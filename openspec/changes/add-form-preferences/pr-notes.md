# PR notes: add-form-preferences

Working notes for the pull request description. Not part of the OpenSpec artifacts.
Branched from split-independent-terms; works with either search.

## Results

- With `fs_prefer : []`, every result of the 174 single-argument inputs in the three original
  rtest files is identical to the baseline, in both searches.
- New rtest_fsimp_prefer.mac: 26/26, one test per spec scenario. All seven rtest files: 15, 112,
  68, 12, 24, 26, 21. Doc examples: 12/12.
- Rank guarantee: for each preference on its own, over the 175 inputs of the three original files
  (now including the `alpha` test) and in both searches,
  no result ranks worse than its input. Inputs with fewer violations after fullsimp:
  rational_denominator 2, single_fraction 6, factored 63, expanded 51, [avoid, csc] 5,
  sin_cos 34, exponential 86, trigonometric 0 (beam search).
- tests/fsimp_check_collisions.mac (new locals, plus a pass with five preferences active): 1840 runs,
  0 differences.
- tests/fsimp_compare_single.mac: 198 inputs, none costlier than a verified single transform.
- Audit: 198 cases, 0 non-identities.

## Timing

Maxima 5.50.0, SBCL, macOS.

- Suite (three original rtest files): 3.75 to 3.77 s before, 3.69 to 3.80 s after. With the
  constant shifts of split-independent-terms underneath: 3.90 to 4.00 s.
- Beam calling fscost instead of computing size inline: results identical, suite 3.61 s.
- `fullsimp(expand((a+b+c+d+u)^10))`: 0.27 s before and after with no preferences; 0.33 s with
  `fs_prefer : ['factored]` against 0.30 s without in the same session, so no factor cache.

## Found during implementation

- tests/run_rtests.sh exited 1 for the full suite since split-independent-terms:
  rtest_fsimp_split.mac echoes an input containing "failed the equivalence check", and the
  runner matched any "failed". It now matches rtest's "problem(s) failed" summary only.
- The beam's uphill slot keeps its "ranked below the best" condition, so it fills exactly as
  before with no preferences. design.md says so.
- An audit for code paths that do the same thing twice found that `fs_simplist` and the split
  step read `fs_prefer` before `fsimp` validated it, so `fs_prefer : 'foo` gave Maxima's own
  "argument must be a non-atomic expression". `fsimpall` now checks the options first.
- The `exponential` preference uses the split step's list of trigonometric and hyperbolic
  functions (`fs_split_shift_funs`) instead of a copy of it.
- A review of the paper found that with `expanded` active, splitting kept `(x+1)*(y+1)` as it
  was, since each factor is already expanded. Products are now kept whole under `expanded`, as
  sums are under `factored`.
