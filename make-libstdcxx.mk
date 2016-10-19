# Build rules for libstdc++

# libstdc++ needs stdtod_l definitions only available with -D_GNU_SOURCE
build-%-libstdcxx/Makefile: | riscv-gcc/configure \
		staging/%-tools staging/%-libc staging/%-libgcc
	mkdir -p $(dir $@)
	cd $(dir $@) && ../riscv-gcc/libstdc++-v3/configure \
		--host=$($*) \
		--prefix=/usr \
		--disable-multilib \
		--enable-shared \
		--disable-rpath \
		--disable-libstdcxx-pch \
		--enable-cxx-flags="-D_GNU_SOURCE"

build-%-libstdcxx/stamp: build-%-libstdcxx/Makefile \
		| staging/%-tools staging/%-libc staging/%-libgcc
	$(MAKE) -C $(dir $@)
	touch $@

files-%-libstdcxx/stamp: build-%-libstdcxx/stamp
	$(MAKE) -C $(patsubst files-%,build-%,$(dir $@)) install \
		DESTDIR=$(abspath $(dir $@))
	touch $@

# Install the lib, flattening versioned and arched
# directory structure in include/c++
staging/%-libstdcxx: files-%-libstdcxx/stamp
	scripts/stagelib "$($*)" $(dir $<)usr/lib
	scripts/stagecxx "$($*)" $(dir $<)usr/include
	touch $@
