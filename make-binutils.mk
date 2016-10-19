binutils: build-binutils/stamp

build-binutils/Makefile: | riscv-binutils-gdb/configure
	mkdir -p $(dir $@) && cd $(dir $@) && \
	../riscv-binutils-gdb/configure \
		--target=riscv64-riscv32-elf \
		--prefix=$(prefix) \
		--disable-werror \
		--disable-nls

build-binutils/stamp: build-binutils/Makefile
	$(MAKE) -C build-binutils
	touch $@

files-binutils/stamp: build-binutils/stamp
	$(MAKE) -C build-binutils install \
		DESTDIR=$(abspath $(dir $@)) \
		prefix=/
	touch $@

staging/exe/ld: files-binutils/stamp
	scripts/stagebin files-binutils/bin riscv64-riscv32-elf
