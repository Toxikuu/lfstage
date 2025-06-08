#!/bin/bash
# Script to ensure the host system meets minimum requirements
# NOTE: envs/base.env is sourced before anything from scripts/ is run.

# shellcheck disable=SC1091,SC2086

LC_ALL=C
PATH=/usr/bin
ERRORS=false

bail() {
    printf "\x1b[37;1m [ \x1b[31mFATAL\x1b[37m ]\x1b[0m %-9s\x1b[0m\n" "$1" >&2
    exit 1
}

err() {
    printf "\x1b[37;1m [ \x1b[31mERROR\x1b[37m ]\x1b[0m %-9s\x1b[0m\n" "$1" >&2
    ERRORS=true
}

ok() {
    printf "\x1b[37;1m [ \x1b[32mOK\x1b[37m ]\x1b[0m    %-9s\x1b[0m\n" "$1"
}

header() {
    printf "\x1b[37;1m%s:\x1b[0m\n" "$1"
}

grep --version &>/dev/null || bail "grep does not work"
sed '' /dev/null || bail "sed does not work"
sort   /dev/null || bail "sort does not work"

ver_check() {
    if ! type -p $2 &>/dev/null; then
        err "Cannot find $2 ($1)"
        return 1
    fi

    v=$($2 --version 2>&1 | grep -E -o '[0-9]+\.[0-9\.]+[a-z]*' | head -n1)
    if printf '%s\n' $3 $v | sort --version-sort --check &>/dev/null; then
        ok "$1 $2 >= $3"
        return 0
    else
        err "$1 is TOO OLD ($3 or later required)"
        return 1
    fi
}

ver_kernel() {
    kver=$(uname -r | grep -E -o '^[0-9\.]+')
    if printf '%s\n' $1 $kver | sort --version-sort --check &>/dev/null; then
        ok "kernel $kver >= $1"
        return 0
    else
        err "kernel $kver is TOO OLD ($1 or later required)"
        return 1
    fi
}

# Coreutils first because --version-sort needs Coreutils >= 7.0
header "Software"
ver_check 'Coreutils   ' 'sort    ' 8.1 || bail "Coreutils too old, stop"
ver_check 'Bash        ' 'bash    ' 3.2
ver_check 'Binutils    ' 'ld      ' 2.13.1
ver_check 'Bison       ' 'bison   ' 2.7
ver_check 'Diffutils   ' 'diff    ' 2.8.1
ver_check 'Findutils   ' 'find    ' 4.2.31
ver_check 'Gawk        ' 'gawk    ' 4.0.1
ver_check 'GCC         ' 'gcc     ' 5.2
ver_check 'GCC (C++)   ' 'g++     ' 5.2
ver_check 'Grep        ' 'grep    ' 2.5.1a
ver_check 'Gzip        ' 'gzip    ' 1.3.12
ver_check 'M4          ' 'm4      ' 1.4.10
ver_check 'Make        ' 'make    ' 4.0
ver_check 'Patch       ' 'patch   ' 2.5.4
ver_check 'Perl        ' 'perl    ' 5.8.8
ver_check 'Python      ' 'python3 ' 3.4
ver_check 'Sed         ' 'sed     ' 4.1.5
ver_check 'Tar         ' 'tar     ' 1.22
ver_check 'Texinfo     ' 'texi2any' 5.0
ver_check 'Xz          ' 'xz      ' 5.0.0

header "Kernel"
ver_kernel 6.14 # A lower version can be used, with 5.4 being what LFS uses

if mount | grep -q 'devpts on /dev/pts' && [ -e /dev/ptmx ]; then
    ok "kernel supports UNIX 98 PTY"
else
    err "kernel does NOT support UNIX 98 PTY"
fi

alias_check() {
    if $1 --version 2>&1 | grep -qi $2; then
        ok "$1 is $2"
    else
        ok "$1 is NOT $2"
    fi
}

header "Aliases"
alias_check 'awk  ' GNU
alias_check 'yacc ' Bison
alias_check 'sh   ' Bash

header "Compiler check"
if printf "int main(){}" | g++ -x c++ -; then
    ok "g++ works"
else
    err "g++ does NOT work"
fi
rm -f a.out

if [ "$(nproc)" = "" ]; then
    err "nproc is not available or it produces empty output"
else
    ok "nproc reports $(nproc) logical cores are available"
fi

header "Networking check"
if ping -c1 'google.com' &>/dev/null; then
    ok "connected to the internet"
else
    err "NOT connected to the internet"
fi

echo
header "Verdict"
if $ERRORS; then
    printf "\x1b[31;1mHost system does not meet requirements\x1b[0m\n"
    exit 1
else
    printf "\x1b[32;1mHost system meets all requirements\x1b[0m\n"
    echo "Requirements met" > /tmp/lfstage/reqs
    exit 0
fi
