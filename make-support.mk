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
	rm -fr build-rv* files-rv* staging staged.list

clean-all: clean
	rm -fr build-* files-* staging staged.list

unstage:
	rm -fr staging

# Re-run make in a selected directory, ignoring stamps.

update-%:
	test -f build-$*/stamp
	rm build-$*/stamp
	$(MAKE) build-$*/stamp $(if $(wildcard staging/$*),staging/$*)

# Destructive partial targets

rebuild-%: | build-%/stamp
	rm -fr build-$*
	$(MAKE) build-$*/stamp $(if $(wildcard staging/$*),staging/$*)

refile-%:
	test -f build-$*/stamp
	rm -fr files-$*
	$(MAKE) files-$*/stamp

staged.list:
	echo staging/rv* > $@

restage: staged.list
	rm -fr staging/{bin,exe,lib}
	rm -fr staging/riscv*
	rm -f staging/rv*
	$(MAKE) $(shell cat $<)
	rm -f $<

restage-%:
	test -f staging/$*
	rm staging/$*
	$(MAKE) staging/$*
