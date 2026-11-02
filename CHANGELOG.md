# Changelog

## [0.1.0] - 2026-11-02

The aquarium application host. One HTTP service and one router; the inventory
module is included and serves `/expenses`, and the scheduler serves `/scheduler`
and `/api/scheduler`. Both keep their tables in the application's main SQL
database and their records in its workspace.
