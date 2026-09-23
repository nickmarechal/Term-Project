# Problem memo -- TEAM-NAME-TODO (Nick Marechal, Liam Sagal)

> **STATUS: NOT YET WRITTEN.** The idea is not locked. This file is the Appendix C template with
> our current leading candidate sketched in as a starting point — it is *not* a submission and
> deliberately does not fake a user we have not actually talked to. A memo that names no real
> user gets returned for revision, which costs a week.
>
> Leading candidate as of 2026-09-23: driveway vehicle identification by magnetic signature.
> Feasibility caveat already established: identifying *a specific car among lookalikes* is not
> reliable at this price point, because the magnetic anomaly falls off as 1/r^3 and
> position variance between passes can exceed the car-to-car difference. The defensible version
> distinguishes **two meaningfully different vehicles** (e.g. an SUV vs. a compact) from a fixed
> driveway position. This must be validated by a repeatability test before this memo is written.

## The user

A person or place, named or nameable. Who will this sit next to?

**TODO.** Must be an actual person we have spoken to, not a category.

## The problem

What goes wrong, how often, and what it costs (money, worry, ruined batches, missed warnings).
Observable, not hypothetical.

**TODO.**

## Why a device

The 3 a.m. test: why must something be physically present and always awake? Why doesn't a phone
app already solve this?

**TODO.** Note: for a monitoring-style device the answer is "the interesting thing happens when
nobody is watching." For an instrumented-gear device the answer is different but equally valid —
the sensor has to live inside the equipment, always ready, across many sessions. Use whichever is
honest for the idea we pick; do not force the 3 a.m. framing where it does not fit.

## The sensors

Which two (or more), and how they COOPERATE (fused, correlated, or one pipeline) rather than
merely coexist.

**TODO.** Two physically distinct modalities. Two units of the same part is a risky reading of
the guardrail — avoid it.

## The mechanisms

First guess at two items from the Section 3.2 menu, one sentence of justification each. Allowed
to change by the design doc.

**TODO.** Justify from the user's requirements, not from what looks easiest. The defense tests
this justification.

## The risk

The single thing most likely to sink this project. Name it now; it is cheaper to meet in Week 5
than in Week 14.

**TODO.** Current honest answer regardless of idea: we have not formed the team, ordered
hardware, or picked the idea, and M0/M1 are already due.
