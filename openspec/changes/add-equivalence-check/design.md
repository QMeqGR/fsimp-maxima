## Context

`fsimp(expr, r)` sweeps the transform list `r` twice. After each transform it compares `fscost` of the result with the current state and either accepts it, accepts it as an uphill step (up to `sizefactor` = 0.8 larger), or drops it. Nothing compares a candidate with the input. The transforms that cause wrong answers are `radcan`, `rootscontract` and `logcontract`, which ignore the assume database, and the chains they start: in the atan derivative case `expand` grows the expression and `radcan` followed by `rootscontract` takes it across the cut.

See proposal.md for the failures and the test-suite audit.

## Goals / Non-Goals

**Goals:**

- Reject any candidate that differs in value from the input, with the check driven by the user's assumptions.
- Keep every existing correct simplification. The 163 audited test cases that are identities must still pass.
- Stay portable Maxima code with no Lisp-specific features.

**Non-Goals:**

- Proving equivalence symbolically. The check is numeric and probabilistic.
- Changing the search itself (see the separate `add-beam-search` and `split-independent-terms` changes).
- Handling `asksign` prompts raised inside transforms.
- Detecting differences confined to isolated points, such as removable singularities. `(x^2-1)/(x-1)` → `x+1` stays accepted, matching Maxima's own conventions.

## Decisions

### Check against the original input, not the previous state

Each candidate gets compared with the expression fullsimp was called with. Comparing with the previous accepted state would let small errors compound along a chain. Values of the original at the test points get computed once per call and cached, so each candidate costs one evaluation per point.

*Alternative:* compare with the previous state, which is cheaper when the original evaluates slowly. Rejected, because an error accepted once would become the reference for every later step.

### Test points

Each point gives every variable a value of one *kind*: positive real, negative real, or complex in one of the four quadrants (kept clear of the axes), with magnitude in [0.2, 1) ("small") or [1, 2) ("large"). Both magnitude classes are needed: the atan derivative only fails for |x| > 1.

Which kinds occur together matters as much as which kinds occur. `log(a)+log(b)` → `log(a*b)` is only wrong when both arguments lie in the left half-plane at once, and `log(a)-log(b)` → `log(a/b)` only when their signs differ. A first implementation that cycled kinds with a fixed offset per variable never put two variables in the same quadrant and accepted `log(a)+log(b)` → `log(a*b)`. Enumerating every combination is not an option either: with k kinds and n variables that is k^n points.

So the points follow a **pairwise covering design**: every pair of variables takes every combination of kinds somewhere in the set, while the number of points stays fixed. Branch-cut errors in the rewrites Maxima's transforms make involve pairs (a product or sum of two roots or logs) or reduce to a pair being wrong together. A triple like `sqrt(a)*sqrt(b)*sqrt(c)` → `sqrt(a*b*c)` already fails when one pair is negative.

- Points 1 to 16 use kind set A = {positive, negative, Q2, Q3} at small magnitude, arranged as the orthogonal array OA(16, 5, 4, 2) over GF(4). For up to 5 variables this covers all 16 kind pairs for every pair of variables.
- Points 17 to 32 repeat the same rows at large magnitude.
- Points 33 to 48 use kind set B = {positive, negative, Q1, Q4} in the same array, with magnitude alternating by variable, so the right half-plane and mixed magnitudes also occur.
- With more than 5 variables, the first 5 columns come from the array and the rest get filled greedily, one row at a time: each variable takes the kind that covers the most pairs not yet covered, with ties broken by a fixed rule. The point count stays at 48, so cost does not grow with n. Coverage of pairs among the later columns becomes partial.
- Variables that appear inside a multivalued function in the input (log, a non-integer power, inverse trig and inverse hyperbolic functions) are the ones whose combinations matter, so they take the first columns. Variables that appear only in polynomial or entire parts take the later ones.

Kinds A cover the left half-plane, where the principal branch cuts of log and roots lie, so they get both magnitude classes. Kinds B make sure all four quadrants appear, as the spec requires.

