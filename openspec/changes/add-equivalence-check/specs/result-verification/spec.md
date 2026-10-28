## Purpose

Guarantees that fullsimp returns an expression equal in value to its input, judged by numeric evaluation at test points that respect the user's assumptions, so a simplified result is safe to use in later steps.

## ADDED Requirements

### Requirement: Results equal the input

fullsimp SHALL NOT return an expression that differs in value from its input at any test point. Test points SHALL include positive reals, negative reals, and complex values in all four quadrants, with magnitudes both below and above 1, unless assumptions restrict a variable.

#### Scenario: Square root of a perfect square

- **WHEN** the user evaluates `fullsimp(sqrt(x^2 + 2*x + 1))` with no assumptions on `x`
- **THEN** the result SHALL NOT be `x + 1`, and it SHALL agree with the input at negative real `x`

#### Scenario: Products of square roots

- **WHEN** the user evaluates `fullsimp(sqrt(x)*sqrt(x+1) - sqrt(x^2+x))` with no assumptions
- **THEN** the result SHALL NOT be `0`

#### Scenario: Derivative with a branch cut

- **WHEN** the user evaluates `fullsimp(diff(atan(x/sqrt(1-x^2)), x))` with no assumptions
- **THEN** the result SHALL agree with the input at `x = 2.0` and `x = -2.0`

#### Scenario: Safe simplifications still happen

- **WHEN** the user evaluates `fullsimp(sin(x)^2 + cos(x)^2)`, `fullsimp((1 + cos(t))/sin(t))` or `fullsimp(gamma(n+1)/gamma(n))`
- **THEN** the results SHALL be `1`, `cot(t/2)` and `n` respectively

### Requirement: Assumptions widen what is accepted

When the `assume` database or `declare`d features constrain a variable, fullsimp SHALL draw that variable's test points from the constrained set, so a rewrite valid under the assumptions passes the check. When no test point satisfying the assumptions can be found, fullsimp SHALL fall back to unconstrained test points.

#### Scenario: Assumption makes a rewrite valid

- **WHEN** the user has evaluated `assume(x > -1)` and then evaluates `fullsimp(sqrt(x^2 + 2*x + 1))`
- **THEN** the result SHALL be `x + 1`

#### Scenario: Assumption makes a different rewrite valid

- **WHEN** the user has evaluated `assume(x < -1)` and then evaluates `fullsimp(sqrt(x^2 + 2*x + 1))`
- **THEN** the result SHALL NOT be `x + 1`, and it SHALL agree with the input at `x = -3`

#### Scenario: Positive variables

- **WHEN** the user has evaluated `assume(x > 0, y > 0)` and then evaluates `fullsimp(sqrt(x)*sqrt(y))`
- **THEN** the result SHALL be `sqrt(x*y)`

#### Scenario: Unsatisfiable sampling falls back

- **WHEN** the assumptions relate several variables in a way the sampler cannot satisfy within its attempt limit
- **THEN** fullsimp SHALL check candidates against unconstrained test points and SHALL still return a result

### Requirement: Expressions with unknown functions are checked

fullsimp SHALL check candidates whose value depends on functions with no numeric definition (for example `f(sin(x)^2 + cos(x)^2)`). When a candidate cannot be evaluated numerically at enough test points, fullsimp SHALL accept it only if the transform that produced it preserves value everywhere.

#### Scenario: Unknown function wrapping an identity

- **WHEN** the user evaluates `fullsimp(f(sin(x)^2 + cos(x)^2) + g((x^2 - 1)/(x - 1)))`
- **THEN** the result SHALL be `f(1) + g(x + 1)`

#### Scenario: Quoted unknown function

- **WHEN** the user evaluates `fullsimp('f(log(a) + log(b)))` under `assume(a > 0, b > 0)`
- **THEN** the result SHALL be `'f(log(a*b))`

### Requirement: Test values follow Maxima's conventions

fullsimp SHALL compare candidates using the values Maxima itself gives the expressions at the test points. In particular, an odd root of a negative real SHALL be its real root, as in Maxima's numeric evaluation.

#### Scenario: Rewrite valid only on the principal branch

- **WHEN** the user evaluates `fullsimp(%e^(log(x)/3))` with no assumptions
- **THEN** the result SHALL NOT be `x^(1/3)`, which Maxima evaluates as `-2` at `x = -8` where the input is `1 + sqrt(3)*%i`

### Requirement: Checking can be disabled

The option variable `fs_check` SHALL default to `true`. When it is `false`, fullsimp SHALL skip the check and return the same results it returned before this change.

#### Scenario: Unchecked mode reproduces old results

- **WHEN** the user sets `fs_check : false` and evaluates `fullsimp(sqrt(x^2 + 2*x + 1))`
- **THEN** the result SHALL be `x + 1`

### Requirement: Rejections are visible when debugging

When `fsdebug` is 1 or more, fullsimp SHALL print each rejected candidate together with the name of the transform that produced it.

#### Scenario: Debug output names the transform

- **WHEN** the user sets `fsdebug : 1` and evaluates `fullsimp(sqrt(a)*sqrt(b))`
- **THEN** the output SHALL include a rejection line naming `rootscontract`

### Requirement: Results are reproducible

fullsimp SHALL return the same result for the same input, assumptions and options in every call, and SHALL leave the user's random state unchanged.

#### Scenario: Repeated calls agree

- **WHEN** the user evaluates `fullsimp(e)` twice for the same expression `e` with no change to assumptions or options
- **THEN** both calls SHALL return identical results

#### Scenario: User random state preserved

- **WHEN** the user evaluates `set_random_state(make_random_state(42))`, then `fullsimp(sqrt(a)*sqrt(b))`, then `random(1000)`
- **THEN** the value SHALL equal the one `random(1000)` returns directly after `set_random_state(make_random_state(42))` with no `fullsimp` call in between
