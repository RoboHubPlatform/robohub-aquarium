-- The categories an item or a purchase can belong to.
CREATE TABLE IF NOT EXISTS categories (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    name    TEXT NOT NULL UNIQUE
);

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
    created_at       TEXT NOT NULL DEFAULT (datetime('now'))
);

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
    created_at             TEXT NOT NULL DEFAULT (datetime('now'))
);

-- One completion of a chore, with the note a person left.
CREATE TABLE IF NOT EXISTS chore_completions (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    chore_id          INTEGER NOT NULL REFERENCES chores(id),
    completed_epoch   INTEGER NOT NULL,
    note              TEXT,
    created_at        TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS chore_completions_chore ON chore_completions(chore_id);

-- Equipment the application can call, read or simulate. Without a board a
-- device is still a row with a state and the last value it reported.
CREATE TABLE IF NOT EXISTS devices (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT NOT NULL,
    kind            TEXT NOT NULL,
    state           TEXT NOT NULL DEFAULT 'unknown',
    last_value      TEXT,
    updated_epoch   INTEGER NOT NULL DEFAULT 0
);

-- A rule is a metric, an operator and an action. The engine evaluates it when a
-- value is fed in; the hardware binding can be added without changing the rule.
CREATE TABLE IF NOT EXISTS automation_rules (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT NOT NULL,
    kind            TEXT NOT NULL,
    metric          TEXT NOT NULL,
    operator        TEXT NOT NULL,
    threshold       TEXT NOT NULL DEFAULT '0',
    action          TEXT NOT NULL,
    enabled         INTEGER NOT NULL DEFAULT 1,
    state           TEXT NOT NULL DEFAULT 'normal',
    last_value      TEXT NOT NULL DEFAULT '0',
    updated_epoch   INTEGER NOT NULL DEFAULT 0
);

-- Manual water tests, the chemistry log.
CREATE TABLE IF NOT EXISTS water_tests (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    parameter       TEXT NOT NULL,
    value           TEXT NOT NULL,
    unit            TEXT NOT NULL DEFAULT '',
    tested_at       TEXT NOT NULL,
    note            TEXT
);

-- Operational modes with an expiry: water change, feeding, and so on.
CREATE TABLE IF NOT EXISTS aquarium_modes (
    name                TEXT PRIMARY KEY,
    active_until_epoch  INTEGER NOT NULL DEFAULT 0,
    note                TEXT
);

-- Append-only audit trail. A state change, a manual override, a trip.
CREATE TABLE IF NOT EXISTS system_events (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    severity        TEXT NOT NULL DEFAULT 'INFO',
    kind            TEXT NOT NULL,
    message         TEXT NOT NULL,
    created_epoch   INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS system_events_created ON system_events(created_epoch);

-- A dashboard widget. numeric shows the last value; chart shows the last
-- `points` values as a sparkline. source_kind is manual or url.
CREATE TABLE IF NOT EXISTS widgets (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    title            TEXT NOT NULL,
    kind             TEXT NOT NULL DEFAULT 'numeric',
    source_kind      TEXT NOT NULL DEFAULT 'manual',
    source           TEXT,
    method           TEXT NOT NULL DEFAULT 'GET',
    unit             TEXT,
    points           INTEGER NOT NULL DEFAULT 24,
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
