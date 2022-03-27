#!/bin/bash

set -e
shopt -s extglob

BASE_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")/..")
cd "$BASE_DIR"

CHROOT_PATH=${CHROOT_PATH:-/opt/archroot}
CHROOT_USER=${CHROOT_USER:-$USER}

c-preparechroot() {
    local root_chroot="$CHROOT_PATH/root"
    local user_chroot="$CHROOT_PATH/$CHROOT_USER"

    if [[ "$user_chroot" == "/" || "$root_chroot" == "/root" ]]; then
        echo "error: chroot path and user not set!!!"
        exit 1
    fi

    if [[ ! -d "$root_chroot" ]]; then
        (set -x
            sudo mkarchroot "$root_chroot"
            touch "$root_chroot.lock" "$user_chroot.lock"
        )
    fi

    (set -x
        sudo rm "$user_chroot" -rf
        sudo sed -i 's/-Werror=format-security//' "$root_chroot/etc/makepkg.conf"
    )
}

c-makepkg() {
    (set -x
        makechrootpkg -r "$CHROOT_PATH" "$@"
    )
}

c-clean-makepkg() {
    c-makepkg -c -u "$@"
}

c-installpkg() {
    (set -x
        sudo pacman -r "$CHROOT_PATH/$CHROOT_USER" --noconfirm -U "$@"
    )
}

c-host-installpkg() {
    (set -x
        sudo pacman --noconfirm -U "$@"
    )
}

c-kbuild() {
    "$BASE_DIR/scripts/build.sh" "$@"
}

c-host-install() {
    local pkgs=()

    for pkg in ${INSTALL_ORDER[@]}; do
        pkgs+=( "$pkg/$pkg"*.pkg.tar.* )
    done

    c-host-installpkg "${pkgs[@]}"
}

CLEAN_PKG=${CLEAN_PKG:riscv32-linux-gnu-linux-api-headers}

BUILD_ORDER=(
    riscv32-linux-gnu-linux-api-headers
    riscv32-linux-gnu-binutils
    riscv32-linux-gnu-gcc-stage1
    riscv32-linux-gnu-glibc
    riscv32-linux-gnu-gcc
    riscv32-linux-gnu-glibc
    riscv32-linux-gnu-gcc
    riscv32-linux-gnu-gdb
)

INSTALL_ORDER=(
    riscv32-linux-gnu-linux-api-headers
    riscv32-linux-gnu-binutils
    riscv32-linux-gnu-gcc
    riscv32-linux-gnu-glibc
)

c-runstep() {
    local pkg="${BUILD_ORDER[$1]}"
    cd "$BASE_DIR/$pkg"

    if [[ "$pkg" == "$CLEAN_PKG" ]]; then
        c-clean-makepkg
    else
        c-makepkg
    fi

    c-installpkg "$pkg"*.pkg.tar.*
}

c-krunstep() {
    local pkg="${BUILD_ORDER[$1]}"
    echo ">> building [$1] $pkg"
    c-kbuild "$1"
}

if [[ $# -eq 1 ]]; then
    case "$1" in
        +([0-9])) true;;
        *) echo "invalid number"; exit 1;;
    esac

    c-runstep "$1"
elif [[ $# -eq 0 ]]; then
    c-preparechroot

    for ((i = 0; i < ${#BUILD_ORDER[@]}; i++)); do
        c-krunstep "$i"
    done

    c-host-install
fi
