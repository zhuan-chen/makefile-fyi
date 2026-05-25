# GNU Make's "default goal" is the first target it encounters while parsing. If
# a user runs `make` with no arguments, the default goal is what gets built. By
# defining `all` here, before any `include`, we guarantee `all` is the default
# no matter what targets the included files happen to declare first.
#
# See: https://www.gnu.org/software/make/manual/html_node/Goals.html
#
# `.PHONY` marks `all` as a non-file target. Without it, if a file named `all`
# ever appeared in the directory, Make would compare its timestamp against the
# rule's prerequisites and skip the rule when the file looked up-to-date.
# `.PHONY` tells Make: this name never refers to a file, always run the rule.
#
# See: https://www.gnu.org/software/make/manual/html_node/Phony-Targets.html
.PHONY: all
all:
