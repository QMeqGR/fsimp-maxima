## Purpose

Lets fullsimp simplify the parts of a sum or product that share no variables independently, so that a transform suited to one part does not damage or slow down the others.

## ADDED Requirements

### Requirement: Independent sum terms are simplified separately

When the top-level operator of an expression is a sum and its terms that contain variables fall into two or more groups such that no two groups share a variable, fullsimp SHALL simplify each group separately. Two terms that share a variable, directly or through other terms, SHALL fall in the same group. Terms without variables SHALL be simplified together with whichever group, or on their own, gives the cheapest combined result. With fewer than two such groups, fullsimp SHALL simplify the expression as a whole.

#### Scenario: Large polynomial plus a trig identity

- **WHEN** the user evaluates `fullsimp(expand((a + b + c + d + u)^10) + sin(x)^2 + cos(x)^2)`
- **THEN** the result SHALL be `(a + b + c + d + u)^10 + 1`

#### Scenario: Half-angle form survives next to an independent term

- **WHEN** the user evaluates `fullsimp((1 + cos(t))/sin(t) + (exp(y) - exp(-y))/(exp(y) + exp(-y)))`
- **THEN** the result SHALL be `cot(t/2) + tanh(y)`

#### Scenario: Constant terms combine

- **WHEN** the user evaluates `fullsimp(sin(x)^2 + cos(x)^2 + y - 1)`
- **THEN** the result SHALL be `y`

#### Scenario: A constant belongs with one group

- **WHEN** the user evaluates `fullsimp(1 - sin(x)^2 + tan(y)^2)`
- **THEN** the result SHALL be `cos(x)^2 + tan(y)^2`

#### Scenario: Constants divided between groups

- **WHEN** the user evaluates `fullsimp(1 - sin(x)^2 + tan(y)^2 + 1)`
- **THEN** the result SHALL be `cos(x)^2 + sec(y)^2`

#### Scenario: Shifts that cancel

- **WHEN** the user evaluates `fullsimp(cosh(z)^2 - sin(x)^2)`
- **THEN** the result SHALL be `sinh(z)^2 + cos(x)^2`

#### Scenario: A group that simplifies to a constant

- **WHEN** the user evaluates `fullsimp(x^2 + 2*x + sin(y)^2 + cos(y)^2)`
- **THEN** the result SHALL be `(x + 1)^2`

#### Scenario: A large group takes no shift

- **WHEN** the user evaluates `fullsimp(expand((a+b+c+d+u)^10) + sin(x)^2 - 1)`
- **THEN** the result SHALL be `sin(x)^2 + (a+b+c+d+u)^10 - 1` and the polynomial group SHALL be simplified once

#### Scenario: Terms sharing a variable stay together

- **WHEN** the user evaluates `fullsimp(sin(x)^2 + cos(x)^2 + (x^2 - 1)/(x - 1))`
- **THEN** the result SHALL be `x + 2`

### Requirement: Independent product factors are simplified separately

When the top-level operator of an expression is a product, fullsimp SHALL partition its factors by the same rule as sum terms and SHALL simplify each group separately.

#### Scenario: Product of independent ratios

- **WHEN** the user evaluates `fullsimp(((1 + cos(t))/sin(t)) * ((exp(y) - exp(-y))/(exp(y) + exp(-y))))`
- **THEN** the result SHALL be `cot(t/2)*tanh(y)`

#### Scenario: A constant factor belongs with one group

- **WHEN** the user evaluates `fullsimp(2*tan(x)/(1 + tan(x)^2) * (exp(y) - exp(-y))/(exp(y) + exp(-y)))`
- **THEN** the result SHALL be `sin(2*x)*tanh(y)`

### Requirement: Groups that merge are merged

After combining the group results, fullsimp SHALL try the routines that merge terms across groups (`logcontract` and `rootscontract`, when they are in the routine list for the input) on the combination, subject to the equivalence check.

#### Scenario: Logarithms of independent variables

- **WHEN** the user has evaluated `assume(a > 0, b > 0)` and then evaluates `fullsimp(log(a) + log(b) + sin(t)^2 + cos(t)^2)`
- **THEN** the result SHALL be `log(a*b) + 1`

#### Scenario: Roots of independent variables

- **WHEN** the user has evaluated `assume(x > 0, y > 0)` and then evaluates `fullsimp(sqrt(x)*sqrt(y))`
- **THEN** the result SHALL be `sqrt(x*y)`

### Requirement: Splitting applies within groups

fullsimp SHALL apply the splitting rule again to each group whose own top-level operator is a sum or product.

#### Scenario: Nested independent parts

- **WHEN** the user evaluates `fullsimp(z * ((1 + cos(t))/sin(t) + (exp(y) - exp(-y))/(exp(y) + exp(-y))))`
- **THEN** the result SHALL be `z*(cot(t/2) + tanh(y))`

### Requirement: Combined results stay correct

The combined result of a split SHALL pass the same equivalence check as any other fullsimp result.

#### Scenario: Unsafe rewrite inside a group

- **WHEN** the user evaluates `fullsimp(sqrt(x^2 + 2*x + 1) + sin(y)^2 + cos(y)^2)` with no assumptions
- **THEN** the result SHALL agree with the input at negative real `x`

### Requirement: Splitting can be disabled

The option variable `fs_split` SHALL default to `true`. When it is `false`, fullsimp SHALL skip splitting and treat the expression as a whole.

#### Scenario: Unsplit mode

- **WHEN** the user sets `fs_split : false` and runs the existing rtest files
- **THEN** every result SHALL match the result from before this change
