# Dark Sky Monitor — Engineering Design Review

**Date:** 2026-09-23 · **Team:** Nick Marechal + TBD · **Status:** pre-M2 analysis
**Scope:** turning "Dark Sky Monitor" into a defensible CS 370 term project.

This document is a critical design review, not a cheerleading document. Sections marked
**CHALLENGE** are places where the original framing needs to change.

---

## 1. System vision

An offline, always-on device that measures the *actual* sky at *one specific site* and answers
"is tonight worth going outside for?" with a category, the evidence behind it, and an honest
confidence score. It never forecasts. It never calls the network. It reports what the sky is
doing right now and what it has been doing for the last half hour.

The product's spine is a restraint: **it is a measurement instrument with an opinion, not a
weather app.** Everything it claims must be traceable to a sensor reading and a rule we wrote.

### CHALLENGE 1: the competition is real and the memo must confront it

Astrospheric and Clear Sky Chart are free, good, and widely used by amateur astronomers. The memo
cannot pretend they don't exist. The honest differentiators:

1. They are **forecasts for a grid cell**, often 2–12 km wide. This is a **measurement of your
   yard**, where a single neighbor's new floodlight or a local inversion layer changes everything.
2. They require **internet**. The highest-value stargazing happens at a dark site 40 minutes out
   of town **with no cell signal** — exactly where every existing answer stops working.
3. They don't know your site's light pollution, and they can't tell you that the sky brightened
   1.2 mag over the last three weeks because someone installed a security light.
4. "Should I drive out there / should I unpack the scope" is a **right-now** question, and no
   forecast answers it.

This is defensible but it is the weakest part of the pitch. It gets much stronger after an actual
conversation with a real user (see §2). Do that before writing the memo.

---

## 2. User and problem statement

### The user (action required this week)

Do **not** write "amateur astronomers." Get a named person. Two concrete leads:

- **Northern Colorado Astronomical Society** (Fort Collins). A local club has members who drive to
  dark sites, already own Sky Quality Meters, and will talk at length for free. This single contact
  gives you: a named user, domain expertise, a **reference instrument to calibrate against**
  (see §14), and a trivial path to "The Reach" (spec §14).
- **CSU Physics / astronomy faculty or the campus observatory.** Same benefits, walking distance,
  and they may lend an SQM.

Either contact upgrades this project more than any code you will write in week 6. Make it this
week.

### The problem

The observing decision is costly and currently made badly:
- Driving 40–60 minutes to a dark site and arriving under cloud wastes an evening.
- Unpacking and cooling a telescope takes 30–45 min; doing it on a night that closes in is wasted
  setup and teardown.
- The inverse error is worse and invisible: **staying home on a night that was actually excellent.**
  Nobody ever learns about those, which is precisely why a logging instrument beats a guess.

### Why a device (the 3 a.m. test)

The interesting transitions happen unattended and at hours nobody is watching: the 2 a.m. clearing,
the high cirrus that rolls in at 11 p.m., the three-week creep in background brightness. A phone
is not in the yard, is not pointed at the zenith, and is not awake.

---

## 3. Recommended sensors

### CHALLENGE 2: two sensors is the wrong target — you need three

The spec requires **at least** two. Two is a floor, not a goal, and the physics here punishes two.

| Role | Part | ~Cost | Interface | Why it's required |
|---|---|---|---|---|
| Sky brightness | **TSL2591** | $12 | I2C | High dynamic range (600M:1), detects down to ~188 µLux. Night sky is ~0.0002–0.003 lux, so this is at the edge but reaches it. Proven in DIY SQM builds. |
| Cloud cover | **MLX90614** (3V version) | $18 | I2C (SMBus) | Non-contact IR thermometer. Clear zenith radiates 20–40 °C *below* ambient; cloud radiates near ambient. ΔT is the cloud signal. |
| Ambient + humidity + pressure | **BME280** | $10 | I2C | **Not optional** — see below. |
| Time | **DS3231 RTC** | $8 | I2C | **Not optional** — see CHALLENGE 3. |

