use serde::Deserialize;
use std::fs;

#[derive(Debug, Deserialize)]
pub struct Config {
    pub disk: String,
    pub build_pre: bool,
    pub build_ch5: bool,
    pub build_ch6: bool,
    pub build_ch7: bool,
    pub custom_tarball: Option<String>,
}

impl Config {
    pub fn load() -> Self {
        let config_path = "config.toml";

        let config_str = fs::read_to_string(config_path).expect("Couldn't find config.toml");
        toml::de::from_str(&config_str).expect("Invalid config")
    }
}
