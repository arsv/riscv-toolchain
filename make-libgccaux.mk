# Build rules for auxilliary gcc libs (atomic, ssp, gomp, quadmath).
# These need about as much of a toolchain as libstdc++, and should only
# be built after libgcc has been staged properly.

build-%-libgccaux/Makefile: | riscv-gcc/configure \
		staging/%-tools staging/%-libc staging/%-libgcc
	mkdir -p $(dir $@)
	cd $(dir $@) && ../riscv-gcc/configure \
		--target=$($*) \
		--prefix=$(abspath staging) \
		--disable-shared \
		--disable-threads \
		--enable-tls \
		--enable-languages=c \
		--disable-gcc \
		--disable-libgcc \
		--disable-libstdcxx \
		--enable-libatomic \
		--enable-libmudflap \
		--enable-libssp \
		--enable-libquadmath \
		--enable-libgomp \
		--disable-nls \
		--disable-bootstrap \
		--disable-multilib

build-%-libgccaux/stamp: build-%-libgccaux/Makefile
	$(MAKE) -C $(dir $@) all-target
	touch $@

files-%-libgccaux/stamp: build-%-libgccaux/stamp
	$(MAKE) -C $(patsubst files-%,build-%,$(dir $@)) \
		install-target \
		DESTDIR=$(abspath $(dir $@)) prefix=/
	touch $@

staging/%-libgccaux: files-%-libgccaux/stamp
	scripts/stagelib "$($*)" $(dir $<)$($*)/lib
	scripts/stageinc "$($*)" $(dir $<)lib/gcc/$($*)/*/include/
	touch $@
