## Purpose

Lets the user state which form of an expression fullsimp should return, through an ordered list of form preferences that take priority over size.

## ADDED Requirements

### Requirement: No preferences by default

fullsimp SHALL provide an option variable `fs_prefer`, default `[]`. With `fs_prefer : []`, fullsimp SHALL return the same results as without this change.

#### Scenario: Default results unchanged

- **WHEN** the rtest files are run with `fs_prefer : []`
- **THEN** every existing test SHALL pass with its current expected result

#### Scenario: Smallest form by default

- **WHEN** the user evaluates `fullsimp(tan(x) + cot(x))` with `fs_prefer : []`
- **THEN** the result SHALL be `2*csc(2*x)`

### Requirement: Preferences rank before size

When `fs_prefer` is not empty, fullsimp SHALL rank each candidate by the number of violations of each preference, in list order, and then by `fscost`. A candidate with fewer violations of an earlier preference SHALL rank better regardless of later preferences and of cost. fullsimp SHALL return the best-ranked candidate that passes the equivalence check.

#### Scenario: A longer result with fewer violations wins

- **WHEN** the user evaluates `fullsimp(tan(x) + cot(x))` with `fs_prefer : ['sin_cos]`
- **THEN** the result SHALL be `2/sin(2*x)`, although `2*csc(2*x)` costs less

#### Scenario: Equal violations fall back to cost

- **WHEN** the user evaluates `fullsimp(x^2 + 1)` with `fs_prefer : ['factored]`
- **THEN** the result SHALL be `x^2 + 1`, since no candidate has fewer violations and none costs less

### Requirement: Rank is visible

fullsimp SHALL provide a function `fs_rank(expr)` that returns a list of the violation counts of `expr` for each entry of `fs_prefer`, in order, followed by `fscost(expr)`.

#### Scenario: Rank of an expression

- **WHEN** the user evaluates `fs_rank(cot(x)/sqrt(2))` with `fs_prefer : ['sin_cos, 'rational_denominator]`
- **THEN** the result SHALL be `[1, 1, fscost(cot(x)/sqrt(2))]`

#### Scenario: Rank with no preferences

- **WHEN** the user evaluates `fs_rank(e)` with `fs_prefer : []`
- **THEN** the result SHALL be `[fscost(e)]`

### Requirement: Rational denominators

The preference `rational_denominator` SHALL count each denominator that is a fractional power or contains one, including inside function arguments. While it is active, fullsimp SHALL also try rationalising denominators with algebraic rational simplification.

#### Scenario: Numeric radical

- **WHEN** the user evaluates `fullsimp(1/(1 + sqrt(2)))` with `fs_prefer : ['rational_denominator]`
- **THEN** the result SHALL be `sqrt(2) - 1`

#### Scenario: Symbolic radical

- **WHEN** the user evaluates `fullsimp(x/(sqrt(x) + 1))` with `fs_prefer : ['rational_denominator]`
- **THEN** the result SHALL be `(x^(3/2) - x)/(x - 1)`

#### Scenario: Rewrites that fail the check stay rejected

- **WHEN** the user evaluates `fullsimp(1/sqrt(x^2 + 2*x + 1))` with `fs_prefer : ['rational_denominator]` and no assumptions
- **THEN** the result SHALL NOT be `1/(x + 1)`, which is wrong for `x < -1`

### Requirement: Single fraction

The preference `single_fraction` SHALL count each sum that has a term with a denominator, and each denominator whose base contains a denominator, outside function arguments.

#### Scenario: Sum with a fraction

- **WHEN** the user evaluates `fullsimp(x + 1/x)` with `fs_prefer : ['single_fraction]`
- **THEN** the result SHALL be `(x^2 + 1)/x`

#### Scenario: Fractions in independent variables

- **WHEN** the user evaluates `fullsimp(1/x + 1/y)` with `fs_prefer : ['single_fraction]`
- **THEN** the result SHALL be `(y + x)/(x*y)`

### Requirement: Factored and expanded

The preference `factored` SHALL count each sum containing a variable that `factor` rewrites as a product, power or negation, outside function arguments. The preference `expanded` SHALL count each product with a sum factor and each sum raised to an integer power above 1, outside function arguments. While `factored` is active, fullsimp SHALL NOT split sums into independent groups.

