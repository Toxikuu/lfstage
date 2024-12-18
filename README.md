# LFStage
A utility for creating stage2 tarballs for LFS

### Usage
LFStage must currently be executed from its source directory (you'll probably want to edit things anyway, so it's just another reason to keep the sources around)

It is executed with `target/release/lfstage` as root

Toggle which chapters of the LFS book you want to follow in the config.toml (important: also specify the disk that is formatted)

Feel free to tweak the scripts in scripts/ and environment files in envs/ (important: note that the lfs user is not made)

Currently no flags are supported, and they probably won't be for some time

### Dependencies
LFStage depends on everything LFS depends on, in addition to (optionally) upx for binary packing
