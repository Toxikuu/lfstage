// src/main.rs

#![deny(
    clippy::perf,
    clippy::todo,
    clippy::complexity,
)]
#![warn(
    clippy::all,
    clippy::pedantic,
    clippy::nursery,
    clippy::unwrap_used,
    clippy::expect_used,
    clippy::panic,
    unused,
    // missing_docs,
    // clippy::cargo,
)]

mod config;
mod globals;
mod cmd;
mod macros;
mod utils;

use log::{info, error};
use globals::CONFIG;
use log4rs::config::Deserializers;

fn build() -> Result<(), std::io::Error> {

    info!("Beginning stage2 build");

    if CONFIG.disk.is_empty() {
        error!("Specify a disk in the config.toml!");
    }

    if CONFIG.build_pre {
        info!("Executing prebuild scripts");
        // check LFS requirements
        cmd::exec("scripts/reqs.sh")?;

        // preform prebuild steps
        let command = format!("DISK='{}' scripts/prebuild.sh", CONFIG.disk);
        cmd::exec(&command)?;
    }

    // complete chapter 5 and 6
    if CONFIG.build_ch5and6 {
        info!("Executing chapter 5 and 6 steps");
        cmd::exec("scripts/ch5and6.sh")?;
    }

    // complete chapter 7
    if CONFIG.build_ch7 {
        info!("Executing chapter 7 steps");
        let command = format!("CUSTOM_TARBALL='{}' scripts/ch7.sh", CONFIG.custom_tarball.clone().unwrap_or_default());
        cmd::exec(&command)?;
    }

    info!("Built stage2");
    Ok(())
}

fn main() {
    log4rs::init_file("log4rs.yaml", Deserializers::default()).unwrap();
    let _ = build(); // to avoid printing anything on errors
}
