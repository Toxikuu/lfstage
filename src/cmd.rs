use std::{
    io::{
        self,
        BufRead,
    },
    process::{
        Command,
        Stdio,
    },
    thread,
};

use tracing::{
    debug,
    error,
    trace,
};

pub fn exec(command: &str) -> io::Result<()> {
    let command = format!("source /usr/share/lfstage/envs/base.env && {command}");
    let mut child = Command::new("bash")
        .arg("-e")
        .arg("-c")
        .arg(command)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()?;

    let stdout = child.stdout.take().unwrap();
    let stderr = child.stderr.take().unwrap();

    let stdout_thread = thread::spawn(move || {
        let reader = io::BufReader::new(stdout);
        for line in reader.lines() {
            match line {
                | Ok(line) => {
                    trace!(" [STDOUT] {line}");
                },
                | Err(e) => error!("Error reading stdout: {e}"),
            }
        }
    });

    let stderr_thread = thread::spawn(move || {
        let reader = io::BufReader::new(stderr);
        for line in reader.lines() {
            match line {
                | Ok(line) => {
                    debug!(" [STDERR] {line}");
                },
                | Err(e) => error!("Error reading stderr: {e}"),
            }
        }
    });

    let status = child.wait()?;
    if !status.success() {
        error!("Command failed with status {status}");
        return Err(io::Error::other(format!(
            "Command failed with status: {status}"
        )));
    }

    stdout_thread.join().unwrap();
    stderr_thread.join().unwrap();

    Ok(())
}

#[macro_export]
macro_rules! exec {
    ($($cmd:tt)*) => {{
        $crate::cmd::exec(&format!($($cmd)*))
    }};
}
