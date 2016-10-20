staging/%-tools: | staging/exe/ld staging/exe/gcc
	scripts/makegcc $* "$($*)" "$($*-spec)"
	scripts/makebin $* "$($*)"
	touch $@

install:
	scripts/install "$(DESTDIR)" "$(prefix)"
