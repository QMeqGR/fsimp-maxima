## Why

fullsimp always returns the smallest expression it finds, but users often want a particular form even when it is longer: a denominator free of radicals, a factored polynomial, sines and cosines instead of `csc` and `cot`, or exponentials instead of trig functions. Today the only ways to steer the result are excluding routines and adding `fs_custom_simp` entries. Neither changes how candidates rank, so `fullsimp(x/(sqrt(x)+1))` keeps the radical in the denominator even when a routine produces `(x^(3/2)-x)/(x-1)`. Redefining `fscost` works in the sweep only, because the beam search computes size without calling it.

## What Changes

- New option variable `fs_prefer`, a list of form preferences, default `[]`. With the default, results are unchanged.
- Each preference counts its violations in an expression. Candidates are ranked by the violation counts of the preferences in list order, then by `fscost`. The first entry matters most, and a candidate with fewer violations wins however large it is.
- The first set of preferences:
  - `rational_denominator`: no radical in any denominator.
  - `single_fraction`: no sum with a fractional term and no fraction inside a denominator.
  - `factored`: no sum that `factor` rewrites as a product or power.
  - `expanded`: no product with a sum factor and no sum raised to a positive integer power.
  - `['avoid, f1, f2, ...]`: no call to any of the named functions.
  - `sin_cos`: no `tan`, `cot`, `sec` or `csc`. Shorthand for `['avoid, tan, cot, sec, csc]`.
  - `exponential`: no trigonometric or hyperbolic function.
  - `trigonometric`: no `%e` raised to a power containing `%i`.
- `rational_denominator` adds a routine, `fs_rationalize` (`ratsimp` with `algebraic : true`), to the routine list while it is active. The other preferences use routines already in the list.
- Opposed pairs (`factored` with `expanded`, `exponential` with `trigonometric`) and unknown entries are errors that name `fs_prefer`.
- With `single_fraction` active, the merge pass after a split also tries `xthru`. With `factored` active, sums are not split, and with `expanded` active, products are not split, so factorisations and expansions across groups stay reachable.
- The beam search computes size through `fscost`, as the sweep does, so a user definition of `fscost` applies to both searches.
- New function `fs_rank(expr)` returns the ranking vector, for checking why one result beat another.

This change builds on `split-independent-terms`, which builds on `add-beam-search` and `add-equivalence-check`. Every candidate still has to pass the equivalence check. The full list of preference ideas, including those left for later, is in `openspec/ideas/form-preferences.md`.

## Capabilities

### New Capabilities

- `form-preferences`: the `fs_prefer` option, the meaning of each preference, how preferences rank candidates, and how they combine with the search guarantees and splitting.

### Modified Capabilities

None in `openspec/specs/`. The earlier changes are not archived yet, so the rank-based reading of their cost guarantees is stated as a requirement of `form-preferences`.

## Impact

- New `fsprefer.mac`, loaded by `fsimp.mac`: `fs_prefer`, its validation, the violation counts, `fs_rank` and `fs_rationalize`.
- `fsimp.mac`: rank comparisons in the sweep, the beam search and the split step, and the extra routine and merge-pass entries.
- `fscheck.mac`: `fs_rationalize` joins `fs_safe_transforms`.
- Run time with `fs_prefer : []`: unchanged, since no violation count runs. With preferences, each candidate pays for one scan per preference. `factored` also calls `factor` on each sum outside function arguments.
- `docs/fsimp.texi`, `README.txt`: document `fs_prefer`, each preference and `fs_rank`.
- New test file for the scenarios in the spec. Existing rtest files must pass unchanged. `tests/fsimp_check_collisions.mac` also runs with preferences active.
