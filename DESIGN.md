# Design Document (M2)

> **STATUS: NOT YET WRITTEN.** Due end of Week 7. This is the required-sections skeleton from
> spec §8 so nothing gets forgotten. 3–5 pages, and per the spec "the most leveraged hours of the
> whole project — every hour of arguing here saves five of rewriting later."
>
> At final submission this file must reflect the design **as it ended, not as it began**, with a
> short changelog of what M2's version got wrong.

## Architecture

A diagram in the spirit of the spec's Figure 1: processes, threads, kernel components, data
flows, and **rates on every arrow**.

**TODO.**

## Mechanism mapping

For each chosen menu item (A–F): which component implements it, and a justification **from the
user's requirements** — not from habit or from what looked easiest. The defense tests this
justification directly.

Example of the required form: *"the vibration analysis is meaningless above 2 ms of sampling
jitter, hence `SCHED_FIFO`."*

| Mechanism | Component | Justification from the user's requirements |
|---|---|---|
| TODO | TODO | TODO |
| TODO | TODO | TODO |

## Failure-mode table

For each component: how it can fail, how the failure is detected, what the system does about it,
and what the log will show. **The 48-hour soak grades this table's honesty.**

| Component | How it fails | How we detect it | What the system does | What the log shows |
|---|---|---|---|---|
| TODO | TODO | TODO | TODO | TODO |

## Storage and data

What is stored, at what rate, in what format, with what retention, and **what happens to it when
the power dies mid-write.**

**TODO.**

## Constraints and substitutions

What the ideal build would use, what we are actually using, and what the gap costs: sensors
downgraded, data synthesized or replayed, claims narrowed.

> "A design document with nothing to report here has usually not met its hardware yet."

**TODO.** Already known: the budget forced a 2-sensor build, and single-unit retail pricing runs
well above the spec's $50–80 estimate.

## Evaluation plan

The measurements we will take (spec §9), each with its method and its target. Numbers committed
to now are twice as credible when hit later, and instructive either way.

**TODO.**

## Ownership map

Which partner owns which subsystems. Ownership means **first authorship and answerability at the
defense**, not exclusivity.

**TODO.** Must match `CLAUDE.md`.

## AI-use plan

What we'll use Claude Code for, what we won't, and how we keep the §3.3 boundary visible in the
repository — e.g. the product source tree contains no network client but the LAN interface, and
a grader can confirm that in one minute.

**TODO.**
