## 1. Preparation

- [x] 1.1 Confirm `add-equivalence-check` has merged, then record rtest pass counts, results and run time with the current search as the baseline
- [x] 1.2 Move the existing loop into `fs_sweep(expr, r)` without changing it, dispatch from `fsimp`, and verify the rtest results match the baseline exactly

## 2. Options

- [x] 2.1 Add `fs_beam_width : 4`, `fs_max_rounds : 4` and `fs_search : 'beam` with validation, and verify invalid values signal an error that names the option and its allowed values

## 3. Beam search

- [x] 3.1 Add the seen-set helpers (create, test-and-insert) to `fsimp.lisp` using an `equal` hash table, and verify inserting the same string twice reports a duplicate
- [x] 3.2 Implement `fs_beam` with the permanent anchor slot, the cheapest-candidate slots and the reserved uphill slot, and verify `fullsimp(diff(atan(x/sqrt(1-x^2)), x))` returns `1/sqrt(1-x^2)`
- [x] 3.3 Implement termination when a round adds no pool member or after `fs_max_rounds`, and verify with `fsdebug : 2` that the trace shows the round count and stop reason
- [x] 3.4 Implement tie-breaking by discovery order, and verify repeated calls on `sin(x)^2 + 2*cos(x)^2` return identical results
- [x] 3.5 Verify with `tests/fsimp_check_collisions.mac` that binding any local variable name outside fullsimp leaves results unchanged in both modes (this needed the fstrigsimp fix, which landed separately on `fix-fstrigsimp-eval`)

## 4. Verification

- [x] 4.1 Add `rtest_fsimp_beam.mac` covering every scenario in `specs/search-strategy/spec.md`, and verify it passes
- [x] 4.2 Add a test that compares fullsimp with every single transform (followed by `combine`) on the rtest inputs, and verify fullsimp is never costlier than a verified single transform
- [x] 4.3 Run all rtest files with `fs_search : 'beam`, review every changed result, record cheaper verified results in the test files, and verify all files pass
- [x] 4.4 Run all rtest files with `fs_search : 'sweep` and verify the results match the baseline from 1.1

## 5. Docs and timing

- [x] 5.1 Document the three options and the new algorithm in `docs/fsimp.texi` and `README.txt`, regenerate the docs, and verify `? fs_beam_width` shows the entry
- [x] 5.2 Record suite run times for both modes against the baseline in the pull request notes
