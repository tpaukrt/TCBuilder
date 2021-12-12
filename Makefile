# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021 Tomas Paukrt

.NOTPARALLEL:

# list of main targets
all: armv7 armv7hf aarch64

# settings for target architecture ARMv7-A (32-bit, soft-float)
armv7:     armv7-all
armv7-%:   TARGET_ARCH = arm
armv7-%:   TARGET_MACH = arm-none-linux-gnueabi
armv7-%:   TARGET_NAME = armv7-none-linux-gnueabi
armv7-%:   TARGET_OPTS = --with-arch=armv7-a --with-fpu=vfpv3-d16 --with-float=softfp

# settings for target architecture ARMv7-A (32-bit, hard-float)
armv7hf:   armv7hf-all
armv7hf-%: TARGET_ARCH = arm
armv7hf-%: TARGET_MACH = arm-none-linux-gnueabihf
armv7hf-%: TARGET_NAME = armv7-none-linux-gnueabihf
armv7hf-%: TARGET_OPTS = --with-arch=armv7-a --with-fpu=vfpv3-d16 --with-float=hard

# settings for target architecture ARMv8-A (64-bit)
aarch64:   aarch64-all
aarch64-%: TARGET_ARCH = arm64
aarch64-%: TARGET_MACH = aarch64-none-linux-gnu
aarch64-%: TARGET_NAME = aarch64-none-linux-gnu
aarch64-%: TARGET_OPTS = --with-arch=armv8-a

# versions of source packages
VER_BINUTILS           = 2.37
VER_GCC                = 8.5.0
VER_GLIBC              = 2.34
VER_LINUX              = 5.4.1

# names of source packages
PKG_BINUTILS           = binutils-$(VER_BINUTILS).tar.xz
PKG_GCC                = gcc-$(VER_GCC).tar.xz
PKG_GLIBC              = glibc-$(VER_GLIBC).tar.xz
PKG_KERNEL             = linux-$(VER_LINUX).tar.xz

# locations of source packages
URL_BINUTILS           = https://ftp.gnu.org/gnu/binutils
URL_GCC                = https://ftp.gnu.org/gnu/gcc
URL_GLIBC              = https://ftp.gnu.org/gnu/glibc
URL_KERNEL             = https://www.kernel.org/pub/linux/kernel

# maintainer of DEB/RPM packages
MAINTAINER             = Tomas Paukrt <tomaspaukrt@email.cz>

# release number of DEB/RPM packages
RELEASE_NUMBER         = 1

# name of target toolchain
TOOLCHAIN_NAME         = gcc-$(TARGET_NAME)

# directories
DIR_BUILD              = /opt/toolchains/build-$(TOOLCHAIN_NAME)
DIR_INSTALL            = /opt/toolchains/$(TOOLCHAIN_NAME)
DIR_SYSROOT            = $(DIR_INSTALL)/sysroot
DIR_DEB_ROOT           = $(DIR_BUILD)/$(TOOLCHAIN_NAME)
DIR_RPM_ROOT           = $(DIR_BUILD)/buildroot
DIR_PACKAGES           = packages

# auxiliary files
FILE_DEB_CTRL          = $(DIR_BUILD)/$(TOOLCHAIN_NAME)/DEBIAN/control
FILE_RPM_SPEC          = $(DIR_BUILD)/$(TOOLCHAIN_NAME).spec

# build rules
include Rules.mk
