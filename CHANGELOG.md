# Changelog

## [0.2.6] - 2026-11-03

The switch card shows one switch (its text is no longer drawn as a second
track), and reconnecting the event stream starts from the current state rather
than replaying old events.

## [0.2.5] - 2026-11-03

The dashboard's switch press no longer assumes a JSON reply: an older cached
page that posts the form normally is followed by a reload instead of a JSON
parse error. Dashboard pages are served with no-store so the live script is not
cached.

## [0.2.4] - 2026-11-03

The dashboard is reactive: widgets listen to the widgets SSE stream and refresh
device states in the background, so an externally switched plug updates without
a page reload. A dashboard switch press updates the control in place.

## [0.2.3] - 2026-11-03

The dashboard keeps its full menu everywhere, offers **+ Add widget** beside the
dashboard, and the switch cards are switch-first: no panel border, a larger
switch, the title opens the widget settings, and pressing the switch stays on
the dashboard.

## [0.2.2] - 2026-11-03

Settings name a Mesh project, not just a Mesh URL. Aquarium asks Mesh for that
project's gateway (`/mesh/api/projects/{project}/gateway`) and stores the
address automatically; the widget editor then lists the devices behind that
gateway.

## [0.2.1] - 2026-11-03

A Settings page for the Mesh and gateway URLs. The widget editor reads the
device list through Mesh and the gateway and offers it as a **Mesh device**
selection; a Switch widget can then turn a plug on and off from the dashboard.

## [0.2.0] - 2026-11-02

The aquarium framework: equipment and devices, automation rules with a value
evaluation and audit event, the water chemistry log, operational modes and the
event trail. The home page is a dashboard built from configurable widgets:
numbers, charts, buttons and switches, each with its own source or hook. All
forms are semi-opaque panels over the aquarium background.

## [0.1.0] - 2026-11-02

The aquarium application host. One HTTP service and one router; the inventory
module serves `/expenses`, the scheduler serves `/scheduler` and
`/api/scheduler`, and the widgets module serves the dashboard cards and
`/api/widgets`. All keep their tables in the application's main SQL database and
their records in its workspace.
