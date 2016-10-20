# Quick toolchain viability check: build hello world executable
# and run it via qemu. Requires qemu-riscv64/32 in PATH.
# Typical invocation:
#
#     make hello      # build only
#     make run-hello  # run all

# both are lists of toolchain stems: rv64-gnu rv64-musl ...
staged-tools := $(filter-out rv%-elf,\
                     $(patsubst %-libc,%,\
                          $(notdir $(wildcard staging/rv*-libc)) ))
staged-tools-cxx := $(patsubst %-libstdcxx,%,\
                         $(notdir $(wildcard staging/rv*-libstdcxx)) )

# hello-rv64-gnu hello-cxx-r64-musl ...
hello := $(patsubst %,hello-%,$(staged-tools))
hello-cxx := $(patsubst %,hello-%-cxx,$(staged-tools-cxx))

hello: all-hello all-hello-cxx
	@test -n "$(hello)$(hello-cxx)" || echo "No staged toolchains"

all-hello: $(hello)
all-hello-cxx: $(hello-cxx)

hello-%: hello.c staging/%-tools staging/%-libc
	staging/bin/$($*)-gcc -o $@ $<

hello-%-cxx: hello.cxx staging/%-tools staging/%-libc staging/%-libstdcxx
	staging/bin/$($*)-g++ -o $@ $<

run-hello: $(patsubst %,run-%,$(hello) $(hello-cxx))

run-hello-rv32%: hello-rv32%
	$(qemu32) -L staging/$(rv32$(patsubst %-cxx,%,$*)) $<

run-hello-rv64%: hello-rv64%
	$(qemu64) -L staging/$(rv64$(patsubst %-cxx,%,$*)) $<

clean-hello:
	rm -f hello-*

clean: clean-hello
