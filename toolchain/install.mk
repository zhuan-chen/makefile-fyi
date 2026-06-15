# Install tools into the repo on demand.

here := $(self_dir)

# Each tool is defined by tools/<tool>.sh and installed by the install.sh
# driver, which downloads, verifies, and places one executable at
# $(root_dir)/.local/bin/<tool>.
#
# The tool definition is the only prerequisite: a version or checksum change in
# that file reinstalls the tool. install.sh is deliberately not a prerequisite,
# so a shared driver edit does not reinstall every tool.
#
# The executable is the target, so deleting it is enough to force a reinstall.
# Unpacking preserves the archive's mtime (the upstream build date), which
# predates the tool definition, so the recipe touches the placed file. Without
# that, Make would see the target as older than its prerequisite and reinstall
# on every run.
#
# In this pattern rule, $* is the stem matched by %, so it is the tool name. The
# recipe runs `install.sh <tool>`.
$(root_dir)/.local/bin/%: $(here)/tools/%.sh
	TOOLCHAIN_INSTALL_PREFIX='$(root_dir)/.local' $(here)/install.sh $*
	@test -x "$@"
	@touch "$@"
