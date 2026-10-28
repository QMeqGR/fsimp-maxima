## Why

fullsimp returns results that are not equal to its input. `radcan`, `rootscontract` and `logcontract` rewrite across branch cuts, and the search keeps whatever comes out smallest. `sqrt(x^2+2*x+1)` becomes `x+1`, `sqrt(x)*sqrt(x+1) - sqrt(x^2+x)` becomes `0` (it equals -4.9 at x = -3), and `diff(atan(x/sqrt(1-x^2)), x)` becomes `%i/sqrt(x^2-1)`, whose sign is wrong for |x| > 1. Declaring `assume(x < -1)` changes nothing. A simplifier that silently changes the value of an expression cannot be trusted for any later step.

A numeric audit of the existing test suite found that 11 of its 174 expected results are not identities. 7 fail when variables are negative (for example `log(a)+log(b)` → `log(a*b)` and `sqrt(4*x^2+8*x+4)` → `2*x+2`). 2 fail only when variables have mixed signs: `log(a)-log(b)` → `log(a/b)` and `log(x)-log(y)+log(z)` → `log((x*z)/y)`. 2 fail even for 0 < x < 1: `log((x+1)/(x^2-1))` → `-log(x-1)` and `((x^2-2*x+1)/(x^2+2*x+1))^0.5` → `(x-1)/(x+1)`.

## What Changes

- fullsimp checks every candidate result against the original input numerically before it can be accepted. A candidate that disagrees at any test point gets discarded.
- The test points respect the `assume` database and `declare`d features, so a rewrite that holds only under the user's assumptions is accepted exactly when those assumptions are in force.
- New option variable `fs_check` (default `true`). Setting it to `false` restores the current unchecked behaviour.
- With `fsdebug` at 1 or above, fullsimp reports each rejected candidate and the transform that produced it.
- **BREAKING**: the 11 test cases above no longer produce their recorded results without assumptions. They move under explicit assumptions that make them true (for example `assume(x > 1)`), and new unassumed versions record the correct result.

## Capabilities

### New Capabilities

- `result-verification`: fullsimp only returns results equal to its input, where "equal" is judged by numeric evaluation under the user's assumptions.

### Modified Capabilities

None. The repository has no specs yet.

## Impact

- `fsimp.mac`: the accept step in `fsimp` gains the check. New file `fscheck.mac` holds test-point generation and comparison, and the new option variable `fs_check`.
- `fsimp.lisp`: a portable numeric evaluator and the covering-design generator for test points.
- `rtest_fsimp2.mac`: 11 cases rewritten as described above.
- `docs/fsimp.texi` and `README.txt`: document `fs_check`, the assumption handling and the removable-singularity caveat. `docs/create_docs.sh` gets a one-character fix so examples with spaces produce a valid `rtest_example_fsimp.mac`.
- `tests/`: a runner for the rtest files and an independent audit of their expectations.
- Run time rises by one numeric evaluation of each candidate at a small fixed number of points.
- No change to the call signature, `fs_custom_simp` or the transform list.
