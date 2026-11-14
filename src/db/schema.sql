-- The appapi module's tables.
-- The appapi module's tables. They belong to the module: an application that
-- includes it gets them generated in (rho-sql 0.2), and never repeats them.

-- A value the application offers. kind is derived (from its presets), published
-- (computed by the application) or export (a reading it passes on). updated_at
-- is Unix seconds.
CREATE TABLE IF NOT EXISTS appapi_values (
    id          TEXT PRIMARY KEY,
    value       TEXT NOT NULL DEFAULT '',
    unit        TEXT NOT NULL DEFAULT '',
    label       TEXT NOT NULL DEFAULT '',
    kind        TEXT NOT NULL DEFAULT 'published',
    updated_at  INTEGER NOT NULL DEFAULT 0
);

-- Each value's history, one row per change, kept for 30 days. at is Unix
-- seconds; value is the number, when the value is one.
CREATE TABLE IF NOT EXISTS appapi_history (
    id     TEXT NOT NULL,
    at     INTEGER NOT NULL,
    value  REAL NOT NULL
);

CREATE INDEX IF NOT EXISTS appapi_history_id_at ON appapi_history(id, at);

-- How a value is derived, from the application's presets. source is what it is
-- derived from (an inventory item's capability, `heater.temperature`, or a
-- journal kind for `since`); fn is latest, avg, min, max, integral, since or
-- export; window_s is the window avg/min/max/integral look over.
CREATE TABLE IF NOT EXISTS appapi_derived (
    id        TEXT PRIMARY KEY,
    source    TEXT NOT NULL,
    fn        TEXT NOT NULL DEFAULT 'latest',
    window_s  INTEGER NOT NULL DEFAULT 0,
    unit      TEXT NOT NULL DEFAULT '',
    label     TEXT NOT NULL DEFAULT ''
);


-- The inventory module's tables.
-- The inventory module's tables. They belong to the module: an application
-- that includes it gets them generated in (rho-sql 0.2), and never repeats them.
--
-- A column added in a later version is in its table's CREATE and in an ALTER
-- after it: a new database gets it from the CREATE (the ALTER then finds it and
-- is passed over), an older one from the ALTER.

-- The categories an item or a purchase can belong to. An application seeds its
-- own from its presets. kind is what an item in it is by default: consumable
-- (used up: food, fertiliser), part (fitted and replaced: filter media) or
-- equipment (installed, and possibly automated). capabilities are what an
-- equipment item in it can be bound to — `switch, power?` — a trailing ? marks
-- one that may stay unbound. uses names a category whose items it consumes
-- (a feeder uses food).
CREATE TABLE IF NOT EXISTS categories (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    name         TEXT NOT NULL UNIQUE,
    kind         TEXT NOT NULL DEFAULT 'consumable',
    capabilities TEXT NOT NULL DEFAULT '',
    uses         TEXT NOT NULL DEFAULT '',
    origin       TEXT NOT NULL DEFAULT 'person'
);

ALTER TABLE categories ADD COLUMN kind TEXT NOT NULL DEFAULT 'consumable';
ALTER TABLE categories ADD COLUMN capabilities TEXT NOT NULL DEFAULT '';
ALTER TABLE categories ADD COLUMN uses TEXT NOT NULL DEFAULT '';
-- 'preset' for a category the application's presets keep (its name is what the
-- application reads), 'person' for one a person added and may rename or delete.
ALTER TABLE categories ADD COLUMN origin TEXT NOT NULL DEFAULT 'person';

-- What is on hand, how much of it, and when to reorder.
CREATE TABLE IF NOT EXISTS items (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    name             TEXT NOT NULL,
    category_id      INTEGER REFERENCES categories(id),
    unit             TEXT NOT NULL DEFAULT 'unit',
    quantity_milli   INTEGER NOT NULL DEFAULT 0,
    reorder_milli    INTEGER NOT NULL DEFAULT 0,
    location         TEXT,
    notes            TEXT,
    created_at       TEXT NOT NULL DEFAULT (datetime('now')),
    kind             TEXT NOT NULL DEFAULT 'consumable',
    handle           TEXT NOT NULL DEFAULT '',
    runtime_s        INTEGER NOT NULL DEFAULT 0,
    runtime_at       INTEGER NOT NULL DEFAULT 0,
    portion_milli    INTEGER NOT NULL DEFAULT 0
);

-- kind: consumable, part or equipment. handle is the name everything else uses
-- for the item — `filter-main` — so a rule, a dashboard card or a chore names the
-- item and never the plug it happens to be on. runtime_s is how long its switch
-- has been on, counted from its history up to runtime_at (Unix seconds).
-- portion_milli is what one use takes from the category it uses (a feeder's
-- portion of food).
ALTER TABLE items ADD COLUMN kind TEXT NOT NULL DEFAULT 'consumable';
ALTER TABLE items ADD COLUMN handle TEXT NOT NULL DEFAULT '';
ALTER TABLE items ADD COLUMN runtime_s INTEGER NOT NULL DEFAULT 0;
ALTER TABLE items ADD COLUMN runtime_at INTEGER NOT NULL DEFAULT 0;
ALTER TABLE items ADD COLUMN portion_milli INTEGER NOT NULL DEFAULT 0;

CREATE UNIQUE INDEX IF NOT EXISTS items_handle ON items(handle) WHERE handle <> '';

-- What an equipment item's capabilities are bound to: one gateway source each.
-- access is control for a capability the item drives (a switch) and read for one
-- it only reports (power, temperature). A source is controlled by one item at
-- most, so two items cannot fight over one relay.
CREATE TABLE IF NOT EXISTS item_bindings (
    item_id     INTEGER NOT NULL REFERENCES items(id),
    capability  TEXT NOT NULL,
    source      TEXT NOT NULL,
    access      TEXT NOT NULL DEFAULT 'read',
    bound_at    TEXT NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (item_id, capability)
);

CREATE UNIQUE INDEX IF NOT EXISTS item_bindings_control ON item_bindings(source) WHERE access = 'control';

-- One purchase line. Money is integer cents and quantity is thousandths, so a
-- total never depends on the floating-point spelling of 12.34.
CREATE TABLE IF NOT EXISTS expenses (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id           INTEGER REFERENCES items(id),
    item              TEXT NOT NULL,
    category_id       INTEGER REFERENCES categories(id),
    quantity_milli    INTEGER NOT NULL DEFAULT 1000,
    unit_price_cents  INTEGER NOT NULL DEFAULT 0,
    total_cents       INTEGER NOT NULL DEFAULT 0,
    source            TEXT,
    purchased_at      TEXT NOT NULL,
    comment           TEXT,
    created_at        TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS expenses_purchased_at ON expenses(purchased_at);

-- Every change to the stock, so the quantity can be read as a history rather
-- than only as a current number. quantity_milli is signed: negative is stock
-- leaving the shelf.
CREATE TABLE IF NOT EXISTS stock_movements (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id          INTEGER NOT NULL REFERENCES items(id),
    kind             TEXT NOT NULL,
    quantity_milli   INTEGER NOT NULL,
    unit_price_cents INTEGER NOT NULL DEFAULT 0,
    total_cents      INTEGER NOT NULL DEFAULT 0,
    source           TEXT,
    occurred_at      TEXT NOT NULL,
    comment          TEXT,
    created_at       TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS stock_movements_item ON stock_movements(item_id);


-- The journal module's tables.
-- The journal module's table. It belongs to the module: an application that
-- includes it gets it generated in (rho-sql 0.2), and never repeats it.

-- One thing that happened. at is Unix seconds. level is info, warning or error.
-- kind is what sort of thing it was (switch, rule, mode, test, stock, system),
-- subject what it was about (an item's handle, a rule's name), actor who or what
-- did it (person:ana, rule:keep-temperature, device, system). An entry that
-- needs attention stays open until resolved_at is set.
CREATE TABLE IF NOT EXISTS journal_entries (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    at           INTEGER NOT NULL,
    level        TEXT NOT NULL DEFAULT 'info',
    kind         TEXT NOT NULL DEFAULT 'system',
    subject      TEXT NOT NULL DEFAULT '',
    actor        TEXT NOT NULL DEFAULT 'system',
    message      TEXT NOT NULL,
    resolved_at  INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS journal_entries_at ON journal_entries(at);


-- The rules module's tables.
-- The rules module's tables. They belong to the module: an application that
-- includes it gets them generated in (rho-sql 0.2), and never repeats them.

-- A rule: when `when_expr` holds (for for_s seconds, when set), run do_actions;
-- when it stops holding — or, with clear_expr, when that holds — run
-- else_actions. A rule fires at most once per cooldown_s. origin is preset (from
-- the application's presets, kept current by them) or person. state is idle,
-- pending or active; state_since and last_fired are Unix seconds.
CREATE TABLE IF NOT EXISTS rules (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT NOT NULL UNIQUE,
    enabled       INTEGER NOT NULL DEFAULT 1,
    when_expr     TEXT NOT NULL,
    clear_expr    TEXT NOT NULL DEFAULT '',
    for_s         INTEGER NOT NULL DEFAULT 0,
    cooldown_s    INTEGER NOT NULL DEFAULT 0,
    do_actions    TEXT NOT NULL DEFAULT '',
    else_actions  TEXT NOT NULL DEFAULT '',
    origin        TEXT NOT NULL DEFAULT 'person',
    state         TEXT NOT NULL DEFAULT 'idle',
    state_since   INTEGER NOT NULL DEFAULT 0,
    last_fired    INTEGER NOT NULL DEFAULT 0,
    last_error    TEXT NOT NULL DEFAULT ''
);

-- What the presets say each preset rule is, kept as they say it: a rule a person
-- edited (origin 'edited') is no longer changed by the presets, and is put back
-- from here when they ask for the preset again.
CREATE TABLE IF NOT EXISTS rule_presets (
    name          TEXT PRIMARY KEY,
    when_expr     TEXT NOT NULL,
    clear_expr    TEXT NOT NULL DEFAULT '',
    for_s         INTEGER NOT NULL DEFAULT 0,
    cooldown_s    INTEGER NOT NULL DEFAULT 0,
    do_actions    TEXT NOT NULL DEFAULT '',
    else_actions  TEXT NOT NULL DEFAULT ''
);

-- A mode: a named change for a while. Starting it runs do_actions and
-- suspends the rules named in suspends (comma-separated); it ends after
-- duration_s (0: when someone ends it) and runs end_actions.
CREATE TABLE IF NOT EXISTS rule_modes (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    name         TEXT NOT NULL UNIQUE,
    title        TEXT NOT NULL DEFAULT '',
    duration_s   INTEGER NOT NULL DEFAULT 0,
    do_actions   TEXT NOT NULL DEFAULT '',
    end_actions  TEXT NOT NULL DEFAULT '',
    suspends     TEXT NOT NULL DEFAULT '',
    origin       TEXT NOT NULL DEFAULT 'person'
);

-- The mode in force, at most one: the row with id 1, or none.
CREATE TABLE IF NOT EXISTS rule_mode_active (
    id          INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    started_at  INTEGER NOT NULL,
    ends_at     INTEGER NOT NULL DEFAULT 0,
    actor       TEXT NOT NULL DEFAULT ''
);


-- The scheduler module's tables.
-- A chore definition and its next due time. next_due_epoch is Unix seconds;
-- zero means the schedule has no wall-clock due time (a usage chore).
CREATE TABLE IF NOT EXISTS chores (
    id                     INTEGER PRIMARY KEY AUTOINCREMENT,
    title                  TEXT NOT NULL,
    description            TEXT,
    schedule_kind          TEXT NOT NULL,
    schedule_value         TEXT,
    interval_hours         INTEGER NOT NULL DEFAULT 0,
    usage_interval_hours   INTEGER NOT NULL DEFAULT 0,
    usage_accum_seconds    INTEGER NOT NULL DEFAULT 0,
    grace_hours            INTEGER NOT NULL DEFAULT 0,
    priority               TEXT NOT NULL DEFAULT 'normal',
    enabled                INTEGER NOT NULL DEFAULT 1,
    next_due_epoch         INTEGER NOT NULL DEFAULT 0,
    snoozed_until_epoch    INTEGER NOT NULL DEFAULT 0,
    last_completed_epoch   INTEGER NOT NULL DEFAULT 0,
    created_at             TEXT NOT NULL DEFAULT (datetime('now')),
    runtime_of             TEXT NOT NULL DEFAULT '',
    runtime_seen           INTEGER NOT NULL DEFAULT 0,
    consumes               TEXT NOT NULL DEFAULT '',
    consumes_milli         INTEGER NOT NULL DEFAULT 0
);

-- runtime_of names an inventory item (by handle) whose switch runtime drives a
-- usage chore, instead of hours typed in; runtime_seen is the item's runtime
-- already counted. consumes names an item a completion takes consumes_milli
-- (thousandths) off: a filter pad, a dose.
ALTER TABLE chores ADD COLUMN runtime_of TEXT NOT NULL DEFAULT '';
ALTER TABLE chores ADD COLUMN runtime_seen INTEGER NOT NULL DEFAULT 0;
ALTER TABLE chores ADD COLUMN consumes TEXT NOT NULL DEFAULT '';
ALTER TABLE chores ADD COLUMN consumes_milli INTEGER NOT NULL DEFAULT 0;

-- One completion of a chore, with the note a person left.
CREATE TABLE IF NOT EXISTS chore_completions (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    chore_id          INTEGER NOT NULL REFERENCES chores(id),
    completed_epoch   INTEGER NOT NULL,
    note              TEXT,
    created_at        TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS chore_completions_chore ON chore_completions(chore_id);


-- The widgets module's tables.
-- A dashboard widget. numeric shows the last value; chart shows the last
-- `points` values as a sparkline; status shows a badge with an ok/warn/bad/info
-- state; button calls its configured hook; toggle reflects and sets a switch.
--
-- `position`, `size`, `decimals` and `pinned` are part of the card layout. The
-- canonical definition lives here; a host includes this file's tables in its
-- own SQL port so the module and the host cannot describe two different
-- widgets tables.
CREATE TABLE IF NOT EXISTS widgets (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    title            TEXT NOT NULL,
    kind             TEXT NOT NULL DEFAULT 'numeric',
    source_kind      TEXT NOT NULL DEFAULT 'manual',
    source           TEXT,
    method           TEXT NOT NULL DEFAULT 'GET',
    unit             TEXT,
    points           INTEGER NOT NULL DEFAULT 24,
    position         INTEGER NOT NULL DEFAULT 0,
    size             TEXT NOT NULL DEFAULT 'small',
    decimals         INTEGER NOT NULL DEFAULT 2,
    pinned           INTEGER NOT NULL DEFAULT 0,
    created_epoch    INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS widget_values (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    widget_id        INTEGER NOT NULL REFERENCES widgets(id),
    value_text       TEXT NOT NULL,
    value_milli      INTEGER NOT NULL DEFAULT 0,
    recorded_epoch   INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS widget_values_widget ON widget_values(widget_id);


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
