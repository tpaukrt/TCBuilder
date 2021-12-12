# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021 Tomas Paukrt

define cmd
	$(1) > /tmp/cmd.out 2> /tmp/cmd.err || { tail /tmp/cmd.err; false; }
endef

%-all: %-unpack %-patch %-build %-strip %-pack %-clean
	@true

$(DIR_PACKAGES):
	@mkdir -p $(DIR_PACKAGES)

$(DIR_PACKAGES)/$(PKG_BINUTILS): | $(DIR_PACKAGES)
	@echo "Downloading $(PKG_BINUTILS)"
	@wget -nv -P $(DIR_PACKAGES) $(URL_BINUTILS)/$(PKG_BINUTILS)

$(DIR_PACKAGES)/$(PKG_GCC): | $(DIR_PACKAGES)
	@echo "Downloading $(PKG_GCC)"
	@wget -nv -P $(DIR_PACKAGES) $(URL_GCC)/gcc-$(VER_GCC)/$(PKG_GCC)

$(DIR_PACKAGES)/$(PKG_GLIBC): | $(DIR_PACKAGES)
	@echo "Downloading $(PKG_GLIBC)"
	@wget -nv -P $(DIR_PACKAGES) $(URL_GLIBC)/$(PKG_GLIBC)

$(DIR_PACKAGES)/$(PKG_KERNEL): | $(DIR_PACKAGES)
	@echo "Downloading $(PKG_KERNEL)"
	@wget -nv -P $(DIR_PACKAGES) $(URL_KERNEL)/v$(firstword $(subst ., ,$(VER_LINUX))).x/$(PKG_KERNEL)

%-unpack: %-unpack-binutils %-unpack-gcc %-unpack-glibc %-unpack-kernel
	@true

%-unpack-binutils: $(DIR_PACKAGES)/$(PKG_BINUTILS)
	@echo "Unpacking $(PKG_BINUTILS)"
	@mkdir -p $(DIR_BUILD)
	@tar xf $^ -C $(DIR_BUILD)

%-unpack-gcc: $(DIR_PACKAGES)/$(PKG_GCC)
	@echo "Unpacking $(PKG_GCC)"
	@mkdir -p $(DIR_BUILD)
	@tar xf $^ -C $(DIR_BUILD)

%-unpack-glibc: $(DIR_PACKAGES)/$(PKG_GLIBC)
	@echo "Unpacking $(PKG_GLIBC)"
	@mkdir -p $(DIR_BUILD)
	@tar xf $^ -C $(DIR_BUILD)

%-unpack-kernel: $(DIR_PACKAGES)/$(PKG_KERNEL)
	@echo "Unpacking $(PKG_KERNEL)"
	@mkdir -p $(DIR_BUILD)
	@tar xf $^ -C $(DIR_BUILD)

%-patch: %-patch-gcc
	@true

%-patch-gcc:
	@echo "Patching gcc"
	@sed -e "s/-lmpc -lmpfr -lgmp/-Wl,-Bstatic,-lmpc,-lmpfr,-lgmp,-Bdynamic/" \
	     -i $(DIR_BUILD)/gcc-$(VER_GCC)/configure
	@sed -e "s/\(LIBGCC2_DEBUG_CFLAGS =\).*/\1/" \
	     -i $(DIR_BUILD)/gcc-$(VER_GCC)/libgcc/Makefile.in

%-build: %-build-binutils %-build-gcc-bootstrap %-build-kernel-headers %-build-glibc %-build-gcc
	@true

%-build-binutils:
	@echo "Building binutils"
	@mkdir -p $(DIR_BUILD)/binutils
	@cd $(DIR_BUILD)/binutils && \
	$(call cmd,$(DIR_BUILD)/binutils-$(VER_BINUTILS)/configure \
	  --target=$(TARGET_MACH) \
	  --prefix=$(DIR_INSTALL) \
	  --with-sysroot=$(DIR_SYSROOT) \
	  --disable-nls \
	  --disable-shared \
	  --disable-werror \
	  CFLAGS="-O2" \
	  LDFLAGS="-s") && \
	$(call cmd,make -j8) && \
	$(call cmd,make install)

