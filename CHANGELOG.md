# Changelog

## [0.1.0] - 2026-11-02

The aquarium application host. One HTTP service and one router; the inventory
module serves `/expenses`, the scheduler serves `/scheduler` and
`/api/scheduler`, and the widgets module serves the dashboard cards and
`/api/widgets`. All keep their tables in the application's main SQL database and
their records in its workspace.

## [0.2.0] - 2026-11-02

The aquarium framework: equipment and devices, automation rules with a value
evaluation and audit event, the water chemistry log, operational modes and the
event trail. The home page is a dashboard built from configurable widgets:
numbers, charts, buttons and switches, each with its own source or hook. All
forms are semi-opaque panels over the aquarium background.

## [0.2.1] - 2026-11-03

A Settings page for the Mesh and gateway URLs. The widget editor reads the
device list through Mesh and the gateway and offers it as a **Mesh device**
selection; a Switch widget can then turn a plug on and off from the dashboard.

## [0.2.2] - 2026-11-03

Settings name a Mesh project, not just a Mesh URL. Aquarium asks Mesh for that
project's gateway (`/mesh/api/projects/{project}/gateway`) and stores the
address automatically; the widget editor then lists the devices behind that
gateway.

## [0.2.3] - 2026-11-03

The dashboard keeps its full menu everywhere, offers **+ Add widget** beside the
dashboard, and the switch cards are switch-first: no panel border, a larger
switch, the title opens the widget settings, and pressing the switch stays on
the dashboard.

## [0.2.4] - 2026-11-03

The dashboard is reactive: widgets listen to the widgets SSE stream and refresh
device states in the background, so an externally switched plug updates without
a page reload. A dashboard switch press updates the control in place.

## [0.2.5] - 2026-11-03

The dashboard's switch press no longer assumes a JSON reply: an older cached
page that posts the form normally is followed by a reload instead of a JSON
parse error. Dashboard pages are served with no-store so the live script is not
cached.

## [0.2.6] - 2026-11-03

The switch card shows one switch (its text is no longer drawn as a second
track), and reconnecting the event stream starts from the current state rather
than replaying old events.

## [0.2.7] - 2026-11-03

Widget switches are correct on the first paint: the dashboard syncs the gateway
state before rendering, and still updates live through SSE with an API polling
fallback.

## [0.2.8] - 2026-11-03

The widget editor lists the Mesh project's inputs and outputs, not only gateway
devices: modules and sensors can feed numbers, charts and tables, and a plug can
feed a switch or show its power. The list is filtered by the widget kind and the
signal's direction, and a chosen source fills its unit. The dashboard has a
Table widget with a settable row count.

## [0.2.9] - 2026-11-04

Aquarium signs in through Keeper SSO. The dashboard, widgets and settings are behind the aquarium session; outbound Mesh API calls carry a signed service JWT so widgets keep reading and driving Mesh.

## [0.3.0] - 2026-11-05

Aquarium's dashboard charts use the robohub-mesh telemetry store. A chart bound
to a Mesh source reads the source's history through the mesh-gateway provider;
a number reads the latest stored value. The miralis project's temperature chart
therefore shows a series instead of the local snapshots the widget happened to
fetch. The Aquarium menu also carries the Keeper link when the keeper started
the application, with the same ↑ affordance as Mesh.

## [0.3.1] - 2026-11-06

Fixed chart widget to parse decimal values (was showing flat line). Chart now
requests 2 hours of history instead of 24 hours for responsiveness. Service
token now requires mesh:default scope.

## [0.3.2] - 2026-11-08

English and Romanian pages, flag-based language switching, and translated
navigation, settings, forms and live widget updates. The Aquarium settings page
now owns the runtime settings for the application and its Inventory, Scheduler
and Widgets dependencies, with vertical tabs, a shared URL/gateway tab, and a
single module-tab layout preference.

## [0.3.3] - 2026-11-09

Inventory, scheduler and widget pages now render inside the aquarium shell instead of their own layouts. Widget card CSS comes from the widgets module.

## [0.3.4] - 2026-11-12

The smoke test signs in with a keeper ticket, as the keeper issues them.

## [0.4.0] - 2026-11-12

Aquarium reaches Mesh through the gateway interface, binding the Mesh provider with Mesh's address and the project in `module.yml`. The Settings page writes those into the binding's settings for the installation; the `mesh-gateway` plugin entry, the contract include and `gateway.conf` are gone.

## [0.4.1] - 2026-11-13

