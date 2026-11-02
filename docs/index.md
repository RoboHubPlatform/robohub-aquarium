# Aquarium

The aquarium application is one HTTP service on one port. Its own domain
handlers and the reusable modules it carries register on the same router.

The modules it carries share its router, port and workspace:

- the inventory and expense tracker under `/expenses`;
- the scheduler under `/scheduler`, with its chores API under `/api/scheduler`;
- the widgets module under `/widgets`, which renders the dashboard cards on the
  home page and serves `/api/widgets`.

Each module owns its tables and pages; the application owns the router, one main
SQL database and the workspace the records live in.

## Dashboard and equipment

The home page is a dashboard: widgets are cards, and the equipment, automation,
chemistry and mode pages are the framework the board will drive later.

- **Equipment** — devices with a state and a last value. A device can be switched
  and can report a value; the same row becomes a real pump, light or heater when
  a node binds it.
- **Automation** — rules made of a metric, an operator, a threshold and an
  action. Evaluating a value moves the rule between normal and triggered and
  writes an audit event. The rule is the policy; the hardware binding is a later
  layer.
- **Chemistry** — manual water tests (ammonia, nitrite, nitrate, phosphate, KH,
  calcium, magnesium) with value, unit, date and note.
- **Modes** — water change and feeding windows with a duration; the page is
  where they are started and where normal operation resumes.
- **Events** — the append-only audit trail of overrides, trips, modes and
  automation.

The widgets module gives the dashboard number, chart, button and switch cards.
A switch calls its configured hook with the new state and shows it in the card.

All forms are cards: a semi-opaque panel over the aquarium background, with the
same colours on every module page.
