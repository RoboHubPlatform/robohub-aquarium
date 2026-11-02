# Changelog

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
