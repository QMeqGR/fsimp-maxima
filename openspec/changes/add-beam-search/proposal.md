## Why

fullsimp keeps a single current state and applies each transform to it in a fixed order. Once an early transform changes the expression, later transforms never see the original. For `diff(atan(x/sqrt(1-x^2)), x)`, `expand` grows the expression before `factor` runs, so fullsimp misses `1/sqrt(1-x^2)`, which `factor` alone produces from the input. With unsafe rewrites rejected by `add-equivalence-check`, the current search would return the unsimplified input here, a worse result than the best single built-in command.

## What Changes

- Replace the single-state sweep with a small beam search. Each round applies every transform to every member of a pool of candidates and keeps the cheapest few, plus one uphill candidate so the existing annealing behaviour survives.
- The original input stays in the pool for the whole search, so every transform gets applied to it.
- Expressions already seen get skipped, so the wider search does not repeat work.
- New option variables: `fs_beam_width` (pool size, default 4), `fs_max_rounds` (default 4) and `fs_search` (`'beam`, the default, or `'sweep` for the current algorithm).
- The result is never costlier than the input or than any verified single transform of the input.

This change builds on `add-equivalence-check`: every candidate the beam keeps must pass the equivalence check. Without it, a wider search would find wrong answers faster.

## Capabilities

### New Capabilities

- `search-strategy`: what fullsimp guarantees about the quality of its result relative to the input and to single transforms, and how the user bounds and selects the search.

### Modified Capabilities

None. `result-verification` requirements stay unchanged.

## Impact

- `fsimp.mac`: `fsimp` gets a new beam implementation alongside the existing sweep, selected by `fs_search`. `fsimpall` passes the transform list as before.
- Run time: up to `fs_beam_width` times more transform calls per round in the worst case. The seen-set and early stopping cut this in practice. The pull request reports full test-suite timings for both modes.
- `docs/fsimp.texi`, `README.txt`: document the three new options and update the algorithm description.
- New test file for the scenarios in the spec. Existing rtest files must pass unchanged.