%-build-gcc-bootstrap:
	@echo "Building gcc bootstrap"
	@mkdir -p $(DIR_BUILD)/gcc-bootstrap
	@cd $(DIR_BUILD)/gcc-bootstrap && \
	$(call cmd,$(DIR_BUILD)/gcc-$(VER_GCC)/configure \
	  --target=$(TARGET_MACH) \
	  --prefix=$(DIR_INSTALL) \
	  --without-headers \
	  --enable-bootstrap \
	  --enable-clocale=gnu \
	  --enable-languages=c++ \
	  --enable-__cxa_atexit \
	  --disable-libcilkrts \
	  --disable-libgcj \
	  --disable-libgomp \
	  --disable-libitm \
	  --disable-libmudflap \
	  --disable-libquadmath \
	  --disable-libssp \
	  --disable-libstdc++-v3 \
	  --disable-libvtv \
	  --disable-lto \
	  --disable-multilib \
	  --disable-nls \
	  --disable-shared \
	  --disable-threads \
	  $(TARGET_OPTS) \
	  libc_cv_c_cleanup=yes \
	  libc_cv_ctors_header=yes \
	  libc_cv_forced_unwind=yes \
	  CFLAGS="-O2" \
	  CXXFLAGS="-O2" \
	  LDFLAGS="-s" \
	  CFLAGS_FOR_TARGET="-O2" \
	  CXXFLAGS_FOR_TARGET="-O2") && \
	$(call cmd,make -j8 all-gcc) && \
	$(call cmd,make -j8 all-target-libgcc) && \
	$(call cmd,make install-gcc install-target-libgcc)

%-build-kernel-headers:
	@echo "Building kernel headers"
	@cd $(DIR_BUILD)/linux-$(VER_LINUX) && \
	$(call cmd,make mrproper) && \
	$(call cmd,make ARCH=$(TARGET_ARCH) defconfig) && \
	$(call cmd,make ARCH=$(TARGET_ARCH) headers_check) && \
	$(call cmd,make ARCH=$(TARGET_ARCH) headers_install INSTALL_HDR_PATH=$(DIR_SYSROOT)/usr)

%-build-glibc:
	@echo "Building glibc"
	@mkdir -p $(DIR_BUILD)/glibc
	@export PATH=$(PATH):$(DIR_INSTALL)/bin && \
	cd $(DIR_BUILD)/glibc && \
	$(call cmd,$(DIR_BUILD)/glibc-$(VER_GLIBC)/configure \
	  --host=$(TARGET_MACH) \
	  --prefix=/usr \
	  --libdir=/usr/lib \
	  --with-headers=$(DIR_SYSROOT)/usr/include \
	  --enable-bind-now \
	  --enable-kernel=$(VER_LINUX) \
	  --enable-stack-protector=strong \
	  --disable-profile \
	  --disable-werror \
	  libc_cv_c_cleanup=yes \
	  libc_cv_ctors_header=yes \
	  libc_cv_forced_unwind=yes \
	  libc_cv_slibdir=/lib \
	  CFLAGS="-O2") && \
	$(call cmd,make -k install-headers cross_compiling=yes install_root=$(DIR_SYSROOT)) && \
	$(call cmd,make -j8) && \
	$(call cmd,make install install_root=$(DIR_SYSROOT))

%-build-gcc:
	@echo "Building gcc"
	@mkdir -p $(DIR_BUILD)/gcc
	@export CC=gcc && \
	cd $(DIR_BUILD)/gcc && \
	$(call cmd,$(DIR_BUILD)/gcc-$(VER_GCC)/configure \
	  --target=$(TARGET_MACH) \
	  --prefix=$(DIR_INSTALL) \
	  --with-sysroot=$(DIR_SYSROOT) \
	  --enable-clocale=gnu \
	  --enable-languages=c++ \
	  --enable-shared \
	  --enable-threads=posix \
	  --enable-__cxa_atexit \
	  --disable-libcilkrts \
	  --disable-libgcj \
	  --disable-libgomp \
	  --disable-libitm \
	  --disable-libmudflap \
	  --disable-libquadmath \
	  --disable-libstdcxx-pch \
	  --disable-libvtv \
	  --disable-lto \
	  --disable-multilib \
	  --disable-nls \
	  $(TARGET_OPTS) \
	  libc_cv_c_cleanup=yes \
	  libc_cv_ctors_header=yes \
	  libc_cv_forced_unwind=yes \
	  CFLAGS="-O2" \
	  CXXFLAGS="-O2" \
	  LDFLAGS="-s" \
	  CFLAGS_FOR_TARGET="-O2" \
	  CXXFLAGS_FOR_TARGET="-O2") && \
	$(call cmd,make -j8 all) && \
	$(call cmd,make install)

