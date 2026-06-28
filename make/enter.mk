# Start an entered shell from Make with exported variables visible.
#
# Usage:
#   make enter
#   make enter ENTER_SHELL="$SHELL"
#
# Default parameter values use ?= so a module included before enter.mk, or a
# value on the command line, can override them.

# Default to the caller's SHELL, falling back to /bin/sh if the caller did not
# export it.
ENTER_SHELL ?= $${SHELL:-/bin/sh}

.PHONY: enter

# Start an entered shell that inherits the recipe environment. Exported Make
# variables stay after entry; unexported Make variables stay Make-only. The
# caller's parent shell is unchanged, and exiting the entered shell returns to
# it.
#
# MAKEFILES points Make at this setup's top Makefile, so a `make` started in the
# entered shell reads this setup no matter which directory it runs from.
#
# See: https://www.gnu.org/software/make/manual/make.html#MAKEFILES-Variable
#
# Make exports MAKEFLAGS, MAKELEVEL, and MFLAGS to recipes. Unset them before
# entry so later `make` commands started by the entered shell do not inherit
# this target's recursive-make state, options, or jobserver flags.
#
# Keep this repository's tools first in PATH. PATH is searched left to right, so
# the recipe prepends .local/bin unless it is already the first entry. The check
# only looks at the first entry; an existing later copy can remain because the
# leading copy is what sets precedence.
#
# ${name:+word} expands to word only when name is set and non-empty. Here,
# word is :$PATH, which avoids creating a trailing colon when PATH is unset or
# empty. In PATH, a trailing, leading, or doubled colon creates an empty field,
# meaning the current directory. This target does not sanitize an already
# malformed caller PATH, but it should not introduce a new empty field.
#
# The final exec replaces Make's recipe shell with the entered shell, which
# removes a dormant wrapper shell:
#   make -> recipe sh -> entered shell  (without exec)
#   make -> entered shell               (with exec)
#
# It also keeps the entered shell's exit status as the recipe status. Without
# exec, a later command could run after the user exits the entered shell and
# mask that status. With exec, later commands are unreachable unless exec itself
# fails.
enter:
	@unset MAKEFLAGS MAKELEVEL MFLAGS; \
	case ":$${PATH-}:" in \
		:"$(root_dir)/.local/bin":*) ;; \
		*) PATH="$(root_dir)/.local/bin$${PATH:+:$$PATH}" ;; \
	esac; \
	export PATH; \
	MAKEFILES="$(root_dir)/Makefile" \
	exec "$(ENTER_SHELL)" -i
