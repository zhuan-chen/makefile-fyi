# Compose the main Make entry point.

make_dir := $(self_dir)

# Global behavior for special Make targets and variables.
#
# They are order-insensitive in GNU Make, but keeping them before modules makes
# the policy visible first.
include $(make_dir)/special-targets.mk
include $(make_dir)/special-variables.mk

# The `all` aggregate goal, plus the modules that add buildable targets to it.
include $(make_dir)/all.mk

# Interactive shell entry point with Make's exported variables.
#
# Make reads all included makefiles before it runs any recipe, so global export
# directives from any module are visible to `enter` regardless of include order.
# Keep enter.mk last for clarity and so earlier modules can shape its
# environment by overriding ENTER_* defaults before enter.mk's ?= assignments.
include $(make_dir)/enter.mk
