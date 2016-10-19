# Build rules for libgcc

# GCC makefiles pass a lot of weird options to CC, effectively cancelling
# sysroot effects. Counter that with build sysroot and build-time prefix.
# With libc already in place, gcc prefix matches target, so no need
# to pass CC_FOR_TARGET.
build-%-libgcc/Makefile: | riscv-gcc/configure \
		staging/%-tools staging/%-libc
	mkdir -p $(dir $@)
	cd $(dir $@) && ../riscv-gcc/configure \
		--target=$($*) \
		--prefix=$(abspath staging) \
		--disable-shared \
		--disable-threads \
		--enable-tls \
		--enable-languages=c \
		--disable-gcc \
		--enable-libgcc \
		--disable-libstdcxx \
		--disable-libatomic \
		--disable-libmudflap \
		--disable-libssp \
		--disable-libquadmath \
		--disable-libgomp \
		--disable-nls \
		--disable-bootstrap \
		--disable-multilib \
		--with-build-sysroot=$(abspath staging/$($*)) \
		CFLAGS_FOR_TARGET="-fPIC"

# prep the build directory by copying necessary files from build-gcc
build-%-libgcc/gcc/include: | build-gcc/stamp
	mkdir -p $(dir $@)
	cp build-gcc/gcc/*.h $(dir $@)
	cp -a build-gcc/gcc/include $(dir $@)

build-%-libgcc/gcc/libgcc.mvars: build-gcc/gcc/libgcc.mvars
	mkdir -p $(dir $@)
	sed -e '/^INHIBIT/s/=.*/=/' $< > $@

build-%-libgcc/stamp: build-%-libgcc/Makefile | \
		build-%-libgcc/gcc/libgcc.mvars \
		build-%-libgcc/gcc/include \
		staging/%-tools staging/%-libc
	$(MAKE) -C $(dir $@) all-target-libgcc
	touch $@

files-%-libgcc/stamp: build-%-libgcc/stamp
	$(MAKE) -C $(patsubst files-%,build-%,$(dir $@)) \
		install-target-libgcc \
			DESTDIR=$(abspath $(dir $@)) prefix=/
	touch $@

staging/%-libgcc: files-%-libgcc/stamp
	scripts/stagelib "$($*)" $(dir $<)lib/gcc/$($*)/*
	scripts/stageinc "$($*)" $(dir $<)lib/gcc/$($*)/*/include/
	touch $@
