# RoboHub Aquarium

The RoboHub aquarium application: the tank, its water chemistry, the equipment
that keeps it running and the inventory and schedule behind them. It reaches
devices only through the `robohub.gateway` interface and the provider it binds
(Mesh today), and it is installed, signed in to and supervised by the keeper.

This repository sits beside the orchestrator, `robohub`, which carries the
shared modules it uses (`inventory`, `scheduler`, `widgets`, `journal`, `rules`,
`appapi`, `simulator`, `ui`, `forms`, `notifications`, `settings`, `i18n`,
`logging`) and the gateway interface.

The aquarium's own code is in `src/aquarium/` (tanks and targets, water,
dosing and livestock, the overview, settings), its own tables in `db/`, and what
each shared module starts with in `presets/`.

## Building

```sh
rho build .
```

## Running

The keeper runs it as a user service with its `app.env`; from a terminal:

```sh
ROBOHUB_APP_WORKSPACE=/tmp/aquarium RHO_HTTP_ADDR=127.0.0.1:8480 ./build/aquarium
```

## Tests

```sh
rho test .
```

## Documentation

`docs/index.md`, built into the RoboHub site by `rho doc`.
