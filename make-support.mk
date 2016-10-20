# Fallback in case this has not been done before runnig make
riscv-%/configure:
	git submodule update --init $(dir $@)

staging/%-tools: | staging/exe/ld staging/exe/gcc
	scripts/makegcc $* "$($*)" "$($*-spec)"
	scripts/makebin $* "$($*)"
	touch $@

install:
	scripts/install "$(DESTDIR)" "$(prefix)"

# Shorthand targets for individual parts: make rv64-gnu-libcxx
%: build-%/stamp staging/%
	@true

# clean only target stuff unless told otherwise
clean:
	rm -fr build-rv* files-rv* staging

clean-all: clean
	rm -fr build-* files-* staging

unstage:
	rm -fr staging
