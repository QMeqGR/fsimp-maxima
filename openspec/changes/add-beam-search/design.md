## Context

`fsimp` holds one state, `smallestExpr`, and for `loopmax` = 2 sweeps applies `combine(r[i](smallestExpr))` for each transform in order. A result up to `sizefactor` = 0.8 larger than the state replaces it (the uphill step), and `expr` tracks the best result seen. Each transform only ever sees whatever the previous transform left behind. The trace for the atan derivative shows the effect: `expand` takes the cost from 115 to 160, the uphill rule accepts it, and `factor` never runs on the original.

This change assumes `add-equivalence-check` has landed. Every candidate below passes through that check before it can join the pool.

## Goals / Non-Goals

**Goals:**

- Apply every transform to the original input at least once.
- Keep the uphill exploration that lets fullsimp pass through a larger intermediate form.
- Keep the old algorithm available for comparison and as a fallback.

**Non-Goals:**

- Simplifying parts of an expression separately (see `split-independent-terms`).
- Changing the transform list or the cost function.
- Wall-clock time limits. Maxima has no portable timeout, so the search gets bounded by width and rounds.

## Decisions

### Pool structure

The pool holds up to `fs_beam_width` candidates. The original input occupies one permanent slot (the anchor) and never gets evicted. The remaining slots hold the cheapest verified candidates found so far, except one slot reserved for the best uphill candidate: the cheapest candidate costlier than the current best but within `(1 + sizefactor)` times its cost. That reserved slot is how the beam keeps Eric's annealing idea.

With `fs_beam_width : 1`, the pool holds only the best candidate, and the search reduces to a greedy hill-climb that still starts from the original.

*Alternative:* plain best-first search with no reserved uphill slot. Rejected, because the existing tests rely on passing through larger forms, for example `trigexpand` before `trigsimp`.

### Rounds and termination

Each round applies every transform to every pool member that has not been expanded before. Each new candidate gets costed, checked for duplicates, verified, and offered to the pool. The search stops when a round adds no new member to the pool, or after `fs_max_rounds` rounds. The anchor gets expanded in round 1 only, because it never changes.

Worst case work is `fs_max_rounds × fs_beam_width × |transforms|` transform calls, about 4 × 4 × 25 = 400 against today's 2 × 25 = 50. In practice most rounds end early because transforms reproduce expressions already seen.

### Seen set

Key each candidate by `string(expr)`. `fscost` already computes this string for its length term, so the cost and the key come from one `string` call per candidate. Store keys in a Lisp `equal` hash table created per call through a helper in `fsimp.lisp`. A Maxima list with `member` would cost O(n) per lookup, and n reaches a few hundred.

*Alternative:* key by `conssize` plus a structural hash. Rejected, because the string is computed anyway and is exact.

### Tie-breaking

Among equal-cost candidates, prefer the earlier one in discovery order: round number first, then pool position, then the transform's position in the list. Discovery order depends only on the input and the options, so results stay reproducible.

### Keeping the sweep

Move the current loop unchanged into `fs_sweep(expr, r)`, and add `fs_beam(expr, r)`. `fsimp` dispatches on `fs_search`, after checking that `fs_beam_width` and `fs_max_rounds` are positive integers and `fs_search` is `'beam` or `'sweep`. Keeping the old code path makes A/B comparison straightforward for review and gives users a fallback.

## Risks / Trade-offs

- [Up to 8× more transform calls on large expressions] → The seen set and early stopping reduce this. Expensive transforms on large candidates are the main cost, so the pull request reports suite timings for both modes. If the default costs too much, lower the default `fs_beam_width` to 3 rather than drop the anchor.
- [A different but equally cheap result changes test expectations] → Deterministic tie-breaking keeps results stable. Any rtest case whose result changes gets reviewed: if the new result is cheaper and verified, the test records it. Otherwise that counts as a bug in the beam.
- [Hash table helper is Lisp code] → `make-hash-table :test #'equal` is standard Common Lisp and works on every Lisp Maxima supports.
