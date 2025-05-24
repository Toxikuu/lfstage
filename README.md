<h1 align="center">
LFStage
</h1>
<h4 align="center">
LFS stage file generator
</h4>

## Introduction
LFStage builds [LFS](https://www.linuxfromscratch.org/)
[stage files](https://wiki.gentoo.org/wiki/Stage_file).

### Features
- Profiles
- Mass stripping
- Configuration
- Logging

### A high-level overview
The central component of LFStage is the *profile*. A profile contains
instructions to build a stage file. The profile defines sources and build
instructions.

LFStage handles downloading those sources and executing the scripts. LFStage
also handles certain things internally, including cleaning the build environment
before and after a build, stripping binaries, and saving the stage file.

## Installation
To download and install LFStage run the following commands:
```bash
git clone https://github.com/Toxikuu/lfstage.git
cd lfstage
git submodule update

# TODO: Add ./configure
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
LFStage depends on a rust compiler. That's about it.

<!--
 TODO: Cache results of reqs.sh, maybe in /tmp/lfstage/reqs.cache, so it's
not run more than once per boot.

Also consider adding support for per-profile `reqs.sh`'s. If I do this, have a
reqs.env defining the basic functions to reduce boilerplate for profile authors.

Yeah I probably should add per-profile `reqs.sh` support. It's nice to be able
to check you meet requirements before running `build`, and it would allow
profile authors a standard way to define profile requirements.
-->
LFStage will run `./usr/lib/lfstage/scripts/reqs.sh` before building which
performs any final checks.

## Basic usage
Let's say you wanted to build the profile `x86_64-glibc-tox-stage2`:

```bash
# Download the sources
sudo lfstage download x86_64-glibc-tox-stage2

# Build the stage file
# Note this command takes a long time -- ~30 minutes on my system
sudo lfstage build x86_64-glibc-tox-stage2

# View the completed build
tar tf "$(ls -1t /var/cache/lfstage/profiles/x86_64-glibc-tox-stage2/stages/* | head -1)"

# View the build log
# Note that trace logs are not written due to size concerns
less -R /var/log/lfstage/lfstage.log
```

<!--
 TODO: Add `./patches/`. Explain that the patches should be applied with `git
apply patches/<patch>`.

Ideas:
- Compression algorithm patches
- Max written log level patch
-->

## Todos
- [ ] Address all comment todos
- [ ] Add more subcommands
    - [ ] `lfstage reqs <profile>` assuming I add per-profile reqs.sh support
    - [ ] `lfstage import path/to/<profile>.tar.xz`
    - [ ] `lfstage export <profile> <optional-destination>.tar.xz`
- [ ] Write documentation
    - [ ] man
    - [ ] docs
- [ ] `./configure` script, supporting standard variables
- [ ] More configuration options
    - [ ] Jobs
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
        - [ ] Stage file
