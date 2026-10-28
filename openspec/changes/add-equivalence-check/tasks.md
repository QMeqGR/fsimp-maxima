## 1. Baseline

- [x] 1.1 Run `batch("rtest_fsimp1.mac", 'test)` and the same for rtest 2 and 3 on the current code, and record the pass counts and total run time in the pull request notes
- [x] 1.2 Add an audit script under `tests/` that checks each rtest expectation numerically against its input, with mixed as well as uniform signs across variables, and verify it reports the 11 known non-identities

## 2. Test points

- [x] 2.1 Add `fs_check : true` and a helper that saves the user's random state, seeds a fixed state and restores the user's state on exit, and verify with the random-state scenario from the spec
- [x] 2.2 Generate kinds from the pairwise covering design (OA(16,5,4,2) for up to 5 variables, greedy fill beyond, branch variables first) and build the 48 points from it, and verify every pair of variables in a 5-variable expression sees all 16 kind pairs from set A, and that a 7-variable expression still gets 48 points
- [x] 2.3 Implement fact parsing for single-variable bounds and `real`/`integer` features, and verify `assume(x < -1)` yields only points below -1
- [x] 2.4 Implement rejection sampling for multi-variable facts with the unconstrained fallback, and verify `assume(x > y)` yields points with x > y and an unsatisfiable fact set falls back without error

## 3. Comparison

- [x] 3.1 Add the Lisp numeric evaluator to `fsimp.lisp` (native arithmetic and elementary functions, Maxima fallback for other operators, signed-zero normalisation), and verify `log((x^2+3*x+2)/(x+2))` and `log(x+1)` agree at every test point
- [x] 3.2 Use the evaluator for float comparison with relative tolerance 1e-8, keep the bigfloat recheck at `fpprec : 40`, and verify the expanded `(a+b+c+d+u)^10` and its factored form compare equal while adding 1/1000 makes them differ
- [x] 3.3 Implement generic-function substitution for functions with no numeric definition, and verify `f(sin(x)^2+cos(x)^2)` and `f(1)` compare equal while `f(x)` and `f(-x)` do not
- [x] 3.4 Implement the value-preserving transform set and the fallback for expressions that cannot be evaluated, and verify a candidate from `radcan` on an unevaluable expression gets rejected
- [x] 3.5 Make powers of negative reals with odd-denominator rational exponents take Maxima's real root, and give quoted unknown functions stand-ins under the same rule as `fs_name_excess`, and verify the "Rewrite valid only on the principal branch" and "Quoted unknown function" scenarios

## 4. Integration

- [x] 4.1 Call the check in the accept step of `fsimp` for both downhill and uphill steps, comparing with the original input, and verify every scenario in `specs/result-verification/spec.md` with a new `rtest_fsimp_check.mac`
- [x] 4.2 Print `rejected <transform>: <candidate>` when `fsdebug >= 1`, and verify the `rootscontract` debug scenario
- [x] 4.3 Verify `fs_check : false` reproduces the baseline results from 1.1 exactly
- [x] 4.4 Verify `fullsimp(expand((a+b+c+d+u)^10))` with checking on takes no more than twice the unchecked time

## 5. Tests and docs

- [x] 5.1 Move the 11 non-identity cases in `rtest_fsimp2.mac` under `assume`/`forget` pairs that make them true, add unassumed copies with the new results checked by the audit script, and verify all rtest files pass
- [x] 5.2 Document `fs_check`, assumption handling and the removable-singularity caveat in `docs/fsimp.texi` and `README.txt`, regenerate the info and HTML docs with `docs/create_docs.sh`, and verify `? fs_check` shows the entry
- [x] 5.3 Record the full test-suite run time against the baseline from 1.1 in the pull request notes
