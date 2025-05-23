// cli/build.rs

use std::path::Path;

use clap::Args;
use tracing::{
    error,
    info,
};

use super::CmdError;
use crate::utils::dl::{
    download_sources,
    read_dls_from_file,
};

#[derive(Args, Debug)]
pub struct Cmd {
    #[arg(default_value = "x86_64-glibc-tox-stage2")]
    pub profile: String,

    /// Whether to forcibly download sources
    #[arg(short, long)]
    pub force: bool,

    /// Whether to perform a dry-run
    #[arg(short, long)]
    pub dry: bool,
}

impl Cmd {
    /// # Runs the download subcommand
    ///
    /// The download subcommand downloads the sources for a stage file profile.
    ///
    /// # Arguments
    /// * `self.profile`    - The profile to target, defaults to "x86_64-glibc-tox-stage2".
    /// * `self.dry`        - If true, perform a dry run, building nothing.
    ///
    /// # Errors
    /// This function returns a `CmdError` if:
    /// - The script directory couldn't be read.
    /// - One of the scripts failed.
    pub async fn run(&self) -> Result<(), CmdError> {
        let sources_dir = Path::new("/var/cache/lfstage/profiles")
            .join(&self.profile)
            .join("sources");

        if self.dry {
            println!(
                "Would ensure the directory '{}' exists",
                sources_dir.display()
            );
        } else {
            fshelpers::mkdir_p(&sources_dir)?;
        }

        let sources_list = Path::new("/var/lib/lfstage/profiles/")
            .join(&self.profile)
            .join("sources");

        // TODO: Consider making this dry-runnable
        if !sources_list.exists() {
            error!("Sources list for profile '{}' does not exist", self.profile);
            return Err(CmdError::MissingComponent(sources_list));
        }

        if self.dry {
            let dls = read_dls_from_file(sources_list)?;
            println!(
                "Would download the following URLs to '{}':",
                sources_dir.display()
            );

            for dl in &dls {
                println!(" - {dl}");
            }

            return Ok(())
        }

        info!("Downloading sources for '{}'", self.profile);
        download_sources(sources_list, sources_dir, self.force).await?;
        Ok(())
    }
}
