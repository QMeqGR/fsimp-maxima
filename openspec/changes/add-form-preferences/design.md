## Context

Three places compare candidates by cost: the sweep (`fs_sweep`) accepts a step when the new cost is no higher, or up to 80% higher (`sizefactor`); the beam search (`fs_beam`, `fs_beam_pool`, `fs_rec_before`) orders candidates by cost and fills an uphill slot with candidates up to 1.8 times the cheapest; the split step (`fs_split_simp`) picks the cheapest placement of constants and guards the combination against the input. The sweep and the split step call `fscost`. The beam search computes `conssize(c) + slength(s)` inline, to reuse the string it already builds for the seen-set key.

The motivation and the list of preferences are in proposal.md. The behaviour each preference promises is in `specs/form-preferences/spec.md`.

A prototype on a scratch copy (beam patched to call `fscost`, preferences emulated by adding 10^6 per violation to `fscost`) gave the results quoted in the spec scenarios.

## Goals / Non-Goals

**Goals:**

- Make "which form" an explicit, ordered choice that every search and the split step respect in the same way.
- Leave results and run time unchanged when `fs_prefer` is `[]`.

**Non-Goals:**

- The preferences in `openspec/ideas/form-preferences.md` not marked as proposed.
- Display-level forms. `sqrt(3)/3` cannot be returned, because Maxima's simplifier turns it into `3^(-1/2)`.
- Numeric weights between preferences and size. A preference either decides between two candidates or it does not.
- New routines beyond `fs_rationalize`. A preference that no routine in the list can reach has no effect.

## Decisions

### A rank vector compared lexicographically

`fs_rank(e)` returns `[v1, ..., vk, fscost(e)]`, where `vi` is the violation count of the i-th entry of `fs_prefer`. Candidates compare lexicographically. With `fs_prefer : []` the rank is `[fscost(e)]`, so every comparison reduces to today's.

*Alternative:* add a weighted penalty to `fscost`, as the prototype did. Rejected. Any fixed weight loses to size on a large enough expression. It also distorts both uphill rules, which compare cost ratios: with a 10^6 penalty the 80% window either admits everything or nothing.

### Uphill moves use size only

The best candidate, the beam's cheapest slots and the sweep's acceptance of a step that is no worse all use rank. The uphill rules use the `fscost` element only. The sweep takes an uphill step when the size ratio is under `sizefactor`, whatever the violation counts. The beam's uphill slot takes the best-ranked candidate not already in the pool that ranks below the best candidate and whose size is at most `1 + sizefactor` times the best candidate's size. Ranking below the best is the rank form of the old "costlier than the best" condition, so the slot fills exactly as before when `fs_prefer` is `[]`. Reaching a preferred form can pass through forms with more violations: factoring can need an expansion first, and rationalising produces a longer intermediate.

*Alternative:* only allow uphill moves that do not add violations. Rejected, because it blocks those paths. The guarantees still hold, since the returned result is always the best-ranked candidate seen.

### The beam calls fscost

The beam computes size as `fscost(c)` instead of `conssize(c) + slength(s)`. This builds the string twice per candidate. On the four original rtest files the suite took 4.27 s inline and 4.28 to 4.37 s with `fscost`, inside run-to-run noise. It removes the difference between the searches and lets a user definition of `fscost` work in both.

### Violation counts work on the internal form

Counts walk the expression with `inflag : true`, so `sqrt(x)` is `x^(1/2)`, `a - b` is `a + (-1)*b` and `x/y` is `x*y^(-1)`. A denominator is a subexpression `u^n` with `n` a negative number.

- `rational_denominator`: denominators `u^n` where `n` is not an integer or `u` contains a power with a non-integer rational exponent. Counted everywhere, including inside function arguments.
- `single_fraction`: sums with a term that contains a denominator, plus denominators whose base contains a denominator.
- `factored`: sums containing a variable that `factor` rewrites as a product, a power or a negation.
- `expanded`: products with a sum factor, plus sums raised to an integer power above 1.
- `['avoid, f, ...]`, `sin_cos`, `exponential`: calls to the named functions, counted everywhere. `exponential` names the six trigonometric and six hyperbolic functions.
- `trigonometric`: powers of `%e` whose exponent contains `%i`, counted everywhere.

`single_fraction`, `factored` and `expanded` stop at function arguments. Users asking for a factored result mean the outer shape, and this keeps `factor` off every sum inside every `sin`.

### Routines for preferences

`rational_denominator` appends `fs_rationalize(e) := block([algebraic : true], ratsimp(e))` to the routine list while active. `fs_rationalize` joins `fs_safe_transforms`: it preserves value except at removable singularities, as `ratsimp` does (`x/(sqrt(x)+1)` becomes `(x^(3/2)-x)/(x-1)`, undefined at `x = 1`). The other preferences rely on routines already selected for expressions they apply to: `xthru`, `factor` and `expand` are always in the list, `trigsimp` and `exponentialize` whenever trig functions are present, `demoivre` whenever `%e` is. Exclusions passed to `fullsimp` still apply, so excluding the routine a preference needs leaves it unreachable without an error.

### Splitting

The constant placement and the final guard in `fs_split_simp` compare ranks. Violation counts add across groups, so a split result ranks the same as the unsplit combination of its parts. Two preferences need more:

- `single_fraction`: the merge pass also tries `xthru`, so `1/x + 1/y` (groups `x` and `y`) becomes `(y+x)/(x*y)`. Without it the prototype returned `1/y+1/x`.
- `factored`: sums are not split. A factorisation across groups (`(x+1)^2 - y^2` becomes `-((y-x-1)*(y+x+1))`) only exists for the whole sum. Products are still split. Splitting the sum returned `(x+1)^2-y^2` in the prototype.
- `expanded`: products are not split, for the same reason: `(x+1)*(y+1)` only expands as a whole. A review found that splitting returned it unchanged. Sums are still split.

### Validation

`fs_check_options` also checks `fs_prefer`: a list, each entry a known symbol or a list `['avoid, f, ...]` of one or more symbols, no opposed pair. Errors name `fs_prefer` and list the allowed entries.

### Debug output

With `fsdebug >= 1`, fullsimp prints the rank of the input and of the result.

## Risks / Trade-offs

- [`factored` calls `factor` on every sum outside function arguments of every candidate] → Measured at 0.31 s against 0.26 s for the expanded `(a+b+c+d+u)^10` in the prototype. Cache by expression string in the seen-set helper if a larger case shows otherwise.
- [Results get longer, by design] → The never-costlier guarantees become never-worse-ranked. The docs state this next to `fs_prefer`.
- [A count can call a form preferred that users would not, for example `(cos(t)+1)/sin(t)` over `cot(t/2)` under `sin_cos`] → That is what the preference says. Users who want `cot(t/2)` there use `['avoid, tan, sec, csc]`.
- [Unreachable preferences look like they do nothing] → `fs_rank` and the `fsdebug` output show the counts, so users can see the preference was evaluated.
- [`sin_cos` and `exponential` overlap, since the exponential form also has no `tan`] → Not an error. The order of entries decides.
