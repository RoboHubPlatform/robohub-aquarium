# RoboHub Aquarium

The RoboHub aquarium application: tanks and their target bands, water tests and
changes, dosing, livestock and plants, the equipment that keeps a tank and the rules
that drive it, the schedule and the journal. It reaches devices only through the
`robohub.gateway` interface and the provider it binds (Mesh, or the simulator), and
it is installed, signed in to and supervised by the keeper, which serves it at
`/app/aquarium/`. Its own loopback port is `127.0.0.1:8480`.

This repository sits beside the orchestrator, `robohub`, which carries the shared
modules it uses (`inventory`, `scheduler`, `widgets`, `journal`, `rules`, `appapi`,
`appshell`, `simulator`, `ui`, `forms`, `notifications`, `settings`, `i18n`,
`logging`, `htmx`) and the gateway interface.

The aquarium's own code is in `src/aquarium/` (tanks and targets, water, dosing and
livestock, the overview, the Devices page's roles, the shell), its own tables in
`db/`, and what each shared module starts with in `presets/`.

## Building and running

```sh
rho build .
```

The keeper runs it as a user service with its `app.env`; from a terminal:

```sh
ROBOHUB_APP_WORKSPACE=/tmp/aquarium RHO_HTTP_ADDR=127.0.0.1:8480 ./build/aquarium
```

## Tests

```sh
rho test .
```

## Documentation

[docs/index.md](docs/index.md), built into the RoboHub site and served by the
running application under Documentation.
