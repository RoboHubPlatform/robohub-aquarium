-- The aquarium's own tables. Everything a shared module keeps — the inventory
-- and its equipment, the schedule, the rules, the journal, the dashboard, the
-- values the aquarium offers — is that module's, generated in by rho-sql (0.2).

-- A tank. type is planted, community, reef or pond: what its targets are
-- seeded from. lights_on and lights_off are HH:MM, what the light rules use.
CREATE TABLE IF NOT EXISTS aquarium_tanks (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL,
    handle      TEXT NOT NULL UNIQUE,
    volume_l    INTEGER NOT NULL DEFAULT 0,
    type        TEXT NOT NULL DEFAULT 'planted',
    lights_on   TEXT NOT NULL DEFAULT '10:00',
    lights_off  TEXT NOT NULL DEFAULT '20:00',
    notes       TEXT NOT NULL DEFAULT '',
    created_at  INTEGER NOT NULL DEFAULT 0
);

-- A parameter's target band for a tank, in thousandths: temperature 24.5–26 is
-- 24500–26000.
CREATE TABLE IF NOT EXISTS aquarium_targets (
    tank_id     INTEGER NOT NULL,
    parameter   TEXT NOT NULL,
    low_milli   INTEGER NOT NULL,
    high_milli  INTEGER NOT NULL,
    PRIMARY KEY (tank_id, parameter)
);

-- One water test: a parameter's value in thousandths, at a time, with the kit
-- (an inventory consumable, by handle) that was used up, or by a sensor.
CREATE TABLE IF NOT EXISTS aquarium_tests (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    tank_id      INTEGER NOT NULL,
    parameter    TEXT NOT NULL,
    value_milli  INTEGER NOT NULL,
    at           INTEGER NOT NULL,
    kit          TEXT NOT NULL DEFAULT '',
    source       TEXT NOT NULL DEFAULT 'manual',
    note         TEXT NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS aquarium_tests_tank_at ON aquarium_tests(tank_id, at);

-- One dose: a product (an inventory consumable, by handle) and how much of it,
-- in the product's unit and thousandths.
CREATE TABLE IF NOT EXISTS aquarium_doses (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    tank_id       INTEGER NOT NULL,
    product       TEXT NOT NULL,
    amount_milli  INTEGER NOT NULL,
    unit          TEXT NOT NULL DEFAULT '',
    at            INTEGER NOT NULL,
    note          TEXT NOT NULL DEFAULT ''
);

-- One water change: the share of the tank's volume, in percent.
CREATE TABLE IF NOT EXISTS aquarium_water_changes (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    tank_id  INTEGER NOT NULL,
    percent  INTEGER NOT NULL,
    at       INTEGER NOT NULL,
    note     TEXT NOT NULL DEFAULT ''
);

-- What lives in a tank: fish, invertebrates, corals and plants, how many, since
-- when, and how many were lost.
CREATE TABLE IF NOT EXISTS aquarium_livestock (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    tank_id   INTEGER NOT NULL,
    kind      TEXT NOT NULL DEFAULT 'fish',
    species   TEXT NOT NULL,
    count     INTEGER NOT NULL DEFAULT 1,
    lost      INTEGER NOT NULL DEFAULT 0,
    added_at  INTEGER NOT NULL DEFAULT 0,
    notes     TEXT NOT NULL DEFAULT ''
);

-- The events the aquarium kept before the journal module (0.4 and earlier). It
-- is read once, into the journal, and otherwise left as it was.
CREATE TABLE IF NOT EXISTS system_events (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    severity        TEXT NOT NULL DEFAULT 'INFO',
    kind            TEXT NOT NULL,
    message         TEXT NOT NULL,
    created_epoch   INTEGER NOT NULL DEFAULT 0
);
