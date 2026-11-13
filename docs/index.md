# Aquarium

The RoboHub aquarium: a tank's water, the equipment that keeps it, and the care
it needs. It is a keeper-hosted application, and it reaches devices only through
the gateway interface — the Mesh provider for real devices, or the simulator.

## What is the aquarium's own

| Place | What it does |
|---|---|
| Overview | the tank, its readings against their target bands, equipment and its switches, the last day's temperature, what is due, the journal |
| Water & chemistry | each parameter's newest reading and trend; history; the tank's target bands; logging a test (a row per parameter, with the kit each used up); water changes |
| Dosing | what was added to the water, taken off the product's stock |
| Livestock & plants | what lives in a tank, how many, and losses |
| Tanks | each tank's volume, kind and light hours, and the one the pages show |

A test outside its band is a journal warning — a notification, open until
someone resolves it. Each tank's newest results are offered as values
(`/api/v1/values`): `<tank>.<parameter>`, and `<parameter>` for the first tank, so
a rule can say `no3 > 25`. A water change logged is the "Water change" chore done.

## What it shares

| Module | What the aquarium uses it for |
|---|---|
| inventory | food, test kits, fertilisers, filter media — and the equipment, bound to gateway sources by capability |
| rules | keeping the temperature, the lights, CO₂ following the light, a filter that stopped; the feeding and maintenance modes |
| scheduler | water changes, tests, rinsing the filter by its runtime, cleaning the glass |
| journal | everything that happened |
| widgets | the dashboard |
| appapi | the values it offers other applications |
| simulator | devices to run on without a mesh |

What each of them starts with is the aquarium's `presets/`: `inventory.yml`,
`rules.yml`, `schedule.yml`, `api.yml`, `sim.yml`, and its own `targets.yml`.

## Equipment and its handles

The preset rules name equipment by handle: `heater`, `light`, `filter-main`, `co2`.
Give an inventory item that handle and bind its capabilities on its Automation
tab — the heater's switch to its plug and its temperature to a probe — and the
rules act on it. Until then they read nothing, do nothing, and say so.

## Settings

Settings → Gateway chooses where readings come from (Mesh or the simulator),
Mesh's project, and how its changes arrive (automatic, the broker, or HTTP).
Mesh's address and the token it is read with come from the keeper.
