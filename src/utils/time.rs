// utils/time.rs
//! Utilities related to time

pub fn timestamp() -> String { chrono::Local::now().format("%Y-%m-%d_%H-%M-%S").to_string() }
