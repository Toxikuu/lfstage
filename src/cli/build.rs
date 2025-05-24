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
    config::CONFIG,
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

    /// The path to save the stagefile to. Should be absolute.
    pub stagefile: Option<String>,

    /// Don't actually do anything
    #[arg(short, long)]
    pub dry: bool,

    /// Don't strip all binaries
    ///
    /// All libraries and executables get stripped with --strip-unneeded
    #[arg(short, long)]
    pub skip_strip: bool,

    /// Don't check system requirements
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
    /// * `self.skip_reqs`  - Don't check system requirements
    /// * `self.skip_strip` - Don't strip binaries
    ///
    /// # Errors
    /// This function returns a `CmdError` if:
    /// - The script directory couldn't be read.
    /// - One of the scripts failed.
    pub fn run(&self) -> Result<(), CmdError> {
        let profile = &self.profile;
        let timestamp = timestamp();

        // Get the path to which the stage file should be saved. Can be overridden if the stagefile
        // positional argument is set.
        let stagefile = match &self.stagefile {
            | Some(path) => path.clone(),
            | None => format!(
                "/var/cache/lfstage/profiles/{profile}/stages/lfstage-{profile}-{timestamp}.tar.xz",
            ),
        };

        // Write some variables to files in `profile_tmpdir` to be accessed later:
        // * `timestamp`    - The timestamp is written to `timestamp`
        // * `stagefile`    - The name of the stagefile is written to `stagefilename`
        // * `strip`        - If we're stripping, create the file `strip`
        if !self.dry {
            // set up `profile_tmpdir`
            let profile_tmpdir = Path::new("/tmp/lfstage").join(profile);
            mkdir_p(&profile_tmpdir)?;

            // timestamp
            fs::write(profile_tmpdir.join("timestamp"), &timestamp)?;

            // stagefilename
            fs::write(profile_tmpdir.join("stagefilename"), &stagefile)?;

            // strip
            if !self.skip_strip && CONFIG.strip {
                fshelpers::mkf(profile_tmpdir.join("strip"))?;
            }
        }

        // The directory for profile-specific scripts.
        let scriptdir = Path::new("/var/lib/lfstage/profiles")
            .join(&self.profile)
            .join("scripts");

        // Display what would be done.
        if self.dry {
            println!(
                "Would build profile '{profile}' and save it to '{stagefile}' by executing scripts in '{}' and '/usr/lib/lfstage/scripts/'",
                scriptdir.display(),
            );
            return Ok(())
        }

        // Check requirements.
        if !self.skip_reqs {
            if let Err(e) = exec!(&self.profile; "/usr/lib/lfstage/scripts/reqs.sh") {
                if e.kind() == io::ErrorKind::Other {
                    error!("System does not meet requirements");
                    exit(1)
                }
                error!("Something unexpected went wrong: {e}");
                exit(1)
            }
        }

        // Gather all the profile-specific scripts.
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

        // Sort those scripts.
        scripts.sort_by_key(|p| {
            p.file_name()
                .and_then(|s| s.to_str())
                .and_then(|s| s.split_once('-'))
                .and_then(|(prefix, _)| prefix.parse::<u32>().ok())
        });

        // Prepare for the build by cleaning and copying over sources.
        clean_lfs()?;
        setup_sources(&self.profile)?;

        // Execute profile-specific scripts.
        for script in scripts {
            info!("Running script {}", script.display());
            if let Err(e) = exec!(&self.profile; &script) {
                error!("Failure in {}: {e}", script.display());
                exit(1)
            }
        }

        // TODO: Add signing. Write lfstage metadata to /etc/lfstage-release before saving.

        // Save the stage file.
        mkdir_p(format!("/var/cache/lfstage/profiles/{profile}/stages"))?;
        if exec!(&self.profile; "/usr/lib/lfstage/scripts/save.sh").is_err() {
            error!("Failed to save stage file");
            exit(1)
        }

        info!("Saved stage file to {stagefile}");
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

        #[allow(clippy::unwrap_used)] // unwrap is probably fine here and im lazy
        let dest = lfs_sources.join(source.components().next_back().unwrap());
        fs::copy(source, dest)?;
    }

    Ok(())
}