The aquarium has a repository of its own, `robohub-aquarium`, beside the
orchestrator, with its history. It declares the RoboHub platform, and binds the
bus as well as the gateway: with `transport: auto` the Mesh provider (0.4.0)
follows the feed Mesh relays on the keeper's broker (`mesh/<project>/telemetry`,
which its broker user may read) and falls back to Mesh's HTTP stream when there
is no broker.

Its own `db/schema.sql` and `db/queries.sql` now hold the aquarium's tables only.
The copies of the inventory, scheduler and widgets tables and statements are
gone: those modules declare their own (inventory 0.2.0, scheduler 0.1.5, widgets
0.2.6) and rho-sql 0.2 generates them in.

## [0.5.0] - 2026-11-13

The aquarium is rebuilt on the shared RoboHub modules, in the RoboHub shell.

What is an aquarium's is its own: tanks (volume, kind, light hours), each with
target bands per parameter seeded from its kind (presets/targets.yml); water
tests logged a row per parameter with the kit each used up, compared with the
bands (out of band is a journal warning) and offered as values a rule can read
(`no3`); water changes, which complete the water-change chore; doses, which take
the product off the inventory; livestock and plants, with losses.

What any application needs is a shared module, seeded from the aquarium's
presets: equipment is inventory items bound to gateway sources (inventory 0.2),
automation is rules and modes (feeding, maintenance), events are the journal,
recurring care is the scheduler, the dashboard is widgets 0.3, and
`/api/v1/values` and `/api/v1/events` are appapi. Readings come from Mesh or the
simulator, chosen in Settings, with Mesh's transport and project; the aquarium no
longer registers with Mesh itself or keeps a shared-secret callback.

The pages: an overview (the tank, its readings against their bands, equipment
with its switches, the last day's temperature, what is due, the journal),
equipment, water and chemistry, dosing, livestock and plants, tanks and settings,
with the shared modules' pages in the same shell; dark and light. The old
equipment, automation, chemistry, modes and events pages lead to their new
places. An installation of 0.4 keeps its records: its events move to the journal
once, and its widgets' Mesh URLs move to stable ids.

## [0.5.1] - 2026-11-13

`same_origin` refuses a form posted from another origin: keeper and the other applications are other ports of the same host, which a SameSite cookie does not tell apart. Built on widgets 0.3.1, inventory 0.2.1, i18n 0.4.1, rules 0.1.1 and notifications 0.1.4. The smoke test tries each of the holes those close.

## [0.5.2] - 2026-11-13

The clock is read from the process (`rho_now_s`, rho 0.6.0) instead of from `date` written to a file and read back, which a request and the background loop could truncate under each other: entries dated 1970 and modes that expired at once. Built on the shared modules' fixes of the same kind and provider-mesh 0.5.1, which no longer hands one source's reading to another.

## [0.5.3] - 2026-11-13

A form that changed something sends the browser back to its page by GET: reloading the page after logging a test, a dose, a water change, livestock, a tank or a device mapping no longer does it again — a second kit used up, the water-change chore completed twice. A water test with one value that is not a number keeps none of them, so sending it again corrected logs nothing twice.

## [0.5.4] - 2026-11-13

Built on the shared modules' fixes: cron chores read as cron, rule durations with decimals and days, a mode ended once, the journal badge past 500, the newest history points, inventory totals in 64 bits and decimal commas, no blank notification.

## [0.6.0] - 2026-11-13

Several tanks, each with its own equipment, rules and chores.

- Roles are a tank's: the first tank keeps `heater`, `light`, `filter-main`
  and `co2`; another tank's are its handle's (`reef-nano-heater`). The Devices
  page fills the roles of the tank it is opened for, and offers the others.
- Each tank has its own copy of the preset rules, named and written with its
  handles and its light hours, made when it is added and kept current at start.
- The temperature rules compare with the tank's own band rather than fixed
  numbers: the heater switches on a quarter of the band above its bottom and
  off a quarter below its top (`band.temperature.on`, `.off`), and the alarm is
  two degrees past the top (`.alarm`). For the planted band, 24.5–26 °C, that is
  on below 24.875 and off above 25.625, where it was 24.5 and 25.5.
- Each tank has its own water change, water test and filter rinse; a water
  change logged for a tank completes that tank's.
- The overview, the Water page and the temperature chart read the tank's own
  probe, through its heater; the light status is the tank's light.
- The feeding and maintenance modes still act on the first tank's equipment.
