## Context

`fsimpall` maps over lists, sets and matrices, then scans the whole expression for function types (trig, exp, log, gamma, factorial) to build the transform list, and calls `fsimp` on the whole expression. A single trig term in a large polynomial therefore puts the trig transforms in the list for the polynomial too, and every transform sees every term. In the `p^10 + sin(x)^2 + cos(x)^2` case, `trigsimp` turns the trig part into 1, after which `factor` works on the 5-variable degree-10 polynomial `p^10 + 1` on every sweep.

This change assumes `add-equivalence-check` has landed. It works with both the sweep and the beam search.

## Goals / Non-Goals

**Goals:**

- Simplify variable-disjoint parts of a top-level sum or product independently, with per-group transform selection.
- Avoid whole-expression transforms on the combined result.

**Non-Goals:**

- Recursing into function arguments. The proposal records why this is unnecessary today.
- Splitting terms that share variables, for example by function type within one variable. That would risk missing identities like `sin(x)^2 + cos(x)^2` that need several terms together.
- Splitting operators other than `"+"` and `"*"`. Quotients appear as products with negative powers, so they are covered.

## Decisions

### Grouping rule

For each term (or factor), compute `listofvars`. Union-find over the terms joins any two terms that share a variable. Terms with an empty variable list go into a separate constant group. This produces the coarsest partition in which no two groups share a variable, so terms that need each other stay together, as the spec's "Terms sharing a variable stay together" scenario requires.

`listofvars` treats subscripted variables like `c[1]` as variables, and leaves `%pi`, `%e` and `%i` out, so constants like `2*%pi` land in the constant group as intended.

*Alternative:* group by function type as well as variables. Rejected for the reason given in Non-Goals.

### Where splitting happens

Add the split at the start of the non-list branch of `fsimpall`, before transform selection. If the top-level operator is `"+"` or `"*"` and the partition has two or more groups, call `fsimpall` on each group (which may split again), then combine the results with the same operator. Otherwise continue as today. Because selection runs per group, a polynomial group gets only the polynomial transforms.

### No whole-expression pass after a split

The combined result gets returned without a further search. Groups with disjoint variables cannot cancel beyond their constants: if `f(X) + g(Y)` vanishes identically with X and Y disjoint, then f and g are both constant, and the constant group handles that. The same argument holds for products. A final pass could only refactor across groups, and in the motivating case that refactoring is the 13.7 s `factor` call. The proposal records the trade-off.

*Alternative:* run a final pass only when the combined result is small. Rejected for now because it adds a threshold to tune for little gain. Revisit if rtest review turns up cases that lose a cross-group factorisation.

### Verification

Each group's result gets checked against that group's original by the existing equivalence check inside its own fullsimp call. The combined result gets checked once more against the whole original input, which guards against errors in the split and combine step itself. If that final check fails, fullsimp falls back to the unsplit path for that call.

### Option

`fs_split` (default `true`) controls the split. When `false`, `fsimpall` takes exactly the current path.

## Risks / Trade-offs

- [Lost factorisation across groups, for example `(x+1)^2 - y^2`] → Accepted trade-off. Run all rtest files with `fs_split : true` and review any case whose result changes.
- [Behaviour change in existing tests with disjoint factors, such as `(cos(th)+1)/((%i*sin(ph)-cos(ph))*sin(th))`] → The groups should still reach the recorded result. The tasks verify this, and any difference gets reviewed rather than accepted silently.
- [Extra cost of `listofvars` on every call] → One pass over the expression, small next to any transform.
