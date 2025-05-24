// cli/clean.rs

use std::io;

use clap::Args;

use crate::exec;

#[derive(Args, Debug)]
pub struct Cmd {
    #[arg(short, long)]
    pub dry: bool,
}

impl Cmd {
    // TODO: Add options to clean a specific profile. Cleaning should remove unregistered source
    // files, and optionally all source files, in addition to running `clean_lfs()`.
    pub fn run(&self) -> Result<(), super::CmdError> {
        if self.dry {
            println!("Would recursively unmount and remove the contents of /var/lib/lfstage/mount");
            return Ok(())
        }

        clean_lfs()?;
        Ok(())
    }
}

pub fn clean_lfs() -> io::Result<()> { exec!("/usr/lib/lfstage/scripts/clean.sh") }
