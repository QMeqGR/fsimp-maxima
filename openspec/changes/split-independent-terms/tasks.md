## 1. Preparation

- [x] 1.1 Confirm `add-equivalence-check` has merged, then record rtest results and run time, plus the time for `fullsimp(expand((a+b+c+d+u)^10) + sin(x)^2 + cos(x)^2)`, as the baseline

## 2. Grouping

- [x] 2.1 Implement the union-find partition of terms or factors by shared variables with a separate constant group, and verify it returns 3 groups for `expand((a+b+c+d+u)^10) + sin(x)^2 + cos(x)^2 - 1` and 1 group for `sin(x)^2 + cos(x)^2 + (x^2-1)/(x-1)`
- [x] 2.2 Verify the partition treats `c[1]` as a variable and puts `2*%pi` in the constant group

## 3. Integration

- [x] 3.1 Add `fs_split : true` and the split step at the start of the non-list branch of `fsimpall`, recursing on each group and combining with the original operator, and verify the sum and product scenarios in `specs/independent-term-splitting/spec.md`
- [x] 3.2 Check the combined result against the whole input and fall back to the unsplit path on failure, and verify the fallback with a test that forces a combine error
- [x] 3.3 Verify `fs_split : false` reproduces the baseline rtest results exactly
- [x] 3.4 Try constant terms with each group and alone, keeping the cheapest, and verify `1 - sin(x)^2 + tan(y)^2` gives `cos(x)^2 + tan(y)^2`
- [x] 3.5 Run a merge pass with `logcontract` and `rootscontract` on the combination, and verify `log(a) + log(b) + sin(t)^2 + cos(t)^2` under `assume(a > 0, b > 0)` gives `log(a*b) + 1`
- [x] 3.6 Add the split path's local variables to `tests/fsimp_check_collisions.mac` and verify it reports no differences
- [x] 3.7 Let each group take a shift (all the constants, or ±1 for trigonometric and hyperbolic groups) with the rest added back, move groups that simplify to constants into the constants, and keep groups over `fs_split_small` from taking any shift, and verify the new constant scenarios

## 4. Verification

- [x] 4.1 Add `rtest_fsimp_split.mac` covering every scenario in the spec, and verify it passes
- [x] 4.2 Run all rtest files with `fs_split : true`, review every changed result (including the `th`/`ph` case in `rtest_fsimp1.mac`), and verify all files pass
- [x] 4.3 Verify the motivating polynomial case finishes in under 1 s and record the time against the baseline in the pull request notes

## 5. Docs

- [x] 5.1 Document `fs_split`, the grouping rule and the cross-group factorisation trade-off in `docs/fsimp.texi` and `README.txt`, regenerate the docs, and verify `? fs_split` shows the entry
