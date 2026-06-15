# Install developer tools into the repo on demand.

here := $(self_dir)

$(root_dir)/.local/bin:
	@mkdir -p $@

# Each tool has a tools/install-<tool>.sh script that downloads, verifies, and
# places one executable at $(root_dir)/.local/bin/<tool>.
#
# The script is the only normal prerequisite. Version and checksum changes live
# in that file, so a script edit reinstalls the tool.
#
# The $(root_dir)/.local/bin directory is an order-only prerequisite: it only
# has to exist, and making it a normal prerequisite would reinstall every tool
# whenever a new install adds a file and bumps the directory's timestamp.
#
# The executable is the target, so deleting it is enough to force a reinstall.
$(root_dir)/.local/bin/%: $(here)/tools/install-%.sh \
                        | $(root_dir)/.local/bin
	TOOLCHAIN_INSTALL_PREFIX='$(root_dir)/.local' $<
	@test -x "$@"
