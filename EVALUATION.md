# Evaluation Report (M5)

> **STATUS: NOT YET WRITTEN.** Due with the final system. 3–4 pages. "Adjectives are not
> measurements." The demo-day defense draws heavily on this document, because Claude Code can
> generate plausible code but cannot fake our understanding of our own measurements.

## Latency / timing

**Distributions, not just means**, for event-to-detection or sample-to-storage, measured under
**both idle and loaded CPU**.

**TODO.**

## Resource footprint

CPU utilization and RSS for each process, at steady state and over the full soak. The soak
heartbeats give this series for free — plot it.

**TODO.**

## Domain metric

Pick the one the product lives or dies by: detection accuracy against ground truth we
constructed, sustained sample rate with drop accounting, or query latency over stored history.

**TODO.**

## Fault-injection results

For each failure mode in the design doc's table: what we injected, what the system did, and the
**log excerpt proving it**.

**TODO.**

## Mechanism comparisons

The comparisons our menu choices require — e.g. interrupt vs. polling for B, real-time vs.
default scheduling for C — presented as experiments with method, data, and conclusion.

**TODO.**

## Limitations

Stated plainly, closing the loop on the constraints and substitutions declared in the design doc.

> "An honest limitations section is worth more at the defense than a suspiciously perfect results
> section, and we notice which one we are reading."

**TODO.**
