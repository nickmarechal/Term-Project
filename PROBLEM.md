# Problem memo -- Dark Sky Monitor (Nick Marechal, Liam Sagal)

> **STATUS: PARTIALLY DRAFTED.** The idea is locked: **Dark Sky Monitor**. Sensors and mechanisms
> below are settled by `docs/design-review.md`. **The user, problem, and risk sections still need
> a real conversation with a real person** — see the action item under "The user." A memo that
> names no real user gets returned for revision and costs a week.

## The user

**ACTION REQUIRED THIS WEEK.** Do not write "amateur astronomers" — that fails the guardrail.
Two concrete leads, either of which also gets us a reference instrument and a path to The Reach:

- **Northern Colorado Astronomical Society** (Fort Collins). Members drive to dark sites, already
  own Sky Quality Meters, and will talk at length for free.
- **CSU Physics / astronomy faculty or the campus observatory** — walking distance, may lend an SQM.

Fill in a named person and what they specifically told us once contact is made.

## The problem

The observing decision is costly and currently made badly:

- Driving 40–60 minutes to a dark site and arriving under cloud wastes the evening.
- Unpacking and thermally equilibrating a telescope takes 30–45 minutes; doing it on a night that
  closes in is wasted setup and teardown.
- The inverse error is worse *and invisible*: **staying home on a night that was actually
  excellent.** Nobody ever finds out about those, which is exactly why a logging instrument beats
  a nightly guess.

**TODO:** replace the generic framing above with what the actual user says it costs *them*, in
their words, with a frequency.

## Why a device

The interesting transitions happen unattended, at hours nobody is watching: the 2 a.m. clearing,
the high cirrus that arrives at 11 p.m., the three-week creep in background brightness after a
neighbour installs a floodlight. A phone is not in the yard, not pointed at the zenith, and not
awake.

**Why a phone app doesn't solve it** (this must confront the real competition — Astrospheric and
Clear Sky Chart are free and good):

1. They are **forecasts for a grid cell** kilometres wide. This is a **measurement of one yard.**
2. They require **internet.** The highest-value stargazing happens at a dark site with **no cell
   signal** — exactly where every existing answer stops working.
3. They don't know this site's light pollution and can't detect that it changed.
4. "Should I unpack the scope *right now*" is a present-tense question; a forecast isn't an answer.

## The sensors

Three sensors, all on one I2C bus. Two would be the floor; the physics punishes two (below).

| Sensor | Measures | Role in the single decision |
|---|---|---|
| **TSL2591** | sky brightness (high dynamic range, reaches ~188 µLux) | how dark the sky actually is, and how *stable* that darkness is |
| **MLX90614** | zenith IR temperature | cloud cover, via ΔT = T_ambient − T_sky (clear sky radiates 20–40 °C below ambient; cloud radiates near ambient) |
| **BME280** | ambient temp, humidity, pressure | **required, not a nicety:** humidity confounds ΔT, because water vapour radiates in the IR window. Also supplies the ambient reference and a pressure trend. |

**How they cooperate — the reason this isn't two demos stapled together:** a brightness sensor
alone is not merely imprecise, it is **wrong in a specific, reproducible way.** At a rural dark
site an overcast sky is *darker* than a clear one, because there is no light to reflect. A light
meter alone therefore confidently recommends the single worst night of the month. The infrared
channel catches exactly that case, and the pair together separate moonlight (bright + cold sky)
from cloud-scattered city glow (bright + warm sky) — a distinction no threshold on either sensor
can make.

## The mechanisms

- **D — custom crash-consistent storage layer.** Weeks of nightly site baseline are the product's
  memory, and they must survive a power cut mid-write; SD-card wear makes the fsync and
  write-batching policy a real design decision rather than an inherited default.
- **E — multiprocess + IPC + supervisor.** A silently dead sky monitor is this product's own
  nightmare scenario, so sensor isolation and supervision are requirements rather than garnish;
  the most failure-prone sensor (MLX90614) must not be able to take down the others.

Considered and **rejected**, with reasons, because sample rates are 0.1–1 Hz: **C** (no hard
deadline exists in "is the sky dark") and **F** (a no-drop high-rate pipeline for a 1 Hz signal
would be padding). **A** (character driver) is a stretch goal, not a commitment.

## The risk

**The MLX90614 cannot see through plastic.** Acrylic and most plastics are opaque in the 8–14 µm
band it uses, so a sealed clear window blinds the cloud sensor outright — and the cloud channel is
the half of the fusion that makes the project defensible. Mitigation is an open aperture under a
rain hood or a thin polyethylene film window, and **it must be tested in week 6, not week 12.**

Second risk, close behind: **the weather owes us nothing.** Clear nights in October and November
are finite and unrecoverable, so the human observation logbook starts the week the sensors first
read, not the week the classifier is finished.
