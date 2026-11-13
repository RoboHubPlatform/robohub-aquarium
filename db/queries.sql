-- name: list_tanks
SELECT id, name, handle, volume_l, type, lights_on, lights_off, notes, created_at
FROM aquarium_tanks ORDER BY id;

-- name: insert_tank
INSERT INTO aquarium_tanks (name, handle, volume_l, type, lights_on, lights_off, notes, created_at)
VALUES (:name, :handle, :volume_l, :type, :lights_on, :lights_off, :notes, :created_at);

-- name: update_tank
UPDATE aquarium_tanks SET name = :name, volume_l = :volume_l, type = :type,
    lights_on = :lights_on, lights_off = :lights_off, notes = :notes
WHERE id = :id;

-- name: list_targets
SELECT tank_id, parameter, low_milli, high_milli FROM aquarium_targets
WHERE tank_id = :tank_id ORDER BY parameter;

-- name: put_target
INSERT OR REPLACE INTO aquarium_targets (tank_id, parameter, low_milli, high_milli)
VALUES (:tank_id, :parameter, :low_milli, :high_milli);

-- name: seed_target
INSERT OR IGNORE INTO aquarium_targets (tank_id, parameter, low_milli, high_milli)
VALUES (:tank_id, :parameter, :low_milli, :high_milli);

-- name: insert_test
INSERT INTO aquarium_tests (tank_id, parameter, value_milli, at, kit, source, note)
VALUES (:tank_id, :parameter, :value_milli, :at, :kit, :source, :note);

-- name: list_tests
SELECT id, tank_id, parameter, value_milli, at, kit, source, note
FROM aquarium_tests WHERE tank_id = :tank_id AND at >= :since
ORDER BY at DESC, id DESC LIMIT 500;

-- name: insert_dose
INSERT INTO aquarium_doses (tank_id, product, amount_milli, unit, at, note)
VALUES (:tank_id, :product, :amount_milli, :unit, :at, :note);

-- name: list_doses
SELECT id, tank_id, product, amount_milli, unit, at, note
FROM aquarium_doses WHERE tank_id = :tank_id ORDER BY at DESC, id DESC LIMIT 200;

-- name: insert_water_change
INSERT INTO aquarium_water_changes (tank_id, percent, at, note)
VALUES (:tank_id, :percent, :at, :note);

-- name: list_water_changes
SELECT id, tank_id, percent, at, note
FROM aquarium_water_changes WHERE tank_id = :tank_id ORDER BY at DESC, id DESC LIMIT 100;

-- name: insert_livestock
INSERT INTO aquarium_livestock (tank_id, kind, species, count, added_at, notes)
VALUES (:tank_id, :kind, :species, :count, :added_at, :notes);

-- name: list_livestock
SELECT id, tank_id, kind, species, count, lost, added_at, notes
FROM aquarium_livestock WHERE tank_id = :tank_id ORDER BY kind, species;

-- name: record_loss
UPDATE aquarium_livestock SET lost = lost + 1 WHERE id = :id AND count > lost;

-- name: list_legacy_events
SELECT id, severity, kind, message, created_epoch FROM system_events ORDER BY id;

-- name: resolve_all_journal
UPDATE journal_entries SET resolved_at = at WHERE resolved_at = 0 AND actor = 'system' AND subject = '';