**Why the BME280 is mandatory, not a nicety:** ΔT is confounded by **humidity**. Water vapor
radiates in the infrared window, so a *humid but perfectly clear* sky reads much warmer than a
*dry clear* sky. Without a humidity measurement, "warm sky = cloud" is simply wrong on humid
nights, and the cloud claim collapses under one question at the defense. Commercial cloud sensors
apply exactly this correction. The BME280 also gives you the ambient reference for ΔT (better than
the MLX90614's own die temperature, which is biased by self-heating and enclosure warmth) and a
pressure trend for free.

### Sensors explicitly rejected, and why

- **BH1750 / generic lux breakouts** — resolution floor around 1 lux. The night sky is ~0.001 lux.
  This is off by three orders of magnitude. Not viable, do not be tempted by the $3 price.
- **Photoresistor + ADC** — nowhere near the sensitivity required. Reject.
- **TSL237** (light-to-frequency, what the commercial Unihedron SQM uses) — genuinely attractive
  because its pulse output makes brightness measurement an *interrupt-timestamping* problem
  (mechanism B). But at bright levels its output climbs toward MHz, which will swamp Pi GPIO
  interrupt handling, forcing an adaptive gate-counting design. **Viable, higher risk.** Treat as
  an alternative only if you specifically want mechanism B (see §10).
- **Camera / Sky quality by imaging** — a camera changes the privacy and cost story, needs far more
  compute, and the spec's own seeds repeatedly reward the camera-less answer. Reject.

### CHALLENGE 3: without an RTC this project cannot work

No network means **no NTP**. A Raspberry Pi has no battery-backed clock, so on every power cycle it
comes up with a garbage or last-known time. That breaks:
- knowing whether it is even astronomically dark,
- the sun/moon ephemeris that gives this project most of its sophistication (§6),
- every timestamp in the storage layer, and therefore every retrospective query.

A **DS3231 (~$8, ±2 ppm, battery-backed)** is a hard requirement. This is the single cheapest
insurance policy in the BOM. Also: use `CLOCK_MONOTONIC` for all interval math and
`CLOCK_REALTIME` only for wall-clock labeling, and treat a backwards jump in realtime as a
loggable fault (§12).

---

## 4. Bill of materials

Overestimated single-unit retail, so real cost should land under these.

| Item | Cost | Notes |
|---|---|---|
| Raspberry Pi 3B+ (used) *or* Zero 2 W | $35 / $18 | A used 3B+ off Marketplace/eBay is the value play. Zero 2 W is fine for the deployed device but slow to compile on — develop on a laptop or cross-compile. |
| microSD, **high-endurance** 32 GB | $12 | Not the cheapest card. This device writes continuously for weeks; endurance cards exist for dashcams for exactly this reason. |
| Power supply | $10 | |
| TSL2591 | $12 | |
| MLX90614 (**3V variant**) | $18 | Get 3V, or you need level shifting on I2C. |
| BME280 | $10 | |
| DS3231 RTC + coin cell | $8 | |
| Breadboard, jumpers, header | $12 | |
| Enclosure + LDPE film + hardware | $14 | §Enclosure below |
| **Subtotal (used Pi, no dew heater)** | **~$121** | ≈ $60/person |
| *Optional:* dew heater (resistor + MOSFET + wire) | $8 | Strongly recommended, see §12 |
| *Optional:* new Pi 4 instead of used 3B+ | +$30 | |

### CHALLENGE 4: $100 is tight, and the honest answer is to say so

A realistic build is **$121–165**, not $100. This is not a failure — spec §5 is explicitly about
this, and §8 requires a "constraints and substitutions" section that documents exactly this kind
of gap. Three legitimate ways to close it:
1. Used Pi 3B+ (~$35) instead of a new Pi 4 (~$65).
2. Skip the case/fan; the spec itself jokes that the enclosure will be a food container.
3. **Ask the CS department whether hardware is loanable or reimbursable before paying retail.**
   Also ask the astronomy contact from §2 — clubs often have spare parts bins.

---

## 5. System architecture

```
                 ZENITH (open sky)
    ┌──────────────┴──────────────┐
    │ TSL2591          MLX90614   │   BME280 (shaded, vented)
    │ (acrylic window) (LDPE film │   DS3231 (inside, warm)
    │                  + hood)    │
    └──────────────┬──────────────┘
                   │ I2C bus (3.3 V, ~50 kHz — see §Wiring)
═══════════════════╪════════════════════════════ kernel / user boundary
        Linux i2c-dev  (serializes bus transactions)
                   │
   ┌───────────────┼────────────────┬──────────────────┐
   │               │                │                  │
┌──▼────────┐ ┌────▼──────┐ ┌───────▼─────┐            │
│ skyd      │ │ cloudd    │ │ envd        │  one process per sensor
│ TSL2591   │ │ MLX90614  │ │ BME280+RTC  │  (mechanism E: isolation)
│ ~0.2 Hz   │ │ ~1 Hz     │ │ ~0.1 Hz     │
└──┬────────┘ └────┬──────┘ └───────┬─────┘            │
   │ SHM ring + sem or UDS          │                  │
   └───────────────┼────────────────┘                  │
                   │                                    │
            ┌──────▼──────────────────────┐             │
            │ fusiond (the hub)           │             │
            │  · feature extraction       │             │
            │  · sun/moon ephemeris (ours)│             │
            │  · veto-gate classifier     │             │
            │  · state machine + hysteresis│            │
            └──────┬──────────────────┬───┘             │
                   │                  │                 │
          ┌────────▼───────┐  ┌───────▼────────┐        │
          │ stored (D)     │  │ LAN/CLI iface  │        │
          │ append-only    │  │ dsq query ...  │        │
          │ CRC'd records  │  └────────────────┘        │
          │ segments+rollup│                            │
          └────────────────┘                            │
                                                        │
            ┌───────────────────────────────────────────▼──┐
            │ dskyd — supervisor (E)                       │
            │ fork/exec, exponential backoff, DEAD state,  │
            │ hourly heartbeat, restart-storm suppression  │
            └──────────────────────────────────────────────┘
```

### CHALLENGE 5: all three sensors share one I2C bus — say so, don't hide it

Three separate processes hammering one I2C bus is a genuine design problem, not a free lunch. The
Linux I2C subsystem serializes transactions, so you will not get corruption — but you *will* get
jitter in sample timing and head-of-line blocking when one sensor is slow. This is an honest
tradeoff to state in the design doc and **measure** in the evaluation:

- Report per-sensor sample-interval jitter with 1 vs. 3 processes contending.
- If jitter proves unacceptable, the fallback is a single `i2cd` broker process owning the bus,
  with the three sensor daemons as clients. **Decide this in the design doc, not in week 11.**

Do not pretend process isolation is costless. Measuring the cost is worth more than hiding it.

---

## 6. Sensor-fusion design

### The core insight — this is your best paragraph, put it in the memo

**A brightness sensor alone is not merely imprecise; it is wrong in a specific, demonstrable,
reproducible way.**

| Sky brightness | ΔT (ambient − sky) | Reality | A light meter alone says |
|---|---|---|---|
| Dark | Large (clear) | **Excellent night** | "dark, great" ✅ |
| Bright | Large (clear) | Clear but moonlit — planets/doubles yes, deep-sky no | "bright, bad" ❌ *wrong* |
| Bright | Small (overcast) | Overcast over a city; cloud reflecting streetlight | "bright, bad" ✅ |
| **Dark** | **Small (overcast)** | **Overcast at a dark site — useless** | **"dark, great"** ❌ **catastrophically wrong** |

That last row is the whole justification for the second sensor. At a rural dark site an overcast
sky is genuinely *darker* than a clear one, because there is no light to reflect. A single-sensor
meter confidently recommends the worst possible night. The IR channel catches it, and no
if-statement on brightness can.

### Features (rolling windows, all locally computed)

| Feature | Window | What it discriminates |
|---|---|---|
| `sky_mag` — brightness, calibrated to relative mag/arcsec² | 1 min | darkness level |
| `sky_sigma` — rolling std-dev of brightness | 10–30 min | **passing cloud causes variability, not just a level shift** |
| `dT = T_amb − T_sky` | 1 min | cloud cover |
| `dT_corr = dT + f(RH, T_amb)` — humidity-corrected | 1 min | cloud cover, honestly |
| `dT_sigma` | 10–30 min | broken/scattered cloud oscillates |
| `dewpoint_margin = T_amb − T_dew` | 5 min | dew risk on optics **and on our own sensor window** |
| `dP/dt` — pressure trend | 3 h | front approaching |
| `sun_alt`, `moon_alt`, `moon_phase` | computed | see below |

`f(RH, T)` must be **fitted from your own logged data**, not guessed. Collect clear humid nights
and clear dry nights and regress. If you cannot separate them, say so and narrow the claim.

### The sophistication multiplier: local sun/moon ephemeris

Implement solar and lunar position from the RTC plus a hardcoded latitude/longitude, in C, from
standard astronomical algorithms. This is **pure local computation — no API, no network** — and it
transforms the product:

1. **Gating.** Astronomical darkness is `sun_alt < −18°`. Without this the device confidently
   grades a bright evening twilight as "POOR conditions" when the correct answer is "not dark yet."
2. **Attribution.** Knowing moon altitude and phase lets you predict the *expected* moonlight
   contribution and therefore attribute measured brightness to a cause: moon, light pollution, or
   cloud-scattered glow. "Bright because the moon is up and 87% illuminated" is a genuine
   explanation; "bright" is not.
3. **Defensibility.** It is math you wrote and can derive at the whiteboard, which is exactly what
   the individual defense rewards.

This is the single highest-leverage component in the design. It is also self-contained and
testable offline against published almanac values — a perfect unit-test target.

### Classifier: veto gates, not a weighted sum

**CHALLENGE 6: do not use a weighted score.** A weighted sum is hard to explain, hard to defend
line-by-line, and produces absurd outputs (enough darkness "outvoting" solid overcast). Use a
**veto hierarchy**, which is more explainable and trivially traceable:

```
1. NOT_DARK      if sun_alt > -18°                         → state: DAYLIGHT / TWILIGHT
2. UNKNOWN       if any required sensor DEAD or window has
                 < X% expected samples or baseline immature
3. POOR  (veto)  if dT_corr < cloud_overcast_threshold      → "overcast"
4. POOR  (veto)  if dewpoint_margin < 1 °C AND dT collapsed → "likely dew on window, not sky"
5. MARGINAL      if dT_sigma high                           → "broken cloud"
   MARGINAL      if sky_sigma high                          → "unstable brightness"
   MARGINAL      if moon_alt > 0 AND phase > 0.5            → "moonlight limits deep-sky"
6. GOOD          if none of the above fired AND sky_mag
                 within the top band of the site baseline
```

Every rule that fires contributes its reason string. **Explainability is not a feature bolted on;
it is a side effect of the architecture.** That is the right way to build it and a good thing to
say out loud at the defense.

---

## 7. State machine

States: `BOOT` → `DAYLIGHT` / `TWILIGHT` / `UNKNOWN` / `POOR` / `MARGINAL` / `GOOD`, plus
`DEGRADED` (running with a dead sensor) and `FAULT`.

Transition discipline:
- **Minimum dwell time** per state (e.g. 10 min) — prevents flapping.
- **Asymmetric hysteresis.** Promoting toward GOOD requires N consecutive qualifying windows;
  demoting requires fewer. Justify the asymmetry explicitly: a false GOOD sends someone outside
  or on a 40-minute drive for nothing, which is the error that gets the device unplugged. Spec
  Seed 1 makes the same point — *"a monitor that cries wolf twice gets unplugged."*
- **Every transition is logged** with the rule that caused it and the feature values at the time.
  The transition log is the artifact you will read from at the demo when asked "why did it say
  that at 1 a.m.?"

---

## 8. Data model

Fixed-width binary records — fixed width matters because it makes torn-write detection and
recovery-by-truncation simple.

```c
/* 48 bytes, explicitly padded, little-endian, version-tagged */
struct dsm_record {
    uint64_t t_mono_ns;   /* CLOCK_MONOTONIC — interval math          */
    uint64_t t_real_ns;   /* CLOCK_REALTIME  — wall clock labelling   */
    uint16_t schema_ver;
    uint16_t source_id;   /* which daemon produced this               */
    uint16_t kind;        /* SAMPLE | FEATURE | STATE | HEARTBEAT | FAULT */
    uint16_t flags;       /* VALID | STALE | SYNTHETIC | CALIBRATING  */
    int32_t  v[4];        /* fixed-point payload, scale per kind      */
    uint32_t seq;         /* per-source sequence — proves no gaps     */
    uint32_t crc32;       /* over all preceding bytes                 */
};
```

Design notes worth defending:
- **`seq` per source** gives you drop accounting for free: a gap in sequence numbers is provable
  data loss, and "zero gaps across 48 hours" is a measurable claim.
- **`flags` carries `SYNTHETIC`.** Spec §5 makes this absolute: replayed or synthesized data must
  be labeled *everywhere it appears*. Putting it in the record format means you cannot forget.
- **Fixed-point, not float.** Deterministic across platforms and trivially CRC-able.

---

## 9. Storage architecture (mechanism D)

```
data/
  seg-000001.dsm      append-only segment, rotated at 8 MB or at local noon
  seg-000002.dsm
  index/2026-10-14.rollup    per-night summary written after the night closes
  MANIFEST                   segment list + validated-length watermark
```

- **Superblock** per segment: magic, schema version, creation time, site lat/long.
- **Write batching:** accumulate records in an in-memory buffer, `write()` in one syscall.
- **fsync policy:** `fsync()` every N seconds and on segment rotation. **N is a tunable you will
  experiment on** (§13) — the tradeoff is data-loss window vs. write amplification vs. SD card
  wear. Measuring that curve is real systems work.
- **Recovery:** on startup, read `MANIFEST` watermark, scan forward validating CRCs, truncate at
  the first invalid record, log the truncation. A torn final record is expected and normal, not an
  error condition.
- **Rollups:** after each night, compute per-night summaries (min/median sky_mag, minutes in each
  state, cloud fraction) into a compact index so queries over weeks do not rescan raw segments.
- **Retention:** raw segments age out at a documented horizon; rollups are kept indefinitely.
  Monitor free space and **refuse to write while logging loudly** rather than filling the card.

The crash-consistency story is the deliverable here, and it is testable by literally pulling the
plug — repeatedly, and counting (§13).

---

## 10. Process architecture & mechanism selection

### CHALLENGE 7: pick D + E. Do not pick C or F.

| Mechanism | Fit | Verdict |
|---|---|---|
| **D** custom crash-consistent storage | Weeks of nightly baseline must survive power cuts; SD wear is real; retrospective queries are a core feature | **Take it.** Strongly justified by the problem. |
| **E** multiprocess + IPC + supervisor | A silently dead sky monitor is this product's nightmare scenario; sensor isolation is a requirement, not garnish | **Take it.** Strongly justified. |
| **A** kernel char driver | Could expose the TSL2591 or MLX90614 via `/dev`. Best resume line in the menu. | **Stretch.** Start it only if M3 lands early. Keep the userspace path as fallback. |
| **B** interrupt vs. polling | Only honest if you switch to the TSL237 pulse-output sensor. The TSL2591's INT pin on a slowly-varying signal is a weak comparison. | **Only with TSL237.** Don't fake it. |
| **C** real-time scheduling | There is no hard deadline in "is the sky dark." Sky brightness changes over minutes. | **Reject.** Forcing `SCHED_FIFO` here is contrived and the defense will find it. |
| **F** no-drop high-rate pipeline | Sampling at 0.1–1 Hz. A "no-drop high-rate pipeline" for a 1 Hz signal is transparently padded. | **Reject.** |

Being able to say *"we considered C and F and rejected them because our sample rates don't justify
them"* is a **stronger** answer at the defense than bolting them on. Judgment is what is being
graded.

### Processes

| Process | Job | Why separate |
|---|---|---|
| `dskyd` | supervisor: fork/exec children, backoff, heartbeat, DEAD marking | must outlive every failure |
| `skyd` | TSL2591 sampling, ~0.2 Hz | an I2C hang here must not kill cloud sensing |
| `cloudd` | MLX90614 sampling, ~1 Hz | the most finicky sensor — isolate it |
| `envd` | BME280 + RTC, ~0.1 Hz | slow, low risk |
| `fusiond` | features, ephemeris, classifier, state machine | the brain; restartable from stored state |
| `stored` | storage layer owner | single writer — avoids multi-writer corruption entirely |
| `dsq` | query CLI (short-lived) | read-only |

**Single-writer storage is a deliberate choice:** exactly one process may write segments, which
eliminates a whole class of concurrency bugs by construction rather than by locking.

---

## 11. IPC design

- **Sensor → hub: POSIX shared-memory ring buffer + semaphore**, one ring per sensor daemon,
  single-producer/single-consumer. Cheap, bounded, and lets the hub detect overrun explicitly
  rather than silently. Per-record `seq` makes any drop provable.
- **Hub → storage: Unix domain socket** (`SOCK_SEQPACKET`). Message-oriented, backpressure comes
  free from the socket buffer, and the fd dying is an immediate, unambiguous signal that the
  storage process is gone.
- **CLI → hub: Unix domain socket** with a small request/response protocol for live state.
- **Supervisor → children: signals + a pipe-based liveness channel.** Each child holds the write
  end of a pipe; the supervisor sees EOF the instant the child dies, without polling. This is a
  clean, classic pattern and a good thing to be able to explain.

Deliberately using **two different IPC mechanisms** is defensible: the sensor path is high-frequency
and fixed-size (shared memory wins), the storage path needs framing and backpressure (sockets win).
Be ready to justify that at the defense rather than saying "we used both to tick a box."

---

## 12. Failure-mode analysis

| # | Failure | Detection | Response | Log evidence |
|---|---|---|---|---|
| 1 | Sensor unplugged | I2C read returns `ENXIO`/`EREMOTEIO` N times consecutively | Mark sensor `DEAD`; fusion drops to `UNKNOWN` or `DEGRADED` with reduced confidence; **never silently substitute a stale value** | `FAULT` record + state transition |
| 2 | **I2C bus lockup** (a real Pi failure mode) | Read timeout; all sensors stop simultaneously | Attempt bus recovery; if it fails, escalate — this is the one fault that can take all sensors at once | `FAULT` with bus state |
| 3 | Sensor stuck (same value forever) | Staleness detector: variance below floor over a long window while others vary | Mark `SUSPECT`, exclude from fusion, keep logging raw | `FAULT` + raw retained |
| 4 | **Dew/frost on the IR window** | `dewpoint_margin < 1 °C` **AND** `dT` collapsed sharply **AND** brightness still dark/stable | Report "likely condensation, not cloud"; enable heater if fitted | dedicated fault class |
| 5 | Process crash | Supervisor sees pipe EOF / `SIGCHLD` | Restart with exponential backoff | restart record with attempt count |
| 6 | **Restart storm** (sensor physically gone, so restarts keep failing) | Backoff exceeds cap / N failures in T | Stop restarting, hold `DEAD`, keep the rest of the system running | explicit "giving up" line |
| 7 | Power cut mid-write | CRC mismatch on the last record at startup | Truncate to last valid record, log it, continue | recovery line with bytes discarded |
| 8 | SD card full | Free-space monitor below threshold | Stop writing raw, keep rollups, log loudly; do not corrupt | pre-emptive warning trail |
| 9 | **RTC battery dead / clock jump** | `CLOCK_REALTIME` moves backwards or disagrees wildly with `CLOCK_MONOTONIC` delta | Keep using monotonic for intervals; flag all affected records; refuse ephemeris-dependent verdicts → `UNKNOWN` | clock-fault record |
| 10 | Slow memory leak | Hourly heartbeat RSS series | Visible as a trend; the soak is the test | heartbeat series (plot it) |

**Failure 4 deserves special attention.** It is the one that is easy to get wrong and it is a
genuinely clever use of fusion: condensation on your own sensor *mimics overcast*, and the only way
to tell them apart is to notice that the other channels disagree. If you build this, it is a strong
thing to be asked about.

---

## 13. Evaluation plan

| # | Measurement | Method | Why it matters |
|---|---|---|---|
| 1 | Sample-to-storage latency | Timestamp at read, at hub, at fsync. **Distributions, not means**, under idle and loaded CPU (`stress-ng`) | Required by spec §9 |
| 2 | Classification latency | Feature-window close → state decision emitted | Required |
| 3 | CPU% and RSS per process | Heartbeat series over the full 48 h; plot | Required; catches leaks |
| 4 | **Domain metric: classification accuracy** | Confusion matrix vs. human labels (§14) | The number the project lives or dies by |
| 5 | **fsync policy experiment (D)** | Sweep fsync interval; measure bytes written, syscall cost, and worst-case data-loss window | Real systems tradeoff curve |
| 6 | **Crash recovery rate (D)** | Pull power **≥ 20 times** mid-write; count clean recoveries; measure records lost | Turns crash-consistency from a claim into a number |
| 7 | **Supervisor recovery (E)** | `kill -9` each child ≥ 20 times; measure detection latency, restart latency, data gap | Turns "survives any child dying" into a number |
| 8 | I2C contention cost | Sample-interval jitter with 1 vs. 3 sensor processes | Honest accounting for the E architecture (CHALLENGE 5) |
| 9 | Ephemeris correctness | Unit-test sun/moon altitude against published almanac values across a year of dates | Cheap, rigorous, fully offline |

---

## 14. Accuracy validation methodology

This is the hardest part of the project and the place where honesty is graded hardest.

### CHALLENGE 8: "87% confidence" is not defensible as written

A percentage produced by a heuristic is **not a probability**, and presenting it as one is exactly
the overclaim spec §5 punishes. Two fixes, do both:

1. **Define it explicitly** as a confidence *score* with a published formula, not a probability:
   ```
   confidence = w1·data_completeness      (fraction of expected samples in window)
              + w2·sensor_health          (all required sensors live?)
              + w3·boundary_distance      (normalised distance from the nearest threshold)
              + w4·baseline_maturity      (nights of site baseline accumulated)
   ```
   Every term is measurable and explainable. Publish the weights and the reasoning.
2. **Calibrate it and report the result honestly.** Bin predictions by confidence and check whether
   the high-confidence bins really are more often correct — a **reliability diagram**. If it turns
   out miscalibrated, *report that*. A reliability diagram that shows "our 90% bin was right 70% of
   the time, here's why" is worth more at the defense than a suspiciously perfect table.

### Ground truth

**Human observation log, started immediately.** Per observation record: timestamp, cloud cover in
okta (0–8, standard meteorological practice), naked-eye limiting magnitude via star counts in Ursa
Minor (a documented, repeatable technique), moon visible y/n, subjective verdict, free-text note.

Three multipliers:
- **Observe 2–3 times per night, not once.** Night-level labels give you ~30 samples across an
  8-week window; observation-level labels give 60–100. With three classes, that difference decides
  whether the confusion matrix means anything.
- **Cloudy nights are data.** Do not only log the good nights — that is how you end up with a
  classifier validated exclusively on the easy case.
- **Borrow a reference SQM** from the astronomy contact in §2. One night of side-by-side readings
  converts your brightness channel from *relative* to *calibrated*, which is the difference between
  "0.4 mag darker than our baseline" and "20.8 mag/arcsec²." Huge credibility upgrade for one
  evening's work.

### CHALLENGE 9: decompose the claim — validate the parts you can validate well

Do not try to prove one grand claim. Split it:

| Claim | Samples available | Validation strength |
|---|---|---|
| **Cloud detection** (clear / broken / overcast from ΔT_corr) | Many — loggable any time you are awake, day or night | **Strong.** Report a real confusion matrix. |
| **Relative sky brightness tracking** | Continuous | **Strong**, and calibratable against a borrowed SQM |
| **Twilight/moon gating via ephemeris** | Unit-testable against almanac | **Very strong** — essentially exact |
| **Overall GOOD/MARGINAL/POOR recommendation** | Few dozen labelled observations | **Modest.** Report exact counts, not percentages to three decimals on n=4. |

Then narrow the headline claim to something true, in the spirit of spec §5:

> *"Classifies cloud state into three classes with these measured error rates, tracks relative sky
> brightness against a site baseline, gates on locally computed solar/lunar geometry, and combines
> them into a GOOD/MARGINAL/POOR recommendation that agreed with N human observations M% of the
> time."*

That survives cross-examination. *"Tells you if it's a good night to stargaze"* does not.

### Provoked conditions (labelled `SYNTHETIC`, always)

You cannot order clouds. You can provoke:
- **Simulated overcast:** hold a room-temperature card/bag over the IR aperture → ΔT collapses.
- **Simulated light pollution / moonlight:** a dimmable LED at a fixed distance.
- **Simulated ideal dark:** the whole head inside a closed box.
- **Simulated dew:** breathe on / mist the window and watch failure mode 4 fire.
- **Two-site comparison:** one night in town, one night outside Fort Collins. A genuine two-point
  brightness calibration and a real-world validation of the darkness scale.
- **Replay harness:** record raw streams on real nights, replay through the *real* pipeline at
  accelerated speed. This is how you iterate on the classifier without waiting for weather, and
  the spec explicitly endorses it.

---

## 15. 48-hour soak-test design

Runs the **final build**, outdoors or at a window, on **live sensors**, spanning two full
day/night cycles — which is valuable in itself because it forces the state machine through four
twilight transitions.

Hourly heartbeat record must carry: uptime, per-process liveness + RSS + CPU, per-sensor sample
counts and sequence high-water marks, current state and confidence, sensor health flags, free disk,
and segment count.

Planned fault injections (spec requires ≥ 1; do more, and schedule them):

| ~Hour | Injection | Expected behaviour |
|---|---|---|
| 8 | `kill -9 cloudd` | Supervisor detects via pipe EOF, restarts, gap < 5 s, logged |
| 14 | **Physically unplug the MLX90614 for 10 min** | `DEAD` after N failed reads, state → `DEGRADED`/`UNKNOWN`, restart storm suppressed, clean recovery on replug |
| 20 | `kill -9 fusiond` | Restarts and rebuilds feature windows from stored data |
| 26 | `kill -9 stored` | Hub detects socket close, buffers, no data loss beyond buffer depth |
| 32 | Fill disk to threshold (quota/ballast file) | Refuses raw writes, keeps rollups, logs loudly, no corruption |
| 48 | Orderly shutdown | Clean segment close, final `fsync`, orderly-exit record |

**Power-cut tests are run separately, not during the graded soak** — pulling power ends the soak.
Do those as their own experiment (§13 item 6).

Run the soak **twice**, with margin. Spec §16: *"You will want to run it twice."*

---

## 16. Development timeline

Mapped to the spec's milestones. Estimated dates assume Week 1 = Aug 24 — verify on Canvas.

| Week | Milestone | Work |
|---|---|---|
| **5** (now) | **M1** | **Contact the astronomy club/faculty. Order hardware today.** Write the memo. Copy transcripts. |
| **6** | | Sensors electrically alive. Raw logging to a flat file. **Start the observation logbook — every clear night from here is data you cannot get back.** |
| **7** | **M2** | Design document. Argue the architecture in ink. Decide: 3 processes vs. i2c broker; fsync policy; record format frozen. |
| **8** | | Storage layer: segments, CRC, recovery. First power-cut tests. Start overnight runs *now*, at small scale. |
| **9** | | Supervisor + IPC. `kill -9` survival. Ephemeris module + unit tests against almanac. |
| **10** | **M3** | **Checkpoint:** all three sensors through the real pipeline into real storage; D and E working. |
| **11** | | Feature extraction, humidity correction fitted from real data, replay harness. |
| **12** | | Veto classifier + state machine + hysteresis. Query CLI. Reference-SQM calibration night. |
| **13** | | Experiments: fsync sweep, recovery rate, kill-9 stats, I2C contention, confusion matrix, reliability diagram. |
| **14** | **M4** | Feature freeze. **48-h soak #1.** Fix what it finds. Soak #2. |
| **15** | **M5** | Evaluation report, DESIGN.md changelog, PROMPTLOG, REFLECTION, final transcripts. |
| **15–16** | **M6** | Demo day. |

### The single most important scheduling point

**The observation logbook starts in week 6, not week 11.** Clear nights in Fort Collins during
October and November are finite and unrecoverable. Every night you log while the code is still ugly
is a night you do not have to beg the weather for in week 13. The code can be rebuilt; the nights
cannot.

---

## 17. MVP definition (must be true at M3, week 10)

1. Three sensors sampling at their own rates through three supervised processes.
2. Records reaching the custom storage layer with CRCs and sequence numbers.
3. Supervisor survives `kill -9` of any child and logs it.
4. Storage recovers cleanly from a mid-write power cut.
5. A CLI that prints current state and dumps a time range.
6. Sun/moon ephemeris correct against almanac values.
7. A state machine emitting GOOD/MARGINAL/POOR/UNKNOWN with reason strings — even with rough
   thresholds. Tuning comes later; the *pipeline* must be real.

Anything beyond this is stretch. Ship the MVP early and spend weeks 11–13 on the analysis and the
measurements, which is where the points actually are.

## 18. Stretch goals (in priority order)

1. **Dew heater control loop** — resistor + MOSFET on the IR aperture, driven by `dewpoint_margin`.
   Turns a failure mode into a feature and adds a measurable control loop.
2. **Character driver (mechanism A)** — expose one sensor via `/dev`. Best resume line available.
   Keep the userspace path as a fallback and only start this if M3 is early.
3. **Condensation self-diagnosis** (failure mode 4) — clever, and a great defense question.
4. **Reference-SQM calibration** → absolute mag/arcsec² instead of relative.
5. **LAN dashboard** — last, and deliberately last. Spec §4.6 is blunt that interface ambition is
   where teams bleed time; a crisp CLI is more defensible and far more extensible at the
   live-modification station on demo day.

## 19. Biggest implementation risks

| Risk | Severity | Mitigation |
|---|---|---|
| **MLX90614 cannot see through plastic.** Acrylic and most plastics are opaque in the 8–14 µm band it uses. A sealed clear window **blinds the cloud sensor.** | **Project-threatening** | Open aperture under a rain hood, tilted ~15° for drainage; **or** a thin LDPE film window (polyethylene is reasonably LWIR-transparent — a bag or cling film, calibrated in place, replaced periodically). Test this in **week 6**, not week 12. |
| **MLX90614 I2C is finicky on the Pi** (SMBus / repeated-start behaviour) | High | Budget real time. Common fixes: lower the bus baudrate (`dtparam=i2c_arm_baudrate=50000`), or use the `i2c-gpio` bitbang overlay on separate pins. Get it reading in week 6 or reconsider the sensor. |
| **Weather refuses to cooperate.** Too few clear nights for a meaningful matrix | High | Log from week 6. Observation-level not night-level labels. Provoked conditions + replay harness. Narrow the claim (§14). |
| **TSL2591 at the bottom of its range.** Night sky is near its noise floor | Medium | Long integration times, dark-frame/offset characterisation in a sealed box, report *relative* brightness unless the SQM calibration happens. |
| **Humidity correction may not separate cleanly** | Medium | If regression on your own data fails to separate humid-clear from overcast, say so and narrow the cloud claim to dry conditions. That is a legitimate result. |
| Dew/frost on sensors in a Colorado November | Medium | Heater (stretch 1); failure mode 4 detection; hood. |
| SD card wear from continuous writes | Medium | High-endurance card, write batching, fsync sweep, retention policy. |
| **Scope creep into a pretty dashboard** | Medium | CLI first. Dashboard is stretch 5 for a reason. |
| Two-person coordination on a shared `CLAUDE.md` | Low | `git pull --rebase` habit; clear ownership map in the design doc. |

## 20. Interview-worthy aspects

Phrased as you would actually say them:

1. *"I wrote a crash-consistent append-only storage engine with CRC-validated fixed-width records,
   swept the fsync policy to measure the data-loss-window versus write-amplification tradeoff, and
   proved recovery by pulling the power 20+ times mid-write and counting clean recoveries."*
2. *"Multiprocess architecture with a supervisor that survives arbitrary child death — proven by
   `kill -9` during a 48-hour unattended soak, with measured detection and recovery latency and
   provable zero data gaps via per-source sequence accounting."*
3. *"I implemented solar and lunar ephemeris from scratch in C so the device could attribute sky
   brightness to a physical cause — moonlight versus light pollution versus cloud-scattered glow —
   entirely offline, with no network dependency of any kind."*
4. *"The fusion fixes a specific, reproducible failure of the naive approach: at a rural site an
   overcast sky is darker than a clear one, so a light meter alone confidently recommends the worst
   night of the month. The infrared channel catches exactly that case."*
5. *"I produced a reliability diagram for my own confidence score and reported where it was
   miscalibrated, rather than shipping a number that looked authoritative and wasn't."*
6. *"I considered real-time scheduling and a no-drop high-rate pipeline and rejected both, because
   at 1 Hz sampling neither is justified — the mechanisms in the system are there because the
   problem demanded them."*

Number 5 and number 6 are the ones that separate an engineer from someone who finished a project.
