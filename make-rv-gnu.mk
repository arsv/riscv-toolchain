rv64-gnu := riscv64-unknown-linux-gnu
rv64-gnu-spec := scripts/spec/rv64-glibc

rv64-gnu: \
	staging/rv64-gnu-tools \
	staging/rv64-gnu-libc \
	staging/rv64-gnu-libgcc \
	staging/rv64-gnu-libgccaux

rv32-gnu := riscv32-unknown-linux-gnu
rv32-gnu-spec := scripts/spec/rv32-glibc

rv32-gnu: \
	staging/rv32-gnu-tools \
	staging/rv32-gnu-libc \
	staging/rv32-gnu-libgcc \
	staging/rv32-gnu-libgccaux

# Libc is configured for /usr, so that the installed files
# could be used to build something bootable. Files needed
# in sysroot are later picked by stage-lib and placed into
# the plain sysroot layout (/include, /lib).

# libc_cv_* from original riscv scripts, no idea why.
# libc_cv_slibdir disables /lib32 for 32-bit libs.
build-%-gnu-libc/Makefile: | riscv-glibc/configure \
		staging/%-gnu-tools \
		staging/%-bare-tools \
		staging/%-bare-libgcc
	mkdir -p $(dir $@) && cd $(dir $@) && \
	../riscv-glibc/configure \
		--host=$($*-gnu) \
		--prefix=/usr \
		--disable-werror \
		--enable-shared \
		--enable-__thread \
		libc_cv_forced_unwind=yes \
		libc_cv_c_cleanup=yes \
		libc_cv_slibdir=/lib \
		--with-headers=$(PWD)/linux-headers \
		CC="$($*-bare)-gcc"

build-%-gnu-libc/stamp: build-%-gnu-libc/Makefile
	$(MAKE) -C $(dir $@)
	touch $@

files-%-gnu-libc/stamp: build-%-gnu-libc/stamp
	$(MAKE) -C $(patsubst files-%,build-%,$(dir $@)) \
		install DESTDIR=$(abspath $(dir $@))
	touch $@

staging/%-gnu-libc: files-%-gnu-libc/stamp
	scripts/stagelib "$($*-gnu)" $(dir $<)lib
	scripts/stagelib "$($*-gnu)" $(dir $<)usr/lib
	scripts/stageinc "$($*-gnu)" $(dir $<)usr/include
	cp -a linux-headers/* staging/$($*-gnu)/include/
	touch $@
