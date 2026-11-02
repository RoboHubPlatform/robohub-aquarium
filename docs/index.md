# Aquarium

The aquarium application is one HTTP service on one port. Its own domain
handlers and the reusable modules it carries register on the same router.

The modules it carries share its router, port and workspace:

- the inventory and expense tracker under `/expenses`;
- the scheduler under `/scheduler`, with its chores API under `/api/scheduler`.

Each module owns its tables and pages; the application owns the router, one main
SQL database and the workspace the records live in.