#### Scenario: Factored polynomial

- **WHEN** the user evaluates `fullsimp(x^3 - x)` with `fs_prefer : ['factored]`
- **THEN** the result SHALL be `(x - 1)*x*(x + 1)`

#### Scenario: Factorisation across independent terms

- **WHEN** the user evaluates `fullsimp((x + 1)^2 - y^2)` with `fs_prefer : ['factored]`
- **THEN** the result SHALL be `-((y - x - 1)*(y + x + 1))`

#### Scenario: Expanded polynomial

- **WHEN** the user evaluates `fullsimp((x + 1)^2)` with `fs_prefer : ['expanded]`
- **THEN** the result SHALL be `x^2 + 2*x + 1`

### Requirement: Function families

The preference `['avoid, f1, f2, ...]` SHALL count each call to any named function, including inside function arguments. `sin_cos` SHALL count as `['avoid, tan, cot, sec, csc]`. `exponential` SHALL count each call to `sin`, `cos`, `tan`, `cot`, `sec`, `csc`, `sinh`, `cosh`, `tanh`, `coth`, `sech` or `csch`. `trigonometric` SHALL count each power of `%e` whose exponent contains `%i`.

#### Scenario: Avoiding one function

- **WHEN** the user evaluates `fullsimp(tan(x) + cot(x))` with `fs_prefer : [['avoid, csc]]`
- **THEN** the result SHALL be free of `csc`

#### Scenario: Exponential form

- **WHEN** the user evaluates `fullsimp(cosh(x))` with `fs_prefer : ['exponential]`
- **THEN** the result SHALL be `(%e^x + %e^-x)/2`

#### Scenario: Trigonometric form

- **WHEN** the user evaluates `fullsimp(%e^(%i*x))` with `fs_prefer : ['trigonometric]`
- **THEN** the result SHALL be `%i*sin(x) + cos(x)`

### Requirement: Invalid preferences are errors

fullsimp SHALL signal an error naming `fs_prefer` when it is not a list, when an entry is not a known preference or an `avoid` list of one or more symbols, or when it contains both `factored` and `expanded` or both `exponential` and `trigonometric`.

#### Scenario: Unknown entry

- **WHEN** the user evaluates `fullsimp(x)` with `fs_prefer : ['shortest]`
- **THEN** fullsimp SHALL signal an error whose message contains `fs_prefer`

#### Scenario: Opposed preferences

- **WHEN** the user evaluates `fullsimp(x)` with `fs_prefer : ['factored, 'expanded]`
- **THEN** fullsimp SHALL signal an error whose message contains `fs_prefer`

#### Scenario: Empty avoid list

- **WHEN** the user evaluates `fullsimp(x)` with `fs_prefer : [['avoid]]`
- **THEN** fullsimp SHALL signal an error whose message contains `fs_prefer`

### Requirement: Search guarantees use rank

When `fs_prefer` is not empty, fullsimp's guarantees about its result SHALL compare rank instead of cost: the result SHALL rank no worse than the input, and no worse than any single transform from the routine list applied to the input that passes the equivalence check. Both searches and the split step SHALL rank candidates the same way.

#### Scenario: Never worse ranked than the input

- **WHEN** the user evaluates `fullsimp(e)` with any valid `fs_prefer`
- **THEN** `fs_rank(fullsimp(e))` SHALL be lexicographically no greater than `fs_rank(e)`

#### Scenario: Same preference in both searches

- **WHEN** the user evaluates `fullsimp(tan(x) + cot(x))` with `fs_prefer : ['sin_cos]` and `fs_search : 'sweep`
- **THEN** the result SHALL be free of `tan`, `cot`, `sec` and `csc`

### Requirement: A user cost function applies to both searches

fullsimp SHALL compute candidate size by calling `fscost` in both searches and in the split step, so that a user redefinition of `fscost` changes the ranking everywhere.

#### Scenario: Redefined cost in the beam search

- **WHEN** the user defines `fscost(e) := fssize(e) + (if freeof(csc, e) then 0 else 10^6)` and evaluates `fullsimp(tan(x) + cot(x))` with `fs_search : 'beam`
- **THEN** the result SHALL be free of `csc`
