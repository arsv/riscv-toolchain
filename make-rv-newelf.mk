# Bare-metal newlib toolchain.
# Almost complete copy of (linux-)newlib for now, including its own
# dedicated newlib-libc build dir, and its own rules for libgloss.
#
# This should not be necessary, only libgloss should be different
# between linux-newlib and elf-newlib, and the only change needed
# should be in the target triplet. But that's still not clear,
# and it's way easier to experiemnt with a full copy.

rv64-elf := riscv64-unknown-elf
rv64-elf-spec := scripts/spec/rv64-gloss

rv64-elf rv64-newelf: \
	staging/rv64-elf-tools \
	staging/rv64-elf-libgcc \
	staging/rv64-elf-libc \
	staging/rv64-elf-libgloss \

rv32-elf := riscv32-unknown-elf
rv32-elf-spec := scripts/spec/rv32-gloss

rv32-elf rv32-newelf: \
	staging/rv32-elf-tools \
	staging/rv32-elf-libgcc \
	staging/rv32-elf-libc \
	staging/rv32-elf-libgloss \

# Just copy them over from -bare for now. Newlib is not enough
# to build libgcc w/o inhibit-libc apparently.

staging/%-elf-libgcc: files-%-bare-libgcc/stamp
	mkdir -p staging/$(rv64-elf)/lib/
	cp -a $(dir $<)/lib/gcc/*/*/lib*.a staging/$(rv64-elf)/lib/
	cp -a $(dir $<)/lib/gcc/*/*/{crtbegin,crtend}.o staging/$(rv64-elf)/lib/
	touch $@

# Libc must be built with bare compiler since $(rv64-new)-gcc
# is not usable without libc startup files.
build-%-elf-libc/Makefile: \
		| riscv-newlib/configure \
		staging/%-elf-tools \
		staging/%-bare-gcc \
		staging/%-bare-libgcc
	mkdir -p $(dir $@) && cd $(dir $@) && \
	../riscv-newlib/newlib/configure \
		--host=$($*-elf) \
		--prefix=/usr \
		--disable-multilib \
		CC="$($*-bare)-gcc"

build-%-elf-libc/stamp: build-%-elf-libc/Makefile
	$(MAKE) -C $(dir $@)
	touch $@

files-%-elf-libc/stamp: build-%-elf-libc/stamp
	$(MAKE) -C $(patsubst files-%,build-%,$(dir $@)) \
		install DESTDIR=$(abspath $(dir $@))
	touch $@

staging/%-elf-libc: files-%-elf-libc/stamp
	mkdir -p staging/$($*-elf)/{include,lib}
	cp -a $(dir $<)usr/*/{include,lib} staging/$($*-elf)/
	touch $@

build-%-elf-libgloss/Makefile: | \
		staging/%-elf-tools \
		staging/%-elf-libc
	mkdir -p $(dir $@) && cd $(dir $@) && \
	../riscv-newlib/libgloss/configure \
		--host=$($*-elf) \
		--prefix=/usr \
		--disable-multilib \
		CC="$($*-elf)-gcc"

build-%-elf-libgloss/stamp: build-%-elf-libgloss/Makefile
	$(MAKE) -C $(dir $@)
	touch $@

files-%-elf-libgloss/stamp: build-%-elf-libgloss/stamp
	$(MAKE) -C $(patsubst files-%,build-%,$(dir $@)) \
		install DESTDIR=$(abspath $(dir $@))
	touch $@

staging/%-elf-libgloss: files-%-elf-libgloss/stamp
	mkdir -p staging/$($*-elf)/{include,lib}
	cp -a $(dir $<)usr/{include,lib} staging/$($*-elf)/
	touch $@
