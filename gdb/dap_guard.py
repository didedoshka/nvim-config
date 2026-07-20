"""Stop one hostile value from killing a whole DAP variables request.

gdb's DAP server expands a pretty-printer eagerly and without a bound:
`varref.VariableReference.cache_children` is `list(self._printer.children())`
for any printer that isn't a `gdb.ValuePrinter` with `num_children()` -- which
is every printer arc's gdb ships (they predate that API). Fine for a
constructed object, not fine for one that isn't yet: stopping on the first
line of a scope leaves that scope's `std::vector` locals holding stack
garbage in `__begin_`/`__end_`, so the libc++ printer walks a bogus
multi-billion element range -- measured at 23+ GB RSS and climbing on
unittester-ytlib at arrow_writer.cpp:2481, response never sent.

A printer that raises on garbage instead (seen from the same setup: "Attempt
to extract a component of a value that is not a struct/class/union") is the
same wound in fast-forward: the exception escapes the request, so the client
loses the *entire* scope rather than the one variable that could not be read.

Both are DAP-only. gdb's CLI caps its own printing with `print elements` and
prints `<error: ...>` per value, which is why `info locals` on that same frame
is fine and the panel is not.

So: bound the walk, and degrade per-variable instead of per-request. Checked
against this box's actual gdb.dap.varref (attribute names vary by gdb build;
this one prefixes internals with `_`), not the version docs floating around.
"""

from gdb.dap.varref import BaseReference, VariableReference

# Deliberately not `print elements`: that knob is about how much of a value to
# print, and a 200-element ceiling on the panel would be a surprise. This is
# only a backstop against nonsense, so it sits well above any value worth
# scrolling in a tree.
MAX_CHILDREN = 1000

_orig_child_count = VariableReference.child_count
_orig_to_object = VariableReference.to_object


def cache_children(self):
    if self._child_cache is None:
        children = []
        try:
            for item in self._printer.children():
                if len(children) >= MAX_CHILDREN:
                    break
                children.append(item)
        except Exception as e:
            # Whatever the generator produced before it gave up is still
            # worth keeping, so append the error rather than discarding it.
            children.append(("<error>", "<error: %s>" % e))
        self._child_cache = children
    return self._child_cache


def child_count(self):
    count = _orig_child_count(self)
    if count is not None and count > MAX_CHILDREN:
        # A gdb.ValuePrinter can report num_children() without ever running
        # children(), bypassing the cap above -- fetch_children would then
        # still allocate a list that big and walk it.
        count = MAX_CHILDREN
        self.count = count
    return count


def to_object(self):
    try:
        return _orig_to_object(self)
    except Exception as e:
        # to_string() (or the memory/type introspection after it) blew up.
        # Answer with a readable placeholder so sibling variables in this
        # scope still reach the client.
        result = BaseReference.to_object(self)
        result[self._result_name] = "<error: %s>" % e
        return result


VariableReference.cache_children = cache_children
VariableReference.child_count = child_count
VariableReference.to_object = to_object
