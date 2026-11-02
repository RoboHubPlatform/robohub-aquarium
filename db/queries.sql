-- name: insert_category
INSERT INTO categories (name) VALUES (:name);

-- name: list_categories
SELECT id, name FROM categories ORDER BY name;

-- name: insert_item
INSERT INTO items (name, category_id, unit, quantity_milli, reorder_milli,
                   location, notes)
VALUES (:name, NULLIF(:category_id, ''), :unit, :quantity_milli,
        :reorder_milli, :location, :notes);

-- name: list_items
SELECT i.id, i.name, COALESCE(c.name, '') AS category, i.category_id, i.unit,
       i.quantity_milli, i.reorder_milli, COALESCE(i.location, '') AS location,
       COALESCE(i.notes, '') AS notes
FROM items i
LEFT JOIN categories c ON c.id = i.category_id
ORDER BY i.name;

-- name: update_item_details
UPDATE items
SET name = :name, category_id = NULLIF(:category_id, ''), unit = :unit,
    reorder_milli = :reorder_milli, location = :location, notes = :notes
WHERE id = :id;

-- name: update_item_stock
UPDATE items SET quantity_milli = quantity_milli + :delta WHERE id = :id;

-- name: insert_expense
INSERT INTO expenses
    (item_id, item, category_id, quantity_milli, unit_price_cents, total_cents,
     source, purchased_at, comment)
VALUES
    (NULLIF(:item_id, ''), :item, NULLIF(:category_id, ''), :quantity_milli,
     :unit_price_cents, :total_cents, :source, :purchased_at, :comment);

-- name: list_expenses
SELECT e.id, e.item, COALESCE(c.name, '') AS category,
       e.quantity_milli, e.unit_price_cents, e.total_cents,
       COALESCE(e.source, '') AS source, e.purchased_at,
       COALESCE(e.comment, '') AS comment
FROM expenses e
LEFT JOIN categories c ON c.id = e.category_id
ORDER BY e.purchased_at DESC, e.id DESC;

-- name: delete_expense
DELETE FROM expenses WHERE id = :id;

-- name: total_expenses
SELECT COALESCE(SUM(total_cents), 0) AS total_cents FROM expenses;

-- name: insert_movement
INSERT INTO stock_movements
    (item_id, kind, quantity_milli, unit_price_cents, total_cents, source,
     occurred_at, comment)
VALUES
    (:item_id, :kind, :quantity_milli, :unit_price_cents, :total_cents, :source,
     :occurred_at, :comment);

-- name: low_stock_items
SELECT i.id, i.name, i.quantity_milli, i.reorder_milli, i.unit,
       COALESCE(i.location, '') AS location
FROM items i
WHERE i.reorder_milli > 0 AND i.quantity_milli <= i.reorder_milli
ORDER BY i.quantity_milli;
-- name: insert_chore
INSERT INTO chores
    (title, description, schedule_kind, schedule_value, interval_hours,
     usage_interval_hours, grace_hours, priority, next_due_epoch, enabled)
VALUES
    (:title, :description, :schedule_kind, :schedule_value, :interval_hours,
     :usage_interval_hours, :grace_hours, :priority, :next_due_epoch, :enabled);

-- name: list_chores
SELECT id, title, COALESCE(description, '') AS description, schedule_kind,
       COALESCE(schedule_value, '') AS schedule_value, interval_hours,
       usage_interval_hours, usage_accum_seconds, grace_hours, priority,
       enabled, next_due_epoch, snoozed_until_epoch, last_completed_epoch,
       created_at
FROM chores
ORDER BY enabled DESC, next_due_epoch, title;

-- name: complete_chore
UPDATE chores
SET next_due_epoch = :next_due_epoch,
    last_completed_epoch = :last_completed_epoch,
    snoozed_until_epoch = 0,
    usage_accum_seconds = :usage_accum_seconds
WHERE id = :id;

-- name: insert_completion
INSERT INTO chore_completions (chore_id, completed_epoch, note)
VALUES (:chore_id, :completed_epoch, :note);

-- name: snooze_chore
UPDATE chores SET snoozed_until_epoch = :snoozed_until_epoch WHERE id = :id;

-- name: add_usage
UPDATE chores
SET usage_accum_seconds = usage_accum_seconds + :delta_seconds
WHERE id = :id;

-- name: list_completions
SELECT c.id, c.chore_id, ch.title, c.completed_epoch,
       COALESCE(c.note, '') AS note
FROM chore_completions c
LEFT JOIN chores ch ON ch.id = c.chore_id
ORDER BY c.completed_epoch DESC, c.id DESC
LIMIT 50;
