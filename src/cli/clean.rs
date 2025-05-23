// cli/clean.rs

use std::{
    fs,
    io,
};

use clap::Args;
use fshelpers::mkdir_p;

#[derive(Args, Debug)]
pub struct Cmd {
    #[arg(short, long)]
    pub dry: bool,
}

impl Cmd {
    pub fn run(&self) -> Result<(), super::CmdError> {
        if self.dry {
            println!("Would remove the contents of /var/lib/lfstage/mount");
            return Ok(())
        }

        clean_lfs()?;
        Ok(())
    }
}

pub fn clean_lfs() -> io::Result<()> {
    fs::remove_dir_all("/var/lib/lfstage/mount")?;
    mkdir_p("/var/lib/lfstage/mount")
}
