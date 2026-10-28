## Why

fullsimp transforms whole expressions only. When a sum or product combines parts that share no variables, a transform suited to one part gets applied to all of them, and the parts interfere. `p^10 + sin(x)^2 + cos(x)^2`, with `p` the expansion of `(a+b+c+d+u)^10`, takes 13.7 s and returns an expanded factorisation of `p^10 + 1` with cost over 20,000. Simplifying the two parts separately gives `(a+b+c+d+u)^10 + 1` in 0.17 s. Smaller cases go wrong in the same way: `(1+cos(t))/sin(t) + (exp(y)-exp(-y))/(exp(y)+exp(-y))` gives `tanh(y) + cos(t/2)/sin(t/2)` rather than `cot(t/2) + tanh(y)`, and the matching product gives `(%e^(2*y)-1)*cot(t/2)/(%e^(2*y)+1)` rather than `cot(t/2)*tanh(y)`.

Function arguments do not need the same treatment. Tests show `f((1+cos(t))/sin(t))`, `exp(tanh-form)` and `sqrt(tan(x)+cot(x))` already simplify inside the argument, because Maxima's transforms and `apply1` recurse into subexpressions.

## What Changes

- Before searching, fullsimp splits a top-level sum or product into groups of terms (or factors) that share no variables, and simplifies each group separately, when there are at least two such groups. Terms with no variables may go with any group, because constants interact with groups: `1 - sin(x)^2` is `cos(x)^2`. A group can take all the constants, or a shift of +1 or -1 when it contains a trigonometric or hyperbolic function, so that `1 - sin(x)^2 + tan(y)^2 + 1` gives `cos(x)^2 + sec(y)^2`.
- Each group gets the full fullsimp treatment, including further splitting of its own top-level sum or product.
- After a split, fullsimp combines the group results and runs one more search restricted to the routines that merge terms across groups (`logcontract`, `rootscontract`), since `log(a)+log(b)` → `log(a*b)` crosses groups. It skips a full whole-expression search, giving up the occasional factorisation across groups, such as `(x+1)^2 - y^2` → `(x+1-y)*(x+1+y)`, in exchange for avoiding blow-ups like the `p^10 + 1` case.
- The combined result still passes the equivalence check against the original input.
- New option variable `fs_split` (default `true`). Setting it to `false` turns splitting off.

This change builds on `add-equivalence-check`, which verifies each group result and the combined result. It works with either search, and is branched from `add-beam-search` because both change `fsimp.mac`.

## Capabilities

### New Capabilities

- `independent-term-splitting`: fullsimp simplifies variable-disjoint parts of a sum or product separately and combines the results.

### Modified Capabilities

None.

## Impact

- `fsimp.mac`: `fsimpall` gains a splitting step before transform selection. Transform selection then runs per group, so a polynomial group no longer gets trig transforms and the reverse.
- Run time drops for mixed expressions with independent parts. Expressions with one group pay for one variable-set scan.
- `docs/fsimp.texi`, `README.txt`: document `fs_split` and the splitting rule.
- New test file for the scenarios in the spec. Existing rtest files must pass unchanged.
