pub mod build;
pub mod clean;
pub mod download;

use std::{
    io,
    path::PathBuf,
};

use clap::{
    Parser,
    Subcommand,
};
use thiserror::Error;

use crate::utils::dl::DownloadError;

#[derive(Parser)]
#[command(name = "LFStage", version, author, about)]
pub struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
#[non_exhaustive]
enum Commands {
    Build(build::Cmd),
    Clean(clean::Cmd),
    Download(download::Cmd),
}

#[derive(Debug, Error)]
pub enum CmdError {
    #[error("I/O error: {0}")]
    Io(#[from] io::Error),

    #[error("Invalid argument: {0}")]
    InvalidArgument(String),

    #[error("Missing component: {0}")]
    MissingComponent(PathBuf),

    #[error("Download error: {0}")]
    Download(#[from] DownloadError),

    #[error("Script failed: {0}")]
    Command(String),
}

impl Cli {
    pub async fn run(&self) -> Result<(), CmdError> {
        match &self.command {
            | Commands::Build(cmd) => cmd.run(),
            | Commands::Clean(cmd) => cmd.run(),
            | Commands::Download(cmd) => cmd.run().await,
        }
    }
}
