use std::io::{self, BufRead};
use std::process::{Command, Stdio};
use std::thread;
use crate::{pr, erm};
use log::{debug, error};

pub fn exec(command: &str) -> io::Result<()> {
    let mut child = Command::new("bash")
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
                Ok(line) => {
                    pr!("{}", line);
                    debug!("{}", line)
                }
                Err(e) => erm!("Error reading stdout: {}", e),
            }
        }
    });

    let stderr_thread = thread::spawn(move || {
        let reader = io::BufReader::new(stderr);
        for line in reader.lines() {
            match line {
                Ok(line) => {
                    pr!("\x1b[31;3;1m{}", line);
                    debug!("[ERR] {}", line)
                }
                Err(e) => erm!("Error reading stderr: {}", e),
            }
        }
    });

    let status = child.wait()?;
    if !status.success() {
        error!("Culprit: `{}`", command);
        return Err(io::Error::new(
            io::ErrorKind::Other,
            format!("Command failed with status: {}", status),
        ));
    }

    stdout_thread.join().unwrap();
    stderr_thread.join().unwrap();

    Ok(())
}
