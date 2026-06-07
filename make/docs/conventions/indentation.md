# Indentation

## Line continuation

A trailing backslash continues a prerequisite list or variable assignment onto
the next line, where Make treats the leading whitespace as insignificant and
collapses it. Indent that continuation with spaces, aligned under the first item
on the line above, so the items read as one per line.

```make
$(root_dir)/.local/bin/%: $(here)/tools/install-%.sh \
                        | $(root_dir)/.local/bin
	TOOLCHAIN_INSTALL_PREFIX='$(root_dir)/.local' $<
	@test -x "$@"
```
