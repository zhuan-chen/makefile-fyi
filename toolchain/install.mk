# Install tools into this repository on demand.

toolchain_dir := $(self_dir)

# Each tool is defined by tools/<tool>.sh and installed by the install.sh
# driver, which downloads, verifies, and installs one pinned version, keeping
# earlier versions in place.
#
# The tool definition is the only prerequisite: a version or checksum change in
# that file reruns the installer. install.sh is deliberately not a prerequisite,
# so a shared driver edit does not reinstall every tool.
#
# The target is the active release symlink under lib/, keyed by tool name.
# Deleting the symlink forces a rerun, which relinks the installed release and
# re-exposes its commands; deleting the installed release too forces a full
# reinstall.
#
# In this pattern rule, $* is the stem matched by %, so it is the tool name. The
# recipe runs `install.sh <tool>`, then touches the release directory through
# the symlink. Make follows the symlink to that directory and reads its
# timestamp; reactivating an installed release keeps an old timestamp there, so
# without the touch Make would rerun the recipe every time.
$(root_dir)/.local/lib/%: $(toolchain_dir)/tools/%.sh
	TOOLCHAIN_INSTALL_PREFIX='$(root_dir)/.local' \
		$(toolchain_dir)/install.sh $*
	touch "$@"
