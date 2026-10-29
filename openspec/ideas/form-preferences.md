# Ideas: fs_prefer form preferences

Candidate entries for an `fs_prefer` option that lets the user say which form they want, not
only the smallest. Each preference needs a violation count read off the expression tree
and routines that can reach the form. Entries marked *proposed* are in the
`add-form-preferences` change. The rest are ideas for later.

## Fractions and radicals

| Preference | Violation | Routines |
|---|---|---|
| `rational_denominator` (*proposed*) | a denominator containing a fractional power | `ratsimp` with `algebraic : true` |
| `single_fraction` (*proposed*) | a sum with a fractional term, or a fraction inside a denominator | `xthru`, `ratsimp`, `combine` |
| `denested_radicals` | a radical inside a radical | `sqrtdenest`, which upstream dropped because it fails on subscripted variables, so it would need a guard |
| `['partfrac, x]` | a term whose denominator has more than one factor in `x` | `partfrac(e, x)` |
| `no_negative_powers` | `x^-n` kept as a power | none needed: Maxima already prints `x^-1` as `1/x`. Probably not worth adding |

## Polynomial shape

| Preference | Violation | Routines |
|---|---|---|
| `factored` (*proposed*) | a sum that `factor` rewrites as a product or power | `factor`, later `gfactor` |
| `expanded` (*proposed*) | a product with a sum factor, or a sum raised to a positive integer power | `expand`, `multthru` |
| `['collect, x]` | a power of `x` appearing in more than one term | `rat(e, x)` then `ratdisrep` |
| `['horner, x]` | a polynomial in `x` not in nested form | `horner(e, x)` |

## Function families

| Preference | Violation | Routines |
|---|---|---|
| `['avoid, f, ...]` (*proposed*) | each occurrence of `f` | whatever removes `f`; for trig, `trigsimp` |
| `sin_cos` (*proposed*) | `tan`, `cot`, `sec` or `csc` | `trigsimp` |
| `exponential` (*proposed*) | a trigonometric or hyperbolic function | `exponentialize` |
| `trigonometric` (*proposed*) | `%e` raised to a power containing `%i` | `demoivre` |
| `no_trig_powers` | `sin(x)^n` with `n > 1`, likewise for the other trig functions | `trigreduce` |
| `single_angle` | a trig function of a multiple angle such as `sin(2*x)` | `trigexpand` |
| `log_combined` | more than one `log` in a sum | `logcontract` |
| `log_expanded` | a `log` of a product, quotient or power | `logexpand : super`, `radcan` |
| `hyperbolic` | a pair of real exponentials that a hyperbolic function would replace | `fstrigsimp`'s `tanh` rules, more rules needed |

## Complex values

| Preference | Violation | Routines |
|---|---|---|
| `rectangular` | not of the form `a + %i*b` with real `a`, `b` | `rectform` |
| `polar` | not of the form `r*%e^(%i*theta)` | `polarform` |
| `real_form` | `%i` anywhere when the input is real | `rectform`, then `realpart` once `%i` cancels |

## Notes for later changes

- Preferences that take a variable (`partfrac`, `collect`, `horner`) make entries lists as
  well as symbols, as `['avoid, ...]` already does.
- `rectform`, `polarform`, `partfrac`, `horner` and `gfactor` are not in the routine list.
  Each preference would add its routines only while active. All five preserve value
  everywhere, so they could join `fs_safe_transforms`.
- Opposed pairs that must be an error together: `log_combined`/`log_expanded`,
  `rectangular`/`polar`, as with `factored`/`expanded` and `exponential`/`trigonometric`.
- `sqrt(3)/3` cannot be returned at all: Maxima's simplifier turns it into `3^(-1/2)`, so
  `rational_denominator` cannot clear single radicals. A display-level option would be
  needed for that.
