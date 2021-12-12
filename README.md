# GNU Toolchain Builder

## Introduction

  The TCBuilder is a very simple generator of cross-toolchains for
  embedded development on the most popular ARM platforms, but it can
  be easily extended to support new platforms or modified to use
  different versions of open source components.

## Supported target architectures

  * ARMv7-A (32-bit)
  * ARMv8-A (64-bit)

## Prerequisites

  * Internet access or source packages in the `packages` directory
  * 64-bit Linux distribution (tested on Ubuntu 16, 18 and 20)
  * GNU Make 4.0+
  * GCC 6.2+
  * Python 3.4+
  * GMP library 4.2+
  * MPC library 0.8.0+
  * MPFR library 2.4.0+
  * bison 2.7+
  * flex 2.5.35+
  * gawk 3.1.2+
  * makeinfo 4.7+
  * dpkg-deb
  * rpmbuild
  * wget

## Build instructions

  Execute the following command as root:

  ```
  make [armv7|armv7hf|aarch64]
  ```

  The chosen toolchain(s) will be installed in the `/opt/toolchains` directory.

## Directory structure

  ```
  TCBuilder
   |
   |--packages                  Input directory with source packages
   |   |
   |   |--binutils-*.tar.xz     The GNU Binutils
   |   |--gcc-*.tar.xz          The GNU Compiler Collection
   |   |--glibc-*.tar.xz        The GNU C Library
   |   +--linux-*.tar.xz        The Linux Kernel
   |
   |--x86_64                    Output directory with DEB/RPM packages
   |   |
   |   |--gcc-*.deb             Created DEB packages
   |   +--gcc-*.rpm             Created RPM packages
   |
   |--COPYING                   GNU General Public License version 2
   |--Makefile                  Main Makefile
   |--NEWS.md                   Version history
   |--README.md                 This file
   +--Rules.mk                  Build rules
  ```

## License

  The code is available under the GNU General Public License version 2
  or later. See the `COPYING` file for the full license text.
