## Purpose

Defines the quality guarantees of fullsimp's search, relative to its input and to single transforms, and the options that bound and select the search.

## ADDED Requirements

### Requirement: No worse than any single transform

fullsimp SHALL return a result whose cost is no greater than the cost of any single transform from its transform list applied to the input, counting only results that pass the equivalence check. A single transform means the transform followed by `combine`, which is how fullsimp applies every transform. Cost is the value of `fscost`.

#### Scenario: Factor applied to the input

- **WHEN** the user evaluates `fullsimp(diff(atan(x/sqrt(1-x^2)), x))` with no assumptions
- **THEN** the result SHALL be `1/sqrt(1-x^2)` or an expression of equal or lower cost that passes the equivalence check

#### Scenario: Built-in comparison

- **WHEN** the user evaluates fullsimp on any expression `e` and on each single transform `t(e)` from the transform list
- **THEN** `fscost(fullsimp(e))` SHALL be less than or equal to `fscost(combine(t(e)))` for every `combine(t(e))` that passes the equivalence check

### Requirement: Never costlier than the input

fullsimp SHALL return its input unchanged when no candidate cheaper than the input passes the equivalence check.

#### Scenario: Nothing simpler exists

- **WHEN** the user evaluates `fullsimp((x^10 - 1)/(x - 1))`
- **THEN** the result SHALL have cost no greater than the input

### Requirement: Existing simplifications are kept

The beam search SHALL reach a result of equal or lower cost than the sweep search on every case in the existing rtest files.

#### Scenario: Regression suite

- **WHEN** the rtest files `rtest_fsimp1.mac` to `rtest_fsimp3.mac` run with `fs_search : 'beam`
- **THEN** every case SHALL pass, or produce a result of lower cost that passes the equivalence check, and the test file SHALL record that new result

#### Scenario: Multi-step trig result

- **WHEN** the user evaluates `fullsimp(tan(x) + cot(x))`
- **THEN** the result SHALL be `2*csc(2*x)`

### Requirement: Bounded and selectable search

The option variables `fs_beam_width` (default 4) and `fs_max_rounds` (default 4) SHALL bound the search. Setting `fs_search : 'sweep` SHALL select the search algorithm fullsimp used before this change, and `fs_search : 'beam` (the default) SHALL select the beam search.

#### Scenario: Sweep mode reproduces the old search

- **WHEN** the user sets `fs_search : 'sweep` and runs the rtest files
- **THEN** every result SHALL match the result from the sweep search before this change

#### Scenario: Width one

- **WHEN** the user sets `fs_beam_width : 1` and evaluates `fullsimp(sin(x)^2 + cos(x)^2)`
- **THEN** the result SHALL be `1`

#### Scenario: Invalid option

- **WHEN** the user sets `fs_beam_width : 0` or `fs_search : 'other` and calls fullsimp
- **THEN** fullsimp SHALL signal an error naming the option and its allowed values

### Requirement: Deterministic choice between equal costs

When several candidates have equal cost, fullsimp SHALL pick between them by a fixed rule that does not depend on evaluation timing or memory layout.

#### Scenario: Repeated calls agree under the beam search

- **WHEN** the user evaluates `fullsimp(sin(x)^2 + 2*cos(x)^2)` twice with the same options
- **THEN** both calls SHALL return the same expression
