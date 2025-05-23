# x86_64-glibc-tox-stage2

## Abstract
This profile serves as a basic example for what you can do with LFStage, and
it's a profile I personally use for my LFS systems.

## Notes
Much like the name suggests, this is a stage 2 stage file based on glibc
featuring several customizations:
- NLS and RPATH are disabled where possible
- Python's IDLE is removed
- Stray READMEs, batch scripts, and other random junk is removed
- Everything is stripped (TODO: Consider oxidizing this(?))
