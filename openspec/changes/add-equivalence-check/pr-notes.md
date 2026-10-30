# PR notes: add-equivalence-check

Working notes for the pull request description. Not part of the OpenSpec artifacts.
Builds on three fixes: fstrigsimp (branch fix-fstrigsimp-eval), the name-length cost
(fix-name-length-cost) and packaging (fix-packaging), which add seven tests to
rtest_fsimp1.mac between them.

## Baseline (upstream plus the three fixes)

Maxima 5.50.0, SBCL, macOS. `tests/run_rtests.sh`:

- rtest_fsimp1.mac: 15/15 passed
- rtest_fsimp2.mac: 101/101 passed
- rtest_fsimp3.mac: 68/68 passed
- Total wall time: 2.8 s

The audit (`tests/fsimp_audit_rtests.mac`) found 11 of the 174 expected results are not identities, all in
rtest_fsimp2.mac: log(a)+log(b), log(a)-log(b), log(x-1)+log(x+1), log(x)-log(y)+log(z),
sqrt(x)*sqrt(y), sqrt(x^2+2*x+1), sqrt(x-1)*sqrt(x+1), sqrt(4*x^2+8*x+4),
(sqrt(x)+sqrt(y))^2-2*sqrt(x*y), log((x+1)/(x^2-1)), ((x^2-2*x+1)/(x^2+2*x+1))^0.5.
A first version of the audit gave every variable the same kind of value and found only 9.
log(a)-log(b) and log(x)-log(y)+log(z) only fail with mixed signs.

## After this change

`tests/run_rtests.sh` (each file in its own Maxima process):

- rtest_fsimp1.mac: 15/15 passed
- rtest_fsimp2.mac: 112/112 passed (the 11 cases above now run under assumptions that make
  them true, plus unassumed copies recording the new results)
- rtest_fsimp3.mac: 68/68 passed
- rtest_fsimp_check.mac (new, one test per spec scenario): 24/24 passed
- Wall time for the three original files: 3.1 to 3.6 s, against 2.8 s before. Most of it is
  Maxima start-up, one process per file.

The audit over all files: 181 cases, 0 non-identities, 1 case with no numeric value
(the unknown-function scenario).

With `fs_check : false`, the original three rtest files pass unchanged (177/177).

Large expression, `fullsimp(expand((a+b+c+d+u)^10))`, warm, three runs each:

- unchecked: 0.151 to 0.154 s
- checked: 0.180 to 0.190 s (about 1.2x)

A first implementation evaluated test points with Maxima's own float evaluation. It took
3.9 s on this input, because Maxima does complex arithmetic symbolically, and `rectform` on a
whole expression returns non-principal arguments for quotients. The Lisp evaluator in
fsimp.lisp fixes both.

## Found in review

An audit for code paths that compute the same thing in two ways found two faults here:

- The Lisp evaluator took principal roots, but Maxima takes real roots of negative reals
  (`(-8.0)^(1/3)` is `-2`). So the check accepted `%e^(log(x)/3)` rewritten to `x^(1/3)`, and
  likewise `x^(2/3)`, `x^(1/5)` and `x^(1/3)*y^(1/3)`, which Maxima evaluates differently for
  negative `x`. Powers of negative reals with odd-denominator rational exponents now take the
  real root. Over a grid of 30 functions at 15 points, the Lisp evaluator and Maxima's bigfloat
  evaluation now disagree only on the imaginary axis, which sample points avoid.
- Points where the input has no value, such as an unevaluated integral at numeric arguments,
  made Maxima print its error message once per point (48 lines for one call). The evaluator
  now runs with `errormsg` off.
- Stand-ins were only given to unquoted unknown functions, so `'f(log(a)+log(b))` was
  unverifiable and kept its form while `f(...)` simplified. The check now uses the same rule as
  the cost (`fs_name_excess`): a function Maxima has no simplifier for.

## Other changes in this PR

- `docs/create_docs.sh`: a misplaced brace in the awk that builds `rtest_example_fsimp.mac`
  put every space-separated token of an example on its own line. Examples with spaces in
  Maxima's echoed input (such as `assume(x > -1)`) came out broken. One-character fix.
- `docs/fsimp-index-html.lisp` was regenerated for the new `fs_check` entry. Its paths are
  absolute, as before, and keep the original `/home/ehm/...` prefix, so HTML help only works
  on the author's machine. Worth a separate fix (relative paths or `mxpm doc`).
- New `tests/run_rtests.sh` and `tests/fsimp_audit_rtests.mac`.

## Installing with mxpm

A simulated registry install (repo at `<userdir>/fullsimp/`) loads with `load("fsimp")`, and
`? fs_check` works. mxpm names the package after the repo by convention, but the entry file is
fsimp.mac, so a `manifest.toml` with `entry = "fsimp.mac"` would let `load("fullsimp")` style
instructions work. Not part of this change.
