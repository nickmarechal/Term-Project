# Problem memo — Dark Sky Monitor (Nick Marechal, Liam Sagal)

> Full technical detail in [`docs/design-review.md`](docs/design-review.md). **Known gap:** the user
> below is an archetype, not a named individual; outreach to the Northern Colorado Astronomical
> Society and CSU astronomy faculty is in progress and either contact also lends us a reference Sky
> Quality Meter. Recording the gap rather than hiding it, per spec §5.

## The user

Amateur stargazers — specifically the one with a modest backyard instrument rather than an
observatory: a 6–8" Dobsonian or small refractor, stored indoors and carried out by hand when the
sky looks promising. They observe from one fixed spot a few times a month, and a few times a season
they drive 30–60 minutes to a darker site outside Fort Collins.

Three properties of this user drive the whole design. **Setup is expensive to them** — carrying the
instrument out, leveling it, and letting the optics reach thermal equilibrium is 30–45 minutes
before the first useful look, paid before they know if the night was worth it. **They own no
instruments** — no sky quality meter, no cloud sensor; the current procedure is stepping outside and
guessing. **They are not at the site continuously** — they are indoors, asleep, or at work while the
sky does the interesting things.

## The problem

- **The wasted trip.** Driving an hour to a dark site and arriving under cloud costs the evening.
  Nothing at the house told them not to go.
- **The wasted setup.** 45 minutes out and 45 back, on a night that closed an hour later.
- **The invisible error, which is worse.** Staying in on a night that was excellent. They never find
  out, so the cost is never felt and never corrected. Only something that logs every night can
  surface these — and a forecast structurally cannot, because a forecast is never checked against
  what the sky actually did.

## Why a device

The sky's interesting transitions happen unattended and at bad hours: the 2 a.m. clearing, the high
cirrus at 11 p.m., the months-long brightening after a neighbour installs a floodlight. A phone is
not in the yard, not pointed at the zenith, and not awake.

Astrospheric and Clear Sky Chart are free and good, so the memo must beat them, not ignore them.
They are **forecasts for a grid cell kilometres wide**; this is a **measurement of one yard.** They
need **internet**, and the best observing happens at a dark site with **no cell signal** — exactly
where every existing answer stops working. And they cannot know this site's light pollution, or that
it changed.

## The sensors

**TSL2591** (sky brightness, reaches ~188 µLux) and **MLX90614** (zenith IR temperature → cloud
cover via ΔT = T_ambient − T_sky; clear sky radiates 20–40 °C below ambient, cloud radiates near
ambient). A **BME280** supplies ambient temperature, humidity, and pressure — required, not
optional, because water vapour radiates in the IR window, so a humid *clear* sky mimics cloud unless
ΔT is humidity-corrected.

**How they cooperate:** a brightness sensor alone is not merely imprecise, it is wrong in a
specific, reproducible way. **At a dark site an overcast sky is *darker* than a clear one**, because
there is no light to reflect — so a light meter alone confidently recommends the worst night of the
month. The IR channel catches exactly that case, and the pair together separate moonlight (bright +
cold sky) from cloud-scattered town glow (bright + warm sky). No threshold on either sensor alone
can make that distinction.

## The mechanisms

- **D — custom crash-consistent storage.** Weeks of nightly site baseline *are* the product's
  memory and must survive a power cut mid-write; SD-card wear makes fsync and write-batching policy
  a real decision rather than an inherited default.
- **E — multiprocess + IPC + supervisor.** A silently dead sky monitor is this product's own
  nightmare scenario, and the most failure-prone sensor must not be able to take down the others.

Considered and rejected, because we sample at 0.1–1 Hz: **C** (no hard deadline exists in "is the
sky dark") and **F** (a no-drop high-rate pipeline for a 1 Hz signal would be padding).

## The risk

**The MLX90614 cannot see through plastic.** Acrylic is opaque in the 8–14 µm band it uses, so a
sealed clear window blinds the cloud sensor — the half of the fusion that makes this project
defensible. Mitigation is an open aperture under a rain hood or a thin polyethylene window, and it
must be tested in Week 6, not Week 12.

Close behind: **the weather owes us nothing.** Clear nights in October and November are finite and
unrecoverable, so the human observation logbook starts the week the sensors first read.
