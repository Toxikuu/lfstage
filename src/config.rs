use std::{
    fs,
    path::Path,
    sync::LazyLock,
};

use serde::Deserialize;

pub static CONFIG: LazyLock<Config> = LazyLock::new(Config::load);

#[derive(Debug, Deserialize)]
#[serde(default)]
pub struct Config {
    pub custom_tarball: Option<String>,
    pub log_level:      String,
    pub strip:          bool,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            custom_tarball: None,
            log_level:      "trace".to_string(),
            strip:          true,
        }
    }
}

impl Config {
    pub fn load() -> Self {
        let config_path = Path::new("/etc/lfstage/config.toml");

        if !config_path.exists() {
            eprintln!("The config at '{}' does not exist.", config_path.display());
            eprintln!("Falling back to the default config.");
        }

        let config_str = match fs::read_to_string(config_path) {
            | Err(e) => {
                eprintln!("Failed to reard config: {e}");
                eprintln!("Falling back to the default config.");
                return Self::default()
            },
            | Ok(s) => s,
        };

        match toml::de::from_str(&config_str) {
            | Err(e) => {
                eprintln!("Invalid config: {e}");
                eprintln!("Falling back to the default config.");
                Self::default()
            },
            | Ok(c) => c,
        }
    }
}
