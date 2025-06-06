<h1 align="center">
LFStage
</h1>
<h2 align="center">
LFS stage file generator
</h2>

## Status - 50%
LFStage currently supports most of the core functionality I want. I need to do
some refactoring to account for expansions in scope, then I need to write
documentation. Currently things mostly work, but it's not pretty.

## Introduction
LFStage builds [stage files](https://wiki.gentoo.org/wiki/Stage_file) for
[Linux From Scratch](https://www.linuxfromscratch.org/). However, it's probably
agnostic enough to build stage files for other systems.

### Features
- Profiles
- Mass stripping
- Configuration
- Logging

### A high-level overview
The central component of LFStage is the *profile*. A profile defines sources and
build instructions.

LFStage handles downloading those sources and executing the scripts. LFStage
also handles certain boilerplate tasks internally, including cleaning the build
environment before and after a build, setting up a minimal environment,
stripping binaries, and saving the stage file.

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

While you don't need to keep the source directory around, it's probably not a
bad idea to since there's a lot of work still to be done.

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

<!--
 TODO: Once I add profile importing and exporting, create a separate git repo
for the profiles currently defined in-tree.

Add a section that links to other LFStage profiles here and link to those ^.
-->

## Todos
- [ ] Address all comment todos
- [ ] Make `lfstage build` run the download logic if any sources are missing
- [ ] Add more subcommands
    - [x] `lfstage view` should list the available profiles
        - [x] `lfstave view <profile>` should list details about a profile
            - [ ] Add a system for profile metadata containing information like
              a description, author, notes, etc.
    - [ ] `lfstage reqs <profile>` assuming I add per-profile reqs.sh support
    - [x] `lfstage import path/to/<profile>.tar.xz`
        - [ ] Support `lfstage import <https://git.repo.git>`
    - [x] `lfstage export <profile> <optional-destination>.tar.xz`
- [ ] Move the profiles included into their own repositories
    - [ ] Decide on a format for repos (\<profile\>-lfstage?)
- [ ] Add a profile struct (low priority)
- [ ] Write documentation
    - [ ] man
    - [ ] docs
    - [ ] code
- [ ] `./configure` script, supporting standard variables
- [x] More configuration options
    - [x] ~~Jobs~~ Makeflags
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
