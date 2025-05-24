#!/bin/bash

# 4.2. Creating a Limited Directory Layout
mkdir -pv "$LFS"/{etc,var,tools} "$LFS"/usr/{bin,lib,sbin}

for i in bin lib sbin; do
    ln -sv usr/$i "$LFS/$i"
done

case $(uname -m) in
    x86_64) mkdir -pv "$LFS/lib64" ;;
esac
