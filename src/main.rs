// src/main.rs

mod config;
mod globals;
mod cmd;
mod macros;
mod utils;

use log::{info, error};
use globals::CONFIG;

fn build() -> Result<(), std::io::Error> {

    info!("Beginning stage2 build");

    if CONFIG.disk.is_empty() {
        error!("Specify a disk in the config.toml!")
    }

    if CONFIG.build_pre {
        info!("Executing prebuild scripts");
        // check LFS requirements
        cmd::exec("scripts/reqs.sh")?;

        // preform prebuild steps
        let command = format!("DISK='{}' scripts/prebuild.sh", CONFIG.disk);
        cmd::exec(&command)?;
    }

    // complete chapter 5
    if CONFIG.build_ch5 {
        info!("Executing chapter 5 steps");
        cmd::exec("scripts/ch5.sh")?;
    }

    // complete chapter 6
    if CONFIG.build_ch6 {
        info!("Executing chapter 6 steps");
        cmd::exec("scripts/ch6.sh")?;
    }

    // complete chapter 7
    if CONFIG.build_ch7 {
        info!("Executing chapter 7 steps");
        let command = format!("CUSTOM_TARBALL='{}' scripts/ch7.sh", CONFIG.custom_tarball.clone().unwrap_or("".to_string()));
        cmd::exec(&command)?;
    }

    info!("Built stage2");
    Ok(())
}

fn main() {
    log4rs::init_file("log4rs.yaml", Default::default()).unwrap();

    let _ = build(); // to avoid printing anything on errors
}
