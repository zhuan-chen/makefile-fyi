include $(root_dir)/toolchain/install.mk

# The aggregate goal: modules add their targets as prerequisites of `all`, so a
# bare `make` builds everything.
all:
