# RV64 musl toolchain

rv64-musl := riscv64-unknown-linux-musl
rv64-musl-spec := scripts/spec/rv64-musl

rv64-musl: \
	staging/rv64-musl-tools \
	staging/rv64-musl-libc \
	staging/rv64-musl-libgcc \
	staging/rv64-musl-libstdcxx \
	staging/rv64-musl-libgccaux

rv32-musl := riscv32-unknown-linux-musl
rv32-musl-spec := scripts/spec/rv32-musl

rv32-musl: \
	staging/rv32-musl-tools \
	staging/rv32-musl-libc \
	staging/rv32-musl-libgcc \
	staging/rv32-musl-libstdcxx \
	staging/rv32-musl-libgccaux

# Libc is configured for /usr, so that the installed files 
# could be used to build something bootable. Files needed
# in sysroot are later picked by stage-lib and placed into
# the plain sysroot layout (/include, /lib).

build-%-musl-libc/Makefile: | riscv-musl/configure \
		staging/%-musl-tools \
		staging/%-bare-tools \
		staging/%-bare-libgcc
	mkdir -p $(dir $@) && cd $(dir $@) && \
	../riscv-musl/configure \
		--host=$($*-musl) \
		--prefix=/usr \
		CC="$($*-bare)-gcc" \
		LDFLAGS="-lgcc"

build-%-musl-libc/stamp: build-%-musl-libc/Makefile
	$(MAKE) -C $(dir $@)
	touch $@

files-%-musl-libc/stamp: build-%-musl-libc/stamp
	$(MAKE) -C $(patsubst files-%,build-%,$(dir $@)) \
		install DESTDIR=$(abspath $(dir $@))
	touch $@

staging/%-musl-libc: files-%-musl-libc/stamp
	mkdir -p staging/$($*-musl)/{include,lib}
	cp -a $(dir $<)usr/include/* staging/$($*-musl)/include/
	cp -a $(dir $<)usr/lib/* staging/$($*-musl)/lib/
	$(foreach L,$(wildcard $(dir $<)lib/ld*),\
		ln -sf libc.so staging/$($*-musl)/lib/$(notdir $L);)
	cp -a linux-headers/* staging/$($*-musl)/include/
	touch $@
