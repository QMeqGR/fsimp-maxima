## Purpose

Lets fullsimp simplify the parts of a sum or product that share no variables independently, so that a transform suited to one part does not damage or slow down the others.

## ADDED Requirements

### Requirement: Independent sum terms are simplified separately

When the top-level operator of an expression is a sum, fullsimp SHALL partition its terms into groups such that no two groups share a variable, and SHALL simplify each group separately. Terms with no variables SHALL form one group. Two terms that share a variable, directly or through other terms, SHALL fall in the same group.

#### Scenario: Large polynomial plus a trig identity

- **WHEN** the user evaluates `fullsimp(expand((a + b + c + d + u)^10) + sin(x)^2 + cos(x)^2)`
- **THEN** the result SHALL be `(a + b + c + d + u)^10 + 1`

#### Scenario: Half-angle form survives next to an independent term

- **WHEN** the user evaluates `fullsimp((1 + cos(t))/sin(t) + (exp(y) - exp(-y))/(exp(y) + exp(-y)))`
- **THEN** the result SHALL be `cot(t/2) + tanh(y)`

#### Scenario: Constant terms combine

- **WHEN** the user evaluates `fullsimp(sin(x)^2 + cos(x)^2 + y - 1)`
- **THEN** the result SHALL be `y`

#### Scenario: Terms sharing a variable stay together

- **WHEN** the user evaluates `fullsimp(sin(x)^2 + cos(x)^2 + (x^2 - 1)/(x - 1))`
- **THEN** the result SHALL be `x + 2`

### Requirement: Independent product factors are simplified separately

When the top-level operator of an expression is a product, fullsimp SHALL partition its factors by the same rule as sum terms and SHALL simplify each group separately.

#### Scenario: Product of independent ratios

- **WHEN** the user evaluates `fullsimp(((1 + cos(t))/sin(t)) * ((exp(y) - exp(-y))/(exp(y) + exp(-y))))`
- **THEN** the result SHALL be `cot(t/2)*tanh(y)`

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
