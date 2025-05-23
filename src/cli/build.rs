// cli/build.rs

use std::{
    fs,
    io,
    path::{
        Path,
        PathBuf,
    },
    process::exit,
};

use clap::Args;
use fshelpers::mkdir_p;
use is_executable::IsExecutable;
use tracing::{
    debug,
    error,
    info,
    warn,
};

use super::{
    CmdError,
    clean::clean_lfs,
};
use crate::{
    exec,
    utils::{
        dl::{
            parse_dl,
            read_dls_from_file,
        },
        time::timestamp,
    },
};

#[derive(Args, Debug)]
pub struct Cmd {
    #[arg(default_value = "x86_64-glibc-tox-stage2")]
    pub profile: String,

    pub stagefile: Option<String>,

    #[arg(short, long)]
    pub dry: bool,

    #[arg(long)]
    pub skip_reqs: bool,
}

impl Cmd {
    /// # Runs the build subcommand
    ///
    /// The build subcommand builds a stage file and accepts a variety of arguments.
    ///
    /// # Arguments
    /// * `self.profile`    - The profile to build, defaults to "x86_64-glibc-tox".
    /// * `self.stagefile`  - The path to the built stagefile, defaults to
    ///   "/var/cache/lfstage/stages/lfstage-<profile>-<timestamp>.tar.xz".
    /// * `self.dry`        - If true, perform a dry run, building nothing.
    ///
    /// # Errors
    /// This function returns a `CmdError` if:
    /// - The script directory couldn't be read.
    /// - One of the scripts failed.
    pub fn run(&self) -> Result<(), CmdError> {
        let stagefile = match &self.stagefile {
            | Some(path) => path.clone(),
            | None => format!(
                "/var/cache/lfstage/stages/lfstage-{}-{}.tar.xz",
                self.profile,
                timestamp()
            ),
        };

        let scriptdir = Path::new("/var/lib/lfstage/profiles")
            .join(&self.profile)
            .join("scripts");

        if self.dry {
            println!(
                "Would build profile '{}' and save it to '{stagefile}' by executing scripts in '{}'",
                self.profile,
                scriptdir.display(),
            );
            return Ok(())
        }

        if !self.skip_reqs {
            if let Err(e) = exec!(&self.profile, "/usr/lib/lfstage/scripts/reqs.sh") {
                if e.kind() == io::ErrorKind::Other {
                    error!("System does not meet requirements");
                    exit(1)
                }
                error!("Something unexpected went wrong: {e}");
                exit(1)
            }
        }

        let mut scripts = scriptdir
            .read_dir()?
            .filter_map(|entry| match entry {
                | Ok(e) => Some(e),
                | Err(e) => {
                    warn!("Entry could not be accessed: {e}");
                    warn!("Ignoring it");
                    None
                },
            })
            .map(|entry| entry.path())
            .filter(|path| !path.is_dir() && path.is_executable())
            .filter_map(|path| {
                let str = path.file_name()?.to_string_lossy();
                if str.chars().take(2).all(|c| c.is_ascii_digit()) { Some(path) } else { None }
            })
            .collect::<Vec<_>>();

        scripts.sort_by_key(|p| {
            p.file_name()
                .and_then(|s| s.to_str())
                .and_then(|s| s.split_once('-'))
                .and_then(|(prefix, _)| prefix.parse::<u32>().ok())
        });

        clean_lfs()?;
        setup_sources(&self.profile)?;

        for script in scripts {
            let script_str = script.to_string_lossy();
            info!("Running script {script_str}");
            if let Err(e) = exec!(&self.profile, "{script:?}") {
                error!("Failure in {script_str}: {e}");
                exit(1)
            }
        }

        Ok(())
    }
}

fn setup_sources(profile: &str) -> io::Result<()> {
    let sources_dir = PathBuf::from("/var/cache/lfstage/profiles/")
        .join(profile)
        .join("sources");

    let sources_list = PathBuf::from("/var/lib/lfstage/profiles/")
        .join(profile)
        .join("sources");

    let registered_sources = read_dls_from_file(sources_list)
        .map_err(|e| io::Error::other(format!("Failed to read dls from sources list: {e}")))?
        .iter()
        .map(|dl| parse_dl(dl.to_string()).1)
        .collect::<Vec<_>>();

    let sources = sources_dir
        .read_dir()?
        .filter_map(|entry| match entry {
            | Ok(e) => Some(e),
            | Err(e) => {
                warn!("Entry could not be accessed: {e}");
                warn!("Ignoring it");
                None
            },
        })
        .map(|entry| entry.path())
        .filter(|path| {
            registered_sources.contains(
                &path
                    .file_name()
                    .unwrap_or_default()
                    .to_string_lossy()
                    .to_string(),
            )
        })
        .collect::<Vec<PathBuf>>();
    debug!("Found registered sources: {sources:#?}");

    for source in sources {
        let lfs_sources = Path::new("/var/lib/lfstage/mount/sources");
        mkdir_p(lfs_sources)?;

        // unwrap is probably fine here and im lazy
        let dest = lfs_sources.join(source.components().last().unwrap());
        fs::copy(source, dest)?;
    }

    Ok(())
}