Points come from a fixed seed, so results are reproducible (see spec, "Results are reproducible"). fullsimp saves the user's random state with `make_random_state(false)` on entry and restores it on exit. The seed only chooses positions within each kind and magnitude class. The covering design fixes the kinds.

A point where the original fails to evaluate (division by zero, overflow, a non-numeric result) gets discarded. When that leaves too few points, extra draws with random kinds refill the set, up to 120 draws in total. For polynomials and rational functions a handful of points already makes false acceptance vanishingly unlikely (Schwartz–Zippel).

*Alternative:* sample only on the positive real line, the domain most users have in mind. Rejected, because it accepts exactly the rewrites that caused the reported wrong answers.

*Alternative:* random kinds per variable. Rejected, because a specific pair combination such as (Q2, Q2) then turns up with probability 1/36 per point and is missed most of the time.

### Assumption-aware sampling

Before generating points, read `facts()` and `featurep`:

- A variable with only single-variable bounds (`x > c`, `x >= c`, `x < c`, `x <= c`, with numeric `c`) gets real points inside the interval those bounds define. An unbounded side extends 2 units beyond the finite bound.
- `declare(x, real)` without bounds gives real points of both signs. `declare(n, integer)` gives integers in [-5, 5].
- Facts relating several variables (`x > y`) get handled by rejection sampling: draw candidate points from each variable's own domain and keep those for which `is()` of every fact evaluates to `true` after substitution.
- If fewer than half the point budget turns up within the attempt limit, fall back to unconstrained points. The fallback only rejects more candidates, never fewer, so it fails safe.

This gives fullsimp assumption-aware simplification without changing any transform. `radcan` keeps ignoring assumptions, and the check decides whether its output is acceptable under them.

### Numeric evaluator

Evaluating with `float(rectform(subst(point, e)))` has two faults:

- `rectform` applied to a whole expression computes `carg(p/q)` as `carg(p) - carg(q)`, which can leave (−π, π]. It made `log((x^2+3*x+2)/(x+2))` disagree with `log(x+1)`, which is an identity apart from the removable point x = −2.
- Maxima's simplifier does complex arithmetic symbolically. One evaluation of the expanded `(a+b+c+d+u)^10` (about 1000 terms) takes around 150 ms, and with checking on, fullsimp on that input went from 0.15 s to 3.9 s.

Evaluation therefore moves to a small Lisp evaluator in `fsimp.lisp`. It walks the expression bottom-up with Common Lisp double-float and complex arithmetic:

- `+`, `*` and powers natively. Integer powers use exact repeated multiplication. A negative real raised to a rational power with an odd denominator takes the real root, as Maxima does: `(-8)^(1/3)` is `-2` and `(-3)^(2/3)` is `3^(2/3)`. Other powers use CL `expt`, which takes the principal value. Taking the principal value everywhere would make the check accept `%e^(log(x)/3)` rewritten to `x^(1/3)`, which Maxima evaluates differently for negative `x`.
- Constants `%pi`, `%e`, `%i`, and the common elementary functions (exp, log, square root, the trig and hyperbolic functions and their inverses, abs, atan2) map to their CL counterparts, whose branch cuts follow the same principal-value conventions Maxima uses for numeric evaluation.
- Any other operator, such as `gamma` or `bessel_j`, is handed to Maxima with numeric arguments (`float(rectform(f(args)))`) and the result converted back. Each function receives a number, so every value is principal.
- A complex result whose imaginary part is ±0.0 becomes real. Otherwise the sign of a zero imaginary part could put two equal expressions on opposite sides of a cut.
- Any error, overflow or non-finite result makes the point unusable for that expression, exactly as before.

The evaluator is standard Common Lisp with no implementation-specific features, so it runs on every Lisp Maxima supports.

*Alternative:* evaluate bottom-up in Maxima with `scanmap(..., bottomup)`. That fixes the branch issue but not the speed.

*Alternative:* the maxima-numerics library. Rejected: it is SBCL-only and depends on Quicklisp, magicl and BLAS, while the task needs only scalar complex arithmetic.

