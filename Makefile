# This file is named Makefile (capital M) by convention. When you run `make`,
# GNU Make searches for a makefile by trying these names in order: GNUmakefile,
# makefile, then Makefile. Both lowercase makefile and capital Makefile work,
# but Makefile is recommended (and by far the most common): in an ASCII listing,
# uppercase sorts before lowercase, so it appears near the top of a directory
# listing, next to README, LICENSE, and friends. GNUmakefile is reserved for
# makefiles that only work with GNU Make.
#
# See: https://www.gnu.org/software/make/manual/html_node/Makefile-Names.html

# Duplicate-read guard. The entered shell (make/enter.mk) exports MAKEFILES
# pointing here, so this file can be read twice: once via MAKEFILES and once
# from normal Makefile discovery or an explicit `make -f <file>`. Without the
# guard, the second pass would warn about overriding every recipe.
#
# Normalize MAKEFILE_LIST entries before counting because the same makefile can
# be read through different path spellings, such as absolute, relative, or
# symlinked names.
root_makefiles := $(foreach makefile,$(MAKEFILE_LIST),$(realpath $(makefile)))
root_makefile := $(lastword $(root_makefiles))
root_makefile_hits := $(filter $(root_makefile),$(root_makefiles))
ifeq ($(words $(root_makefile_hits)),1)

# The absolute directory of the makefile currently being read. See the full
# rationale in make/docs/conventions/path-anchor.md.
self_dir = $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# This Makefile's own directory, pinned before any `include`.
root_dir := $(self_dir)

include $(root_dir)/make/main.mk

endif