%-strip:
	@echo "Removing documentation"
	@rm -rf $(DIR_INSTALL)/share/info
	@rm -rf $(DIR_INSTALL)/share/man
	@rm -rf $(DIR_INSTALL)/sysroot/usr/share/info

%-pack: %-pack-deb %-pack-rpm
	@true

%-pack-deb:
	@echo "Creating package $(TOOLCHAIN_NAME)-$(VER_GCC)-$(RELEASE_NUMBER).x86_64.deb"
	@mkdir -p x86_64
	@mkdir -p $(DIR_DEB_ROOT)/DEBIAN
	@mkdir -p $(DIR_DEB_ROOT)/$(DIR_INSTALL)
	@cp -r $(DIR_INSTALL)/* $(DIR_DEB_ROOT)/$(DIR_INSTALL)
	@echo "Package: $(TOOLCHAIN_NAME)" > $(FILE_DEB_CTRL)
	@echo "Version: $(VER_GCC)-$(RELEASE_NUMBER)" >> $(FILE_DEB_CTRL)
	@echo "Architecture: all" >> $(FILE_DEB_CTRL)
	@echo "Maintainer: $(MAINTAINER)" >> $(FILE_DEB_CTRL)
	@echo "Depends: libc6" >> $(FILE_DEB_CTRL)
	@echo "Section: devel" >> $(FILE_DEB_CTRL)
	@echo "Priority: optional" >> $(FILE_DEB_CTRL)
	@echo "Description: GNU toolchain" >> $(FILE_DEB_CTRL)
	@$(call cmd,dpkg-deb -b $(DIR_DEB_ROOT) x86_64/$(TOOLCHAIN_NAME)-$(VER_GCC)-$(RELEASE_NUMBER).x86_64.deb)

%-pack-rpm:
	@echo "Creating package $(TOOLCHAIN_NAME)-$(VER_GCC)-$(RELEASE_NUMBER).x86_64.rpm"
	@mkdir -p $(DIR_RPM_ROOT)/$(DIR_INSTALL)
	@cp -r $(DIR_INSTALL)/* $(DIR_RPM_ROOT)/$(DIR_INSTALL)
	@echo "Name: $(TOOLCHAIN_NAME)" > $(FILE_RPM_SPEC)
	@echo "Version: $(VER_GCC)" >> $(FILE_RPM_SPEC)
	@echo "Release: $(RELEASE_NUMBER)" >> $(FILE_RPM_SPEC)
	@echo "Group: Development/Tools" >> $(FILE_RPM_SPEC)
	@echo "License: GPL" >> $(FILE_RPM_SPEC)
	@echo "Packager: $(MAINTAINER)" >> $(FILE_RPM_SPEC)
	@echo "Summary: GNU toolchain" >> $(FILE_RPM_SPEC)
	@echo "AutoReqProv: no" >> $(FILE_RPM_SPEC)
	@echo "%define _source_filedigest_algorithm md5" >> $(FILE_RPM_SPEC)
	@echo "%define _binary_filedigest_algorithm md5" >> $(FILE_RPM_SPEC)
	@echo "%define _build_id_links none" >> $(FILE_RPM_SPEC)
	@echo "%define _rpmdir ." >> $(FILE_RPM_SPEC)
	@echo "%description" >> $(FILE_RPM_SPEC)
	@echo "%files" >> $(FILE_RPM_SPEC)
	@echo "%defattr(-,root,root)" >> $(FILE_RPM_SPEC)
	@echo "/*" >> $(FILE_RPM_SPEC)
	@$(call cmd,@rpmbuild -bb --buildroot=$(DIR_RPM_ROOT) $(FILE_RPM_SPEC))

%-clean:
	@echo "Removing build directory"
	@rm -rf $(DIR_BUILD)

clean:
	@echo "Removing build artifacts"
	@rm -rf x86_64

distclean:
	@echo "Removing build artifacts and downloaded packages"
	@rm -rf x86_64 packages