### Comparison and precision

Compare with relative tolerance 1e-8: reject if `|c - o| > 1e-8 * (1 + |o|)`. Float evaluation can lose precision through cancellation in large expressions, so a mismatch gets rechecked in Maxima bigfloat with `fpprec : 40`, evaluated bottom-up, before the candidate is rejected. The recheck only runs on mismatches, so its cost falls on candidates about to be rejected.

### Unknown functions

An expression like `f(sin(x)^2+cos(x)^2)` gives a non-numeric value at every point. Before evaluation, replace each function with no numeric definition, quoted or not, by a fixed generic function of its arguments, `exp(c1*a1 + c2*a2 + ...)` with fixed irrational coefficients. If two expressions agree for every `f`, they agree for this one. A function counts as unknown under the same rule `fs_name_excess` uses for the cost: its operator has no simplifier in Maxima. A first version only looked at unquoted names, so `'f(x)` stayed unevaluable and its expressions fell back to value-preserving routines only. A false acceptance would need a wrong rewrite that happens to agree for this particular choice, which is negligible.

If a candidate still cannot be evaluated at enough points (for example because it contains unevaluated integrals), accept it only if every transform on its path preserves value everywhere. That set includes `ratsimp`, `fullratsimp`, `factor`, `expand`, `combine`, `xthru`, `multthru`, `resimplify`, `trigsimp`, `trigreduce`, `trigexpand`, `trigrat`, `minfactorial`, `exponentialize`, `demoivre` and `fstrigsimp`. `radcan`, `rootscontract`, `logcontract` and all `fs_custom_simp` entries are outside it, because they are known to be unsafe or unknown.

### Option and debug output

`fs_check` (default `true`) wraps the check in a single test, so `fs_check : false` takes exactly the old code path. When `fsdebug >= 1`, print `rejected <transform>: <candidate>` for each rejection, in keeping with the existing debug levels.

### Test-suite migration

For each of the 11 non-identity cases, keep the original expectation inside an `assume`/`forget` pair that makes it true (`assume(a > 0, b > 0)` for `log(a)+log(b)`, `assume(x > 1)` for the `log((x+1)/(x^2-1))` case, and so on). Add an unassumed copy that records what fullsimp now returns, after checking that result numerically. This keeps the intent of each test and documents the new behaviour.

## Risks / Trade-offs

- [Maxima's float and bigfloat `atan` pick opposite signs on the imaginary-axis branch cut, so the float evaluation and the bigfloat recheck can disagree there] → Sample points stay clear of the axes, so only arguments such as `%i*x` reach the cut, and only the recheck uses bigfloat.

- [A wrong rewrite that agrees at all sampled points] → The covering design guarantees every kind pair for up to 5 branch variables. Errors that need three variables in a specific joint configuration, or that only show at points the kinds avoid (exactly on an axis), stay possible. The spec scenarios document the guarantee as numeric.
- [Partial pair coverage beyond 5 branch variables] → Branch variables take the first columns, and the greedy fill keeps adding coverage in later columns. Raising the point budget would extend full coverage, at a linear cost.
- [Slower calls on large expressions] → 48 evaluations per candidate in Lisp, with the original's values cached. Operators the evaluator does not know go through Maxima one call at a time and cost more. Report the timings for the suite and for the 1000-term polynomial against the unchecked baseline.
- [Evaluator and Maxima disagree on a function's convention] → Both sides of each comparison go through the same evaluator, so a differing convention only matters if it makes a true identity fail. The spec scenarios and the full rtest suite exercise the supported functions.
- [Assumption parsing misses fact forms] → Unrecognised facts fall through to rejection sampling and then to the unconstrained fallback, which can only reject more.
- [Reduced output for users who relied on the unsafe rewrites] → Documented as **BREAKING**, with `fs_check : false` as the escape hatch and `assume` as the correct fix.

## Migration Plan

Ship as one pull request. Users who want the old results set `fs_check : false`. Rollback means reverting the commit, since no stored data or interface depends on it.
