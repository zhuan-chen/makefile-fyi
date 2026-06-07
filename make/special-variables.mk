# Special variables.
# See: https://www.gnu.org/software/make/manual/html_node/Special-Variables.html

# GNU Make's "default goal" is what `make` builds when run with no target
# arguments. By default that's the first target it encounters while parsing, but
# .DEFAULT_GOAL pins it explicitly to `all`, so target order (and whatever an
# `include` happens to declare first) stops mattering.
#
# See: https://www.gnu.org/software/make/manual/html_node/Goals.html
.DEFAULT_GOAL := all
