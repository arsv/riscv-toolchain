PATH := $(abspath staging/bin):$(PATH)

include config.mk

default: $(default)

include make-binutils.mk
include make-gcc.mk

include make-libgcc.mk
include make-libgccaux.mk
include make-libstdcxx.mk

include make-rv-bare.mk
include make-rv-gnu.mk
include make-rv-musl.mk
include make-rv-newlib.mk

include make-support.mk

# Do not remove intermediate targets (stamps etc)
.SECONDARY:

# Disable built-in rules
#MAKEFLAGS += --no-builtin-rules --no-builtin-suffixes
# ^ does not work since $(MAKE) passes them to libgcc which depends
#   on some of those rules apparently
# So instead, let's at least do not try to re-build makefiles;
%.mk:

config.mk:
	@echo Run ./configure to create config.mk >&2
