# This file is named Makefile (capital M) by convention. When you run `make`,
# GNU Make searches for a makefile by trying these names in order: GNUmakefile,
# makefile, then Makefile. Both lowercase makefile and capital Makefile work,
# but Makefile is recommended (and by far the most common): in an ASCII listing,
# uppercase sorts before lowercase, so it appears near the top of a directory
# listing, next to README, LICENSE, and friends. GNUmakefile is reserved for
# makefiles that only work with GNU Make.
#
# See: https://www.gnu.org/software/make/manual/html_node/Makefile-Names.html

# The absolute directory of the makefile currently being read. See the full
# rationale in `make/docs/conventions/path-anchor.md`.
self_dir = $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# This Makefile's own directory, pinned before any `include`.
root_dir := $(self_dir)

include $(root_dir)/make/special-targets.mk
include $(root_dir)/make/special-variables.mk
include $(root_dir)/make/all.mk
