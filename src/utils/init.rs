// utils/init.rs
//! Initialization utilities

use std::{
    io,
    process::exit,
    str::FromStr,
    sync::OnceLock,
};

use tracing::{
    Level,
    error,
    metadata::LevelFilter,
};
use tracing_appender::{
    non_blocking::WorkerGuard,
    rolling,
};
use tracing_subscriber::{
    EnvFilter,
    fmt::{
        time,
        writer::MakeWriterExt,
    },
};

use crate::config::CONFIG;

static LOG_GUARD: OnceLock<WorkerGuard> = OnceLock::new();

pub fn init() {
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
    let file_appender = rolling::never("/var/log/lfstage", "lfstage.log");
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
