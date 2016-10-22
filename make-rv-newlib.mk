rv64-new := riscv64-unknown-linux-newlib
rv64-new-spec := scripts/spec/rv64-gloss

rv64-newlib: \
	staging/rv64-new-tools \
	staging/rv64-new-libgcc \
	staging/rv64-new-libc \
	staging/rv64-new-libgloss \

rv32-new := riscv32-unknown-linux-newlib
rv32-new-spec := scripts/spec/rv32-gloss

rv32-newlib: \
	staging/rv32-new-tools \
	staging/rv32-new-libgcc \
	staging/rv32-new-libc \
	staging/rv32-new-libgloss \

# Just copy them over from -bare for now. Newlib is not enough
# to build libgcc w/o inhibit-libc apparently.

staging/%-new-libgcc: files-%-bare-libgcc/stamp
	mkdir -p staging/$(rv64-new)/lib/
	cp -a $(dir $<)lib/gcc/*/*/lib*.a staging/$(rv64-new)/lib/
	cp -a $(dir $<)lib/gcc/*/*/{crtbegin,crtend}.o staging/$(rv64-new)/lib/
	touch $@

# Libc must be built with bare compiler since $(rv64-new)-gcc
# is not usable without libc startup files.
build-%-new-libc/Makefile: \
		| riscv-newlib/configure \
		staging/%-new-tools \
		staging/%-bare-gcc \
		staging/%-bare-libgcc
	mkdir -p $(dir $@) && cd $(dir $@) && \
	../riscv-newlib/newlib/configure \
		--host=$($*-new) \
		--prefix=/usr \
		--disable-multilib \
		CC="$($*-bare)-gcc"

build-%-new-libc/stamp: build-%-new-libc/Makefile
	$(MAKE) -C $(dir $@)
	touch $@

files-%-new-libc/stamp: build-%-new-libc/stamp
	$(MAKE) -C $(patsubst files-%,build-%,$(dir $@)) \
		install DESTDIR=$(abspath $(dir $@))
	touch $@

staging/%-new-libc: files-%-new-libc/stamp
	mkdir -p staging/$($*-new)/{include,lib}
	cp -a $(dir $<)usr/*/{include,lib} staging/$($*-new)/
	cp -a linux-headers/* staging/$($*-new)/include/
	touch $@

build-%-new-libgloss/Makefile: | \
		staging/%-new-tools \
		staging/%-new-libc
	mkdir -p $(dir $@) && cd $(dir $@) && \
	../riscv-newlib/libgloss/configure \
		--host=$($*-new) \
		--prefix=/usr \
		--disable-multilib \
		CC="$($*-new)-gcc"

build-%-new-libgloss/stamp: build-%-new-libgloss/Makefile
	$(MAKE) -C $(dir $@)
	touch $@

files-%-new-libgloss/stamp: build-%-new-libgloss/stamp
	$(MAKE) -C $(patsubst files-%,build-%,$(dir $@)) \
		install DESTDIR=$(abspath $(dir $@))
	chmod u+w $(dir $@)usr/include/machine/*.h
	touch $@

staging/%-new-libgloss: files-%-new-libgloss/stamp
	mkdir -p staging/$($*-new)/{include,lib}
	cp -a $(dir $<)usr/{include,lib} staging/$($*-new)/
	touch $@
