# LFStage
**LFS stage file generator**

## Introduction
LFStage builds LFS [stage files](https://wiki.gentoo.org/wiki/Stage_file).

It uses rust to wrap a series of bash scripts, stored in `scripts/`, which build
the stage file.

The scripts do the following:
- Check system requirements
- Download sources
- Set up and mount a loopback device to `/mnt/lfstage`
- Complete chapters 5, 6, and 7 of [Linux From Scratch](https://linuxfromscratch.org/lfs)
- Clean up
- Save the stage file to `/var/tmp/lfstage/stages/lfstage@<timestamp>.tar.xz`

LFStage makes a few opinionated optimizations:
- Packages are built with more restrictive flags and less support for
  old/uncommon software and hardware. And also without NLS. Sorry.
- All executable binaries are stripped with `strip --strip-unneeded`.
- All test suites, excepting sanity checks, are skipped.
- The stage files are compressed with `xz -9e`[^1].
- "Unnecessary" files are removed[^2].
- Texinfo is skipped[^3].

[^1]: There are plans to make this configurable.

[^2]: The files are snapped out of existence at the end of
    `scripts/libexec/chroot.sh` if you'd like to see what you're missing.

[^3]: Genuinely why is this in Chapter 7 at all? It is not critical and nothing
    before Chapter 8 even depends on it.

## Installation
To install LFStage run the following commands:
```bash
make
sudo make install
```

If you'd like to examine the structure of LFStage, execute the following
commands as well:
```bash
make DESTDIR="$PWD/DESTDIR" install
tree DESTDIR
```

## Dependencies
LFStage depends on a rust compiler, unless you'd rather use a binary provided as
a release asset[^4].

[^4]: An LFStage-generated stage file is also provided as a release asset.

LFStage checks via `scripts/00-reqs.sh` to ensure the system meets the minimum
requirements to build LFS when run.

## Usage
To build a stage file, logging everything to the console, execute the following
command as the root user:
```bash
LOG_LEVEL=trace lfstage
```

This command takes roughly 30 minutes on my system, though your mileage will
vary depending on your hardware.

LFStage writes a log to `/var/log/lfstage.log`, though the log level is limited
to debug because writing trace-level logs results in a massive log file. Issuing
the following `sed` before compiling will write everything to the log file:
```bash
sed '/with_max_level/s/DEBUG/TRACE/' -i src/main.rs
```

## Todos
- [ ] `./configure` script, supporting standard variables
- [ ] Simple argument parsing with [clap](https://github.com/clap-rs/clap)
- [ ] More configuration options
    - [ ] Compression algorithm
   ~Image size (with minimum)~
- [ ] Drop the loopback device entirely as it's unnecessary
- [ ] Support for multiple stages
- [ ] Support custom file trees specified in `/etc/lfstage/custom/`
- [ ] GitHub actions
    - [ ] Formatting
        - [ ] Trimming white space
        - [ ] Rustfmt
    - [ ] Test
        - [ ] Lint
        - [ ] Nextest
        - [ ] Audit
    - [ ] Release
        - [ ] Changelog
        - [ ] Build stage file
        - [ ] LFStage binary tarball
