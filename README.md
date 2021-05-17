# `riscv32-linux-gnu` Toolchain for ArchLinux

This repo provides the necessary PKGBUILDs for compiling a `riscv32-linux-gnu`
toolchain on ArchLinux.

The packages should be preferably compiled in a clean chroot (e.g. using
`mkarchroot` and `makechrootpkg`).

## Preparation

The `-Werror=format-security` option in `/etc/makepkg.conf` needs to be removed,
since GCC fails to compile with it present.

## Build Order

The build order is as follows. Install the new package in the chroot after every
build.

- `riscv32-linux-gnu-linux-api-headers`
- `riscv32-linux-gnu-binutils`
- `riscv32-linux-gnu-gdb`
- `riscv32-linux-gnu-gcc-stage1`
- `riscv32-linux-gnu-glibc`
- `riscv32-linux-gnu-gcc`
- `riscv32-linux-gnu-glibc` (rebuild)
- `riscv32-linux-gnu-gcc` (rebuild)

After a successful build, only the following packages are needed:

- `riscv32-linux-gnu-linux-api-headers`
- `riscv32-linux-gnu-binutils`
- `riscv32-linux-gnu-gdb`
- `riscv32-linux-gnu-glibc`
- `riscv32-linux-gnu-gcc`
