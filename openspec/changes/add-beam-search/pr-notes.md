# PR notes: add-beam-search

Working notes for the pull request description. Not part of the OpenSpec artifacts.
Builds on add-equivalence-check (branch add-equivalence-check).

## Results

- `fullsimp(diff(atan(x/sqrt(1-x^2)), x))` now gives `1/sqrt(1-x^2)` (cost 28). The sweep gave
  `1/(sqrt(1-x)*sqrt(x+1))` (cost 47), because `factor` never saw the input.
- The beam computes each candidate's cost inline, reusing the string it builds for the seen-set
  key, so it subtracts `fs_name_excess` itself, as `fssize` does since fix-name-length-cost.
  rtest_fsimp_beam.mac checks that both searches give `-(%e^(%i*alpha)*cot(t/2))` for the doc
  example written in `alpha`.
- `tests/fsimp_compare_single.mac`: over 183 rtest inputs, the beam result is never costlier than a
  verified single transform. The sweep is costlier on the atan case (2 transforms beat it).
- One rtest result changed: `cot(x)*sin(2*x)` now gives `cos(2*x) + 1` instead of `2*cos(x)^2`.
  Both cost 18; the beam finds the first one first. Recorded in rtest_fsimp3.mac with a comment.
- With `fs_search : 'sweep`, all original rtest expectations pass unchanged (15, 112, 68, 24).
- All rtest files pass in beam mode: 12, 112, 68, 12 (new rtest_fsimp_beam.mac), 24.
- Audit: 183 cases, 0 non-identities.

## Variable names

The beam search's loop variable `p` exposed fstrigsimp evaluating its input a second time: with
the old fstrigsimp the doc example `(cos(t)+1)/((%i*sin(p)-cos(p))*sin(t))` failed. That fix
landed on its own first (branch fix-fstrigsimp-eval), since it affects the sweep too.

`tests/fsimp_check_collisions.mac` binds each of 83 names (every local and parameter on fullsimp's call
path, plus common single letters) to a sentinel value outside fullsimp, over 4 expressions and
both modes: 664 runs, 0 differences. With the old fstrigsimp it reports differences for p, r, i, e.

A first attempt renamed all variables to fresh uninterned symbols before searching. It was
dropped: Maxima's term order depends on variable names, and so did fsimp's cost before
fix-name-length-cost, so the renamed copy took different search paths and changed results.

## Timing

Maxima 5.50.0, SBCL, macOS.

- Suite (three original rtest files, one Maxima process each): beam 3.4 to 3.9 s, sweep 2.7 to 3.0 s.
- `fullsimp(expand((a+b+c+d+u)^10))`: beam 0.26 s, sweep 0.17 s (warm, two runs each).
- atan derivative: beam 0.011 s, sweep 0.004 s.
- `tan(x)+cot(x)`: beam 0.011 s, sweep 0.008 to 0.061 s.
