// src/main.rs

#![deny(clippy::perf, clippy::todo, clippy::complexity)]
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

mod cmd;
mod config;
mod globals;

use std::{
    io,
    process::exit,
    str::FromStr,
    sync::OnceLock,
};

use chrono::Local;
use globals::CONFIG;
use tracing::{
    Level,
    error,
    info,
    level_filters::LevelFilter,
};
use tracing_appender::{
    non_blocking::WorkerGuard,
    rolling,
};
use tracing_subscriber::{
    EnvFilter,
    fmt::time,
    prelude::*,
};

const SCRIPTDIR: &str = "/usr/share/lfstage/scripts";
static LOG_GUARD: OnceLock<WorkerGuard> = OnceLock::new();

fn build() -> Result<(), io::Error> {
    info!("Beginning stage file build");
    let ts = timestamp();

    info!("Executing prebuild scripts");
    exec!("{SCRIPTDIR}/00-reqs.sh")?;
    exec!("{SCRIPTDIR}/01-setup.sh")?;
    exec!("{SCRIPTDIR}/02-getsources.sh")?;

    info!("Building chapter 5");
    exec!("{SCRIPTDIR}/05-chapter5.sh")?;
    info!("Building chapter 6");
    exec!("{SCRIPTDIR}/06-chapter6.sh")?;
    info!("Building chapter 7");
    exec!("TS={ts} {SCRIPTDIR}/07-chapter7.sh")?;

    info!("Saved stage file to /var/tmp/lfstage/stages/lfstage@{ts}.tar.xz");
    Ok(())
}

fn main() {
    init();
    // Avoid printing more than necessary on failures
    let _ = build();
}

fn init() {
    check_perms();
    log();
}

fn check_perms() {
    if unsafe { libc::geteuid() } != 0 {
        eprintln!("Run this as root");
        exit(1);
    }
}

fn log() {
    let file_appender = rolling::never("/var/log", "lfstage.log");
    let (file_writer, guard) = tracing_appender::non_blocking(file_appender);

    let level = LevelFilter::from_str(&CONFIG.log_level).unwrap_or(LevelFilter::DEBUG);
    let filter = EnvFilter::builder()
        .with_default_directive(level.into())
        .with_env_var("LOG_LEVEL")
        .from_env_lossy();

    // Trace-level logs are only written to stdout as they take up a lot of space
    tracing_subscriber::fmt()
        .with_env_filter(filter)
        .with_level(true)
        .with_target(true)
        .with_timer(time::uptime())
        .with_writer(file_writer.with_max_level(Level::DEBUG).and(io::stdout))
        .compact()
        .init();

    if LOG_GUARD.set(guard).is_err() {
        error!("[UNREACHABLE] log() was called more than once");
    }
}

fn timestamp() -> String { Local::now().format("%Y-%m-%d_%H-%M-%S").to_string() }
