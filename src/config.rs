use serde::Deserialize;
use std::fs;

#[derive(Debug, Deserialize)]
#[serde(default)]
pub struct Config {
    // pub disk: String,
    // pub build_pre: bool,
    // pub build_ch5and6: bool,
    // pub build_ch7: bool,
    pub custom_tarball: Option<String>,
    pub log_level: String,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            custom_tarball: None,
            log_level: "debug".to_string(),
        }
    }
}

impl Config {
    pub fn load() -> Self {
        let config_path = "/etc/lfstage/config.toml";

        let config_str =
            fs::read_to_string(config_path).expect("Couldn't find /etc/lfstage/config.toml");
        toml::de::from_str(&config_str).expect("Invalid config")
    }
}
