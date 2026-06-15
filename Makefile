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
# rationale in make/docs/conventions/path-anchor.md.
self_dir = $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# This Makefile's own directory, pinned before any `include`.
root_dir := $(self_dir)

# Global behavior for special Make targets and variables.
#
# They are order-insensitive in GNU Make, but keeping them before modules makes
# the policy visible first.
include $(root_dir)/make/special-targets.mk
include $(root_dir)/make/special-variables.mk

# The `all` aggregate goal, plus the modules that add buildable targets to it.
include $(root_dir)/make/all.mk

# Interactive shell entry point with Make's exported variables.
#
# Make reads all included makefiles before it runs any recipe, so global export
# directives from any module are visible to `enter` regardless of include order.
# Keep enter.mk last anyway for clarity. This also allows other modules to shape
# enter.mk's environment by overriding ENTER_* defaults before enter.mk's ?=
# assignments.
include $(root_dir)/make/enter.mk
