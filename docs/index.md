# Aquarium

The aquarium application is one HTTP service on one port. Its own domain
handlers and the reusable modules it carries register on the same router.

The first module it carries is the inventory and expense tracker, served under
`/expenses`. The module owns its tables and pages; the application owns the
router, the port and the workspace its records live in.
