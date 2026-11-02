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
