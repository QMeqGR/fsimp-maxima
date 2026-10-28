## Context

`fsimpall` maps over lists, sets and matrices, then scans the whole expression for function types (trig, exp, log, gamma, factorial) to build the transform list, and calls `fsimp` on the whole expression. A single trig term in a large polynomial therefore puts the trig transforms in the list for the polynomial too, and every transform sees every term. In the `p^10 + sin(x)^2 + cos(x)^2` case, `trigsimp` turns the trig part into 1, after which `factor` works on the 5-variable degree-10 polynomial `p^10 + 1` on every sweep.

This change assumes `add-equivalence-check` has landed. It works with both the sweep and the beam search.

## Goals / Non-Goals

**Goals:**

- Simplify variable-disjoint parts of a top-level sum or product independently, with per-group transform selection.
- Avoid whole-expression transforms on the combined result.

**Non-Goals:**

- Recursing into function arguments. The proposal records why this is unnecessary today.
- Splitting terms that share variables, for example by function type within one variable. That would risk missing identities like `sin(x)^2 + cos(x)^2` that need several terms together.
- Splitting operators other than `"+"` and `"*"`. Quotients appear as products with negative powers, so they are covered.

## Decisions

### Grouping rule

For each term (or factor), compute `listofvars`. Union-find over the terms joins any two terms that share a variable. This produces the coarsest partition in which no two groups share a variable, so terms that need each other stay together, as the spec's "Terms sharing a variable stay together" scenario requires. fullsimp only splits when at least two groups contain variables.

Terms without variables are set aside. A first version kept them as a group of their own. That broke 7 existing tests, for example `1 - sin(x)^2` → `cos(x)^2` and `2*tan(x)/(1+tan(x)^2)` → `sin(2*x)`, because constants interact with whatever they sit next to.

### Constants and shifts

Let `c` be the sum of the constant terms. Each group either keeps its own result or takes a *shift* `k`, meaning it is simplified again as `g + k`, and the combination adds back `c - (sum of the shifts)`. A group may take `k = c`, and a group containing a trigonometric or hyperbolic function may also take `k = 1` or `k = -1`. Every combination is formed and the cheapest wins, ties to the earliest, where the first combination is the one with no shifts and the next ones give `c` to one group in turn, which is the earlier behaviour. A group whose own result is a constant (such as `sin(y)^2 + cos(y)^2`) joins the constants first, so `x^2 + 2*x + sin(y)^2 + cos(y)^2` gives `(x + 1)^2`. For a product the shifts are factors: a group may take the constant factor, or keep its result.

Shifts of ±1 cover the identities with a constant term among the functions fullsimp handles: `sin^2 + cos^2 = 1`, `1 + tan^2 = sec^2`, `csc^2 - cot^2 = 1`, `cosh^2 - sinh^2 = 1` and the double-angle forms `2*cos^2 - 1 = cos(2*x)` and `1 - 2*sin^2 = cos(2*x)`. They let fullsimp divide constants between groups: `1 - sin(x)^2 + tan(y)^2 + 1` gives `cos(x)^2 + sec(y)^2`, and `2*cos(u)^2 - sin(x)^2`, where Maxima has already cancelled a -1 and a +1, gives `cos(x)^2 + cos(2*u)`. Placing all constants in one group, as the first version did, gave `cos(x)^2 + tan(y)^2 + 1` and `2*cos(u)^2 - sin(x)^2`, worse than the unsplit search.

A group larger than `fs_split_small` (1000 in the units of `fscost`) takes no shift. Each shift repeats the group's simplification, and for the expanded `(a+b+c+d+u)^10` that is the expensive `factor` call splitting exists to avoid: `p + sin(x)^2 - 1` takes 3.0 s when the polynomial may take the -1 and 0.5 s with the limit. (In `p + sin(x)^2 + cos(x)^2 - 1` the trigonometric group simplifies to 1 and joins the constants, which then total 0, so no shift arises.) When the shifts would give more than 256 combinations, only the shift `c` is tried.

*Alternatives:* simplify the whole input as well and keep the better result. That removes every regression against the unsplit search, but costs a second full search, which for a small but expensive input such as `(a+b+c+d+u)^10 + sin(x)^2 + cos(x)^2 - 1` reaches `factor` on the expanded polynomial. Split only large inputs. Rejected because splitting helps small inputs too: over 60 random sums and products of rtest inputs with disjoint variables, splitting gave a cheaper result in 6 and a costlier one in none. Give every group the shifts ±1. Rejected because a polynomial power such as `(a+b+c+d+u)^10 - 1` takes 2.4 s to simplify.

`listofvars` treats subscripted variables like `c[1]` as variables, and leaves `%pi`, `%e` and `%i` out, so constants like `2*%pi` land in the constant group as intended.

*Alternative:* group by function type as well as variables. Rejected for the reason given in Non-Goals.

### Where splitting happens

Add the split at the start of the non-list branch of `fsimpall`, before transform selection. If the top-level operator is `"+"` or `"*"` and the partition has two or more groups, call `fsimpall` on each group (which may split again), then combine the results with the same operator. Otherwise continue as today. Because selection runs per group, a polynomial group gets only the polynomial transforms.

### A merge pass, not a whole-expression pass, after a split

Groups with disjoint variables cannot cancel beyond their constants: if `f(X) + g(Y)` vanishes identically with X and Y disjoint, then f and g are both constant. But they can merge: `log(a)+log(b)` → `log(a*b)` and `sqrt(x)*sqrt(y)` → `sqrt(x*y)` cross groups, and a first version that returned the combination as it stood broke 4 existing tests. So the combination gets one more search restricted to `logcontract` and `rootscontract` (when the input's routine list has them, and with the user's exclusions applied). Both are cheap on large expressions. A full whole-expression search could also refactor across groups, but in the motivating case that is the 13.7 s `factor` call. The proposal records the trade-off.

*Alternative:* run a final pass only when the combined result is small. Rejected for now because it adds a threshold to tune for little gain. Revisit if rtest review turns up cases that lose a cross-group factorisation.

### Verification

Each group's result gets checked against that group's original by the existing equivalence check inside its own fullsimp call. The combined result gets checked once more against the whole original input, which guards against errors in the split and combine step itself. If that final check fails, fullsimp falls back to the unsplit path for that call.

### Option

`fs_split` (default `true`) controls the split. When `false`, `fsimpall` takes exactly the current path.

## Risks / Trade-offs

- [Lost factorisation across groups, for example `(x+1)^2 - y^2`] → Accepted trade-off. Run all rtest files with `fs_split : true` and review any case whose result changes.
- [Shifts repeat group simplifications] → Up to three extra simplifications per trigonometric group. The three original rtest files take about 10% longer, and the 60 random pairs above take 2.6 s instead of 1.6 s.
- [Constants other than ±1 that need dividing, such as a 1/2 for each group] → Not handled. The result stays correct and no costlier than the input.
- [A small expression that is expensive to simplify, such as `(a+b+c+d+u)^10`, still takes the constants] → The size limit only sees the expression as written. Such a group repeats its simplification once with the constants.
- [Behaviour change in existing tests with disjoint factors, such as `(cos(th)+1)/((%i*sin(ph)-cos(ph))*sin(th))`] → The groups should still reach the recorded result. The tasks verify this, and any difference gets reviewed rather than accepted silently.
- [Extra cost of `listofvars` on every call] → One pass over the expression, small next to any transform.
