// cli/export.rs

use std::fs::write;

use clap::Args;
use fshelpers::mkdir_p;
use tracing::info;

use crate::{
    config::CONFIG,
    exec,
};

#[derive(Args, Debug)]
pub struct Cmd {
    /// The profile to export
    #[arg(default_value = CONFIG.default_profile.as_str())]
    pub profile: String,

    /// An optional destination for the exported tarball
    pub out: Option<String>,

    /// Whether to perform a dry-run
    #[arg(short, long)]
    pub dry: bool,
}

impl Cmd {
    pub fn run(&self) -> Result<(), super::CmdError> {
        let out = self
            .out
            .clone()
            .unwrap_or_else(|| format!("/var/cache/lfstage/profiles/{}.tar.xz", &self.profile));

        if self.dry {
            println!(
                "Would run /usr/lib/lfstage/scripts/export.sh with profile '{}' and destination '{out}'",
                self.profile
            );
            return Ok(())
        }

        mkdir_p("/tmp/lfstage")?;
        write("/tmp/lfstage/export", &out)?;
        exec!(&self.profile; "/usr/lib/lfstage/scripts/export.sh")?;

        info!("Exported '{}' to '{out}'", self.profile);
        println!("Exported '{}' to '{out}'", self.profile);

        Ok(())
    }
}
