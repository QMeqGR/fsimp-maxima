# PR notes: split-independent-terms

Working notes for the pull request description. Not part of the OpenSpec artifacts.
Branched from add-beam-search, since both change fsimp.mac; works with either search.

## Results

- `fullsimp(expand((a+b+c+d+u)^10) + sin(x)^2 + cos(x)^2)` gives `(a+b+c+d+u)^10 + 1` in
  0.37 s (warm). Before: 16.4 s with the beam search, 7.9 s with the sweep, both returning an
  expanded factorisation of `p^10 + 1` (cost 20149).
- `(1+cos(t))/sin(t) + (exp(y)-exp(-y))/(exp(y)+exp(-y))` gives `cot(t/2) + tanh(y)`, and the
  matching product `cot(t/2)*tanh(y)`. The beam search gives the same results without splitting.
- Constants divided between groups: `1 - sin(x)^2 + tan(y)^2 + 1` gives `cos(x)^2 + sec(y)^2`,
  `cosh(z)^2 - sin(x)^2` gives `sinh(z)^2 + cos(x)^2`, and `x^2 + 2*x + sin(y)^2 + cos(y)^2`
  gives `(x + 1)^2`.
- `expand((a+b+c+d+u)^10) + sin(x)^2 + cos(x)^2 - 1` gives `(a+b+c+d+u)^10` in 0.4 s. When the
  -1 was tried with the polynomial group it took 3.0 s; the trigonometric group now simplifies to 1
  and joins the constants, which then cancel.
- `expand((a+b+c+d+u)^10) + sin(x)^2 - 1` takes 0.5 s. Without the size limit the polynomial takes
  the -1 and the call takes 3.0 s.
- 60 random sums and products of rtest inputs with disjoint variables: splitting gives a cheaper
  result than `fs_split : false` in 6 and a costlier one in none. Time 2.5 s split, 1.5 s unsplit.
- All existing rtest expectations pass unchanged with splitting on, and with `fs_split : false`.
- New rtest_fsimp_split.mac: 21/21. All six rtest files: 15, 112, 68, 12, 23, 21.
- tests/fsimp_check_collisions.mac (split-path locals added): 832 runs, 0 differences.
- tests/fsimp_compare_single.mac: 196 inputs, beam never costlier than a verified single transform.
- Audit: 196 cases, 0 non-identities.
- Suite time (three original files): 3.70 to 3.77 s.

## Design changes found during implementation

The proposal kept constants as a group of their own and returned the combination without any
further search. With that, 13 existing tests failed:

- Constants interact with groups: `1 - sin(x)^2` → `cos(x)^2`, `1 + tan(x)^2` → `sec(x)^2`,
  `2*tan(x)/(1+tan(x)^2)` → `sin(2*x)` (7 tests). Now fullsimp only splits when at least two
  groups contain variables, and tries the constants with each group and alone, keeping the
  cheapest.
- Disjoint groups can merge: `log(a)+log(b)` → `log(a*b)`, `sqrt(x)*sqrt(y)` → `sqrt(x*y)` under
  assumptions (6 tests). Now the combination gets one more search restricted to `logcontract` and
  `rootscontract`.

- Constants placed in one group could not serve two groups. `1 - sin(x)^2 + tan(y)^2 + 1` gave
  `cos(x)^2 + tan(y)^2 + 1`, worse than `cos(x)^2 + sec(y)^2` from the unsplit search, and
  `2*cos(u)^2 - sin(x)^2` stayed as it was. Now each group can take a shift: all the constants,
  or +1 or -1 if it contains a trigonometric or hyperbolic function. Groups over size 1000 take
  no shift. A zero product from a group that
  simplifies to 0 is returned directly.

Known limits, documented under `fs_split`:

- Factorisations across groups, such as `(x+1)^2 - y^2` → `(x+1-y)*(x+1+y)`, are not found.
- Constants other than ±1 that would need dividing between groups (such as 1/2 for each) are not
  divided.

## Test tooling note

The audit and comparison scripts parse rtest inputs without evaluating them, so
`fullsimp(expand(...))` reaches them as an unevaluated `expand` call and counts as "not numerically
checkable". The rtest itself checks that case.
