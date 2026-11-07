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

-- name: insert_device
INSERT INTO devices (name, kind, state, last_value, updated_epoch)
VALUES (:name, :kind, :state, :last_value, :updated_epoch);

-- name: list_devices
SELECT id, name, kind, state, COALESCE(last_value, '') AS last_value, updated_epoch
FROM devices ORDER BY name;

-- name: update_device_state
UPDATE devices SET state = :state, updated_epoch = :updated_epoch WHERE id = :id;

-- name: update_device_value
UPDATE devices SET last_value = :last_value, updated_epoch = :updated_epoch
WHERE id = :id;

-- name: insert_rule
INSERT INTO automation_rules
    (name, kind, metric, operator, threshold, action, enabled, state, last_value,
     updated_epoch)
VALUES
    (:name, :kind, :metric, :operator, :threshold, :action, :enabled, 'normal', 0,
     :updated_epoch);

-- name: list_rules
SELECT id, name, kind, metric, operator, threshold, action, enabled, state,
       last_value, updated_epoch
FROM automation_rules ORDER BY kind, name;

-- name: update_rule
UPDATE automation_rules
SET enabled = :enabled, state = :state, last_value = :last_value,
    updated_epoch = :updated_epoch
WHERE id = :id;

-- name: insert_test
INSERT INTO water_tests (parameter, value, unit, tested_at, note)
VALUES (:parameter, :value, :unit, :tested_at, :note);

-- name: list_tests
SELECT id, parameter, value, unit, tested_at, COALESCE(note, '') AS note
FROM water_tests ORDER BY tested_at DESC, id DESC LIMIT 200;

-- name: set_mode
INSERT INTO aquarium_modes (name, active_until_epoch, note)
VALUES (:name, :active_until_epoch, :note)
ON CONFLICT(name) DO UPDATE SET
    active_until_epoch = excluded.active_until_epoch,
    note = excluded.note;

-- name: get_modes
SELECT name, active_until_epoch, COALESCE(note, '') AS note
FROM aquarium_modes ORDER BY name;

-- name: insert_event
INSERT INTO system_events (severity, kind, message, created_epoch)
VALUES (:severity, :kind, :message, :created_epoch);

-- name: list_events
SELECT id, severity, kind, message, created_epoch
FROM system_events ORDER BY created_epoch DESC, id DESC LIMIT 200;

-- name: insert_widget
INSERT INTO widgets (title, kind, source_kind, source, method, unit, points, position, size, decimals, created_epoch)
VALUES (:title, :kind, :source_kind, :source, :method, :unit, :points, :position, :size, :decimals, :created_epoch);

-- name: list_widgets
SELECT id, title, kind, source_kind, COALESCE(source, '') AS source,
       method, COALESCE(unit, '') AS unit, points, position, size, decimals, pinned, created_epoch
FROM widgets ORDER BY position, title;

-- name: update_widget
UPDATE widgets SET title = :title, kind = :kind, source_kind = :source_kind,
    source = :source, method = :method, unit = :unit, points = :points, decimals = :decimals WHERE id = :id;

-- name: move_widget
UPDATE widgets SET position = :position WHERE id = :id;

-- name: resize_widget
UPDATE widgets SET size = :size WHERE id = :id;

-- name: pin_widget
UPDATE widgets SET pinned = :pinned WHERE id = :id;

-- name: delete_widget
DELETE FROM widgets WHERE id = :id;

-- name: insert_widget_value
INSERT INTO widget_values (widget_id, value_text, value_milli, recorded_epoch)
VALUES (:widget_id, :value_text, :value_milli, :recorded_epoch);

-- name: list_widget_values
SELECT * FROM widget_values WHERE widget_id = :widget_id
ORDER BY recorded_epoch DESC, id DESC LIMIT 100;

-- name: latest_widget_value
SELECT id, widget_id, value_text, value_milli, recorded_epoch
FROM widget_values WHERE widget_id = :widget_id
ORDER BY recorded_epoch DESC, id DESC LIMIT 1;
