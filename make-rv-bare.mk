# libgcc must be configured for -linux-gnu target to get
# crt*S and crt*T variants. Such config apparently has no effects
# on regular crt, so the end result remains usable both for linux
# and non-linux targets.

rv64-bare := riscv64-bare
rv64-bare-linux := riscv64-unknown-linux-gnu
rv64-bare-spec := scripts/spec/rv64-bare

rv64-bare: \
	staging/rv64-bare-gcc \
	staging/rv64-bare-libgcc

rv32-bare := riscv32-bare
rv32-bare-linux := riscv32-unknown-linux-gnu
rv32-bare-spec := scripts/spec/rv32-bare

rv32-bare: \
	staging/rv64-bare-gcc \
	staging/rv64-bare-libgcc

# Pre-install required scripts. CC is riscv64-bare-gcc because anything
# non-bare is going to have libgcc in spec; however, libgcc configure cannot
# handle AR_FOR_TARGET properly, so target-prefixed binutils must be available
# in $PATH for it to pick.
#
# The lack of rv*-bare-tools target ensures generic libgcc.mvars rule
# does not apply here.

staging/%-bare-gcc:
	scripts/makegcc $* "$($*-bare)" $($*-bare-spec) gcc-only
	touch $@

build-%-bare-libgcc/Makefile: | riscv-gcc/configure \
		staging/%-gnu-tools staging/%-bare-gcc
	mkdir -p $(dir $@)
	cd $(dir $@) && ../riscv-gcc/configure \
		--target=$($*-bare-linux) \
		--prefix=$(abspath staging) \
		--without-headers \
		--disable-shared \
		--disable-threads \
		--enable-tls \
		--enable-languages=c \
		--disable-libatomic \
		--disable-libmudflap \
		--disable-libssp \
		--disable-libquadmath \
		--disable-libgomp \
		--disable-nls \
		--disable-bootstrap \
		--disable-multilib \
		--disable-gcc \
		CC_FOR_TARGET="$($*-bare)-gcc" \
		CFLAGS_FOR_TARGET="-fPIC" \
		LDFLAGS_FOR_TARGET="-nostdlib"

build-%-bare-libgcc/gcc/libgcc.mvars: build-gcc/gcc/libgcc.mvars
	mkdir -p $(dir $@)
	cp $< $@

build-%-bare-libgcc/stamp: build-%-bare-libgcc/Makefile | \
		build-%-bare-libgcc/gcc/libgcc.mvars \
		build-%-bare-libgcc/gcc/include \
		staging/%-bare-gcc
	$(MAKE) -C $(dir $@) all-target-libgcc

staging/%-bare-libgcc: files-%-bare-libgcc/stamp
	mkdir -p staging/$($*-bare)/lib
	cp -a $(dir $<)/lib/gcc/$($*-bare-linux)/*/*.[oa] staging/$($*-bare)/lib/
	touch $@
