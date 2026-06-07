# Special built-in target names.
# See: https://www.gnu.org/software/make/manual/html_node/Special-Targets.html

# Delete a target if its recipe fails after starting to write it, so a failed
# build never leaves a half-written target behind.
# See: https://www.gnu.org/software/make/manual/html_node/Errors.html
.DELETE_ON_ERROR:

# .PHONY marks non-file targets. Without it, for example, if a file named `all`
# ever appeared in the directory, Make would compare its timestamp against the
# rule's prerequisites and skip the rule when the file looked up-to-date. .PHONY
# tells Make: this name never refers to a file, always run the rule.
#
# See: https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html
.PHONY: all
