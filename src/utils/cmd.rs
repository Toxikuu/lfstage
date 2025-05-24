#![allow(clippy::expect_used)]

use std::{
    io::{
        self,
        BufRead,
    },
    path::Path,
    process::{
        Command,
        Stdio,
        exit,
    },
    thread,
};

use tracing::{
    debug,
    error,
    trace,
};

// TODO: Create a thiserror for script failures prolly

// This could be written to take environment variables as vector argument but I cba
/// WARN: MUST CALL A SCRIPT, NOT A COMMAND
#[allow(clippy::panic)]
pub fn exec<P>(profile: Option<&str>, script: P) -> io::Result<()>
where
    P: AsRef<Path>,
{
    let script = script.as_ref();
    if !script.exists() {
        error!("Script: '{}' does not exist", script.display());

        #[cfg(test)]
        panic!("Nonexistent script");

        #[cfg(not(test))]
        exit(1)
    }

    let command = if let Some(profile) = profile {
        let envs_dir = Path::new("/var/lib/lfstage/profiles")
            .join(profile)
            .join("envs");
        let base_env = envs_dir.join("base.env");

        if !base_env.exists() {
            error!("Base environment '{}' does not exist.", base_env.display());
            error!("Refusing to execute commands without a defined environment.");
            exit(1)
        }

        format!(
            r"
                cp -f /usr/lib/lfstage/envs/internal.env /tmp/lfstage/bashenv
                cat << EOF >> /tmp/lfstage/bashenv
export ENVS={envs_dir}
export LFSTAGE_PROFILE={profile}
export LFSTAGE_VERSION={version}
source {rcfile} || exit 2
EOF
                BASH_ENV=/tmp/lfstage/bashenv bash --noprofile --norc {script}
            ",
            envs_dir = envs_dir.display(),
            rcfile = base_env.display(),
            script = script.display(),
            version = env!("CARGO_PKG_VERSION")
        )
    } else {
        format!(
            "BASH_ENV=/usr/lib/lfstage/envs/internal.env bash --noprofile --norc {}",
            script.display()
        )
    };

    let mut child = Command::new("bash")
        .arg("--noprofile")
        .arg("--norc")
        .arg("-c")
        .arg(&command)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()?;

    let stdout = child.stdout.take().expect("Handle present");
    let stderr = child.stderr.take().expect("Handle present");

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

    stdout_thread.join().expect("Failed to join thread");
    stderr_thread.join().expect("Failed to join thread");

    Ok(())
}

#[macro_export]
macro_rules! exec {
    // Pattern: profile and a script
    ($profile:expr; $script:expr) => {{
        tracing::debug!("Using profile {} to execute script {:?}", $profile, $script);
        $crate::utils::cmd::exec(Some($profile), $script)
    }};

    // Pattern: just a script
    ($script:expr) => {{
        tracing::debug!("Executing {:?} without a profile", $script);
        $crate::utils::cmd::exec(None, $script)
    }};
}

#[cfg(test)]
mod test {
    #[test]
    fn test_no_profile() { assert!(exec!("/usr/lib/lfstage/scripts/testing.sh").is_ok()) }

    #[test]
    #[should_panic(expected = "Nonexistent script")]
    fn test_exec_failure() { assert!(exec!("x86_64-glibc-tox-stage2"; "cat /usr").is_err()) }

    #[test]
    fn test_exec_success_on_reqs() {
        assert!(
            exec!(
                "x86_64-glibc-tox-stage2";
                "/usr/lib/lfstage/scripts/reqs.sh"
            )
            .is_ok()
        );
    }

    #[test]
    fn ensure_shell_options() {
        assert!(
            exec!(
                "x86_64-glibc-tox-stage2";
                "/usr/lib/lfstage/scripts/testing.sh"
            )
            .is_ok()
        );
    }

    // #[test]
    // fn test_exec_failure_on_script() {
    //     assert!(
    //         exec!(
    //             "x86_64-glibc-tox-stage2";
    //             "/var/lib/lfstage/profiles/x86_64-glibc-tox-stage2/scripts/06-chapter6.sh",
    //         )
    //         .is_err()
    //     );
    // }
}
