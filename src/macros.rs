// src/macros.rs

#[macro_export]
macro_rules! pr {
    ($($arg:tt)*) => {{
        println!("\x1b[30;3m{}\x1b[0m", format!($($arg)*))
    }};
}

#[macro_export]
macro_rules! erm {
    ($($arg:tt)*) => {{
        eprintln!("\x1b[31;3;1m{}\x1b[0m", format!($($arg)*))
    }};
}
