# Indentation

## Line continuation

A trailing backslash continues a prerequisite list or variable assignment onto
the next line, where Make treats the leading whitespace as insignificant and
collapses it. Indent that continuation with spaces, aligned under the first item
on the line above, so the items read as one per line.

```make
$(dest_dir)/%.txt: $(src_dir)/%.txt \
                 | $(dest_dir)
	cp "$<" "$@"
	@test -s "$@"
```
