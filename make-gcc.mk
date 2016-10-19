gcc: build-gcc/stamp

# Force binutils to be installed. With no as available to check,
# configure assumes hidden symbols are not supported, crippling
# the compiler.
build-gcc/Makefile: | riscv-gcc/configure staging/exe/ld

# GCC must be configured with target *not* matching any of the sysroot
# names. In particular, riscv64-unknown-elf is a very bad choice here,
# as gcc will look for e.g. crtbegin.o in $prefix/$target no matter what.
# We abuse the -vendor- field to show that the directories in gcc
# built-in lists are going to be common for rv64 and rv32 targets.
#
# Sadly gcc does not accept neutral "riscv" cpu designation.

build-gcc/Makefile:
	mkdir -p build-gcc && cd build-gcc && \
	../riscv-gcc/configure \
		--target=riscv64-riscv32-elf \
		--prefix=$(prefix) \
		--libexecdir=$(prefix)/lib \
		--disable-version-specific-runtime-libs \
		--disable-nls \
		--disable-shared \
		--disable-threads \
		--enable-tls \
		--enable-languages=c,c++ \
		--without-headers \
		--disable-bootstrap \
		--disable-libgcc \
		--disable-libstdcxx \
		--disable-libatomic \
		--disable-libmudflap \
		--disable-libssp \
		--disable-libquadmath \
		--disable-libgomp \
		--with-build-time-tools=$(abspath staging/exe)

build-gcc/stamp: build-gcc/Makefile
	$(MAKE) -C $(dir $@) all-host
	touch $@

files-gcc/stamp: build-gcc/stamp
	$(MAKE) -C build-gcc install-host \
		DESTDIR=$(abspath $(dir $@)) \
		prefix=/ \
		libexecdir=/lib
	rm -f files-gcc/bin/*gcc-[0-9]*
	touch $@

# libgcc.mvars is a by-product of gcc build process required to build libgcc.
# Beware of timestamps: build-gcc/stamp is usually older than libgcc.mvars,
# and touching libgcc.mvars here may prompt unnecessary rebuilds within gcc.

build-gcc/gcc/libgcc.mvars: | build-gcc/stamp
	@test -f $@ || echo Failed to build $@ >&2
	@test -f $@

staging/exe/gcc: files-gcc/stamp
	scripts/stagebin files-gcc/bin riscv64-riscv32-elf
	cp -a files-gcc/lib staging/
