## 1. Preparation

- [ ] 1.1 Record rtest results, suite time and the time for `fullsimp(expand((a+b+c+d+u)^10))` on the `split-independent-terms` tip as the baseline
- [ ] 1.2 Make the beam search compute size with `fscost`, and verify the rtest results match the baseline exactly and the suite time stays within noise

## 2. Ranking

- [ ] 2.1 Add `fs_prefer : []` and `fs_rank`, with `fs_rank(e)` returning `[fscost(e)]` for the empty list, and verify the "Rank with no preferences" scenario
- [ ] 2.2 Switch the sweep, the beam pool order, the best-candidate choice and the split step's constant placement and guard to lexicographic rank comparison, keeping both uphill rules on size, and verify the rtest results still match the baseline exactly
- [ ] 2.3 Add `fs_prefer` validation to `fs_check_options`, and verify the three error scenarios
- [ ] 2.4 Print the rank of the input and the result at `fsdebug >= 1`, and verify with a traced run

## 3. Preferences

- [ ] 3.1 Implement the shared walker on the internal form, with and without descent into function arguments, and the `['avoid, ...]`, `sin_cos`, `exponential` and `trigonometric` counts, and verify the "Rank of an expression" scenario and the function-family scenarios
- [ ] 3.2 Implement `rational_denominator` and `fs_rationalize`, add `fs_rationalize` to the routine list while the preference is active and to `fs_safe_transforms`, and verify the three rational-denominator scenarios
- [ ] 3.3 Implement `single_fraction` and add `xthru` to the merge pass while it is active, and verify both single-fraction scenarios
- [ ] 3.4 Implement `factored` and `expanded` and turn off splitting of sums while `factored` is active, and verify the three factored and expanded scenarios
- [ ] 3.5 Verify the "Same preference in both searches" scenario and the "Redefined cost in the beam search" scenario

## 4. Verification

- [ ] 4.1 Add `rtest_fsimp_prefer.mac` covering every scenario in `specs/form-preferences/spec.md`, and verify it passes
- [ ] 4.2 Run the rtest inputs with each preference in turn and verify `fs_rank(fullsimp(e))` is never lexicographically greater than `fs_rank(e)`
- [ ] 4.3 Add the new local variables to `tests/fsimp_check_collisions.mac`, and verify it reports no differences
- [ ] 4.4 Time `fullsimp(expand((a+b+c+d+u)^10))` with `fs_prefer : ['factored]` against the baseline, and cache `factor` results by expression string if it costs more than twice the baseline

## 5. Docs

- [ ] 5.1 Document `fs_prefer`, each preference, the rank-based guarantees and `fs_rank` in `docs/fsimp.texi` and `README.txt`, regenerate the docs, and verify `? fs_prefer` shows the entry
