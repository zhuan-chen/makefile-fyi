# Start a child shell from Make with exported variables visible.
#
# Usage:
#   make enter
#   make enter ENTER_PROMPT_NAME=custom
#   make enter ENTER_SHELL="$SHELL"
#
# Default parameter values use ?= so a module included before enter.mk, or a
# value on the command line, can override them.

# The prompt name identifies this environment. The recipe prefixes it to the
# inherited PS1. With ENTER_PROMPT_NAME=foo and a current prompt of $, the
# entered shell gets:
#   (foo) $
#
# The default is this repo's directory name. root_dir is an absolute path with
# no trailing slash, so notdir keeps its final path component.
ENTER_PROMPT_NAME ?= $(notdir $(root_dir))

# Default to /bin/sh because interactive shells often reset inherited PS1 from
# their startup files. For example, Bash commonly reads ~/.bashrc for
# interactive sessions, and that file often assigns PS1 again. If that happens,
# it overwrites the prompt label from Make.
ENTER_SHELL ?= /bin/sh

.PHONY: enter

# Start a child shell that inherits the recipe environment. Exported Make
# variables stay after entry; unexported Make variables stay Make-only. The
# caller's parent shell is unchanged, and exiting the child shell returns to it.
#
# Keep repo-local tools first in PATH. PATH is searched left to right, so the
# recipe prepends .local/bin unless it is already the first entry. The check
# only looks at the first entry; an existing later copy can remain because the
# leading copy is what sets precedence.
#
# ${name:+word} expands to word only when name is set and non-empty. Here,
# word is :$PATH, which avoids creating a trailing colon when PATH is unset or
# empty. In PATH, a trailing, leading, or doubled colon creates an empty field,
# meaning the current directory. This target does not sanitize an already
# malformed caller PATH, but it should not introduce a new empty field.
#
# PATH could be assigned in Make, but the child shell is its only consumer, so
# keeping the assignment in the recipe limits its scope.
#
# The final exec replaces Make's recipe shell with the environment shell, which
# removes a dormant wrapper shell:
#   make -> recipe sh -> env shell  (without exec)
#   make -> env shell               (with exec)
#
# It also keeps the environment shell's exit status as the recipe status.
# Without exec, a later command could run after the user exits the child shell
# and mask that status. With exec, later commands are unreachable unless exec
# itself fails.
enter:
	@case ":$${PATH-}:" in \
		:"$(root_dir)/.local/bin":*) ;; \
		*) PATH="$(root_dir)/.local/bin$${PATH:+:$$PATH}" ;; \
	esac; \
	PS1="($(ENTER_PROMPT_NAME)) $${PS1-}"; \
	export PATH PS1; \
	exec "$(ENTER_SHELL)" -i
