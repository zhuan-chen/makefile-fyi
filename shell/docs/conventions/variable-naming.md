# Variable naming

## Case

Use lowercase names for values owned by a shell script. Use uppercase names only
for values supplied by the caller or environment, or for standard shell names
that are already uppercase.

## Private variables

POSIX `sh` has no `local`, so functions and sourced files share one variable
namespace with their caller. In a sourced helper, give every private variable a
helper-specific underscore prefix, such as `_foo_`.

Use that prefix for function arguments, scratch values, and shared helper state
alike. Plain lowercase names are the shared vocabulary between a script and the
helpers it sources.

The underscore prefix is a convention, not a scope. The variable is still global
inside the current shell process; the prefix buys collision avoidance and an
internal marker, not isolation.
