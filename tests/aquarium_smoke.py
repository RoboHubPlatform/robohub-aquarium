#!/usr/bin/env python3
"""Smoke test for the aquarium, end to end, on the simulator.

Builds the aquarium, gives it a workspace with a database an aquarium of 0.4
left behind, chooses the simulator as the gateway, starts it on a free local
port, and walks what a person does: the overview, a water test out of band, a
dose, a water change, livestock, tanks and targets, settings, and the pages of
0.4 that moved.
"""

import html
import json
import os
import re
import socket
import sqlite3
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = ROOT.parent
RHO = WORKSPACE / "rho" / "bin" / "rho"
TOKEN = ""
CSRF = ""


def rho() -> str:
    return str(RHO) if RHO.exists() else "rho"


def mint_token(home: str) -> str:
    """A ticket for the aquarium, as the keeper would issue one."""
    keys = os.path.join(home, ".rho", "auth")
    os.makedirs(keys, exist_ok=True)
    subprocess.run([rho(), "auth", "keygen", "--dir", keys, "--force"], check=True, capture_output=True, text=True)
    result = subprocess.run([rho(), "auth", "ticket", "--private", os.path.join(keys, "private.pem"), "--issuer", "keeper",
                             "--audience", "aquarium", "--subject", "smoke", "--scopes", "*", "--ttl", "1h"],
                            check=True, capture_output=True, text=True)
    return result.stdout.strip()


def open_url(target, timeout: float = 20):
    request = target if isinstance(target, urllib.request.Request) else urllib.request.Request(target)
    request.add_header("Authorization", f"Bearer {TOKEN}")
    return urllib.request.urlopen(request, timeout=timeout)


def get(base: str, path: str) -> str:
    with open_url(base + path) as response:
        return response.read().decode("utf-8", "replace")


def post(base: str, path: str, fields: dict) -> str:
    fields = dict(fields, csrf=CSRF)
    request = urllib.request.Request(base + path, data=urllib.parse.urlencode(fields).encode(), method="POST")
    request.add_header("Content-Type", "application/x-www-form-urlencoded")
    with open_url(request) as response:
        return response.read().decode("utf-8", "replace")


def free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def wait_for(base: str) -> None:
    deadline = time.time() + 30
    while time.time() < deadline:
        try:
            with open_url(base + "/healthz", timeout=2):
                return
        except (urllib.error.URLError, OSError):
            time.sleep(0.3)
    raise SystemExit("the aquarium did not start")


def assert_contains(text: str, needles: list, label: str) -> None:
    for needle in needles:
        if needle not in text:
            raise AssertionError(f"{label} does not contain {needle!r}")


OLD = """
CREATE TABLE system_events (id INTEGER PRIMARY KEY AUTOINCREMENT, severity TEXT NOT NULL DEFAULT 'INFO',
    kind TEXT NOT NULL, message TEXT NOT NULL, created_epoch INTEGER NOT NULL DEFAULT 0);
INSERT INTO system_events (severity, kind, message, created_epoch) VALUES
    ('INFO', 'mode', 'water_change started', 1794000000), ('WARN', 'rule', 'Overheat triggered', 1794000100);
"""


def main() -> int:
    global TOKEN, CSRF
    build = subprocess.run([rho(), "build", str(ROOT)], capture_output=True, text=True)
    if build.returncode != 0:
        raise SystemExit("build failed:\n" + build.stdout + build.stderr)
    port = free_port()
    base = f"http://127.0.0.1:{port}"
    with tempfile.TemporaryDirectory(prefix="aquarium-") as workspace, tempfile.TemporaryDirectory(prefix="aquarium-home-") as home:
        os.makedirs(os.path.join(workspace, "data"))
        db = os.path.join(workspace, "data", "app.db")
        with sqlite3.connect(db) as conn:
            conn.executescript(OLD)
        with open(os.path.join(workspace, "bind.conf"), "w") as f:
            f.write("robohub-provider-mesh.enabled=false\nsimulator.enabled=true\n")
        os.chmod(os.path.join(workspace, "bind.conf"), 0o600)
        TOKEN = mint_token(home)
        env = dict(os.environ, HOME=home, ROBOHUB_APP_WORKSPACE=workspace, RHO_APP_WORKSPACE=workspace,
                   RHO_HTTP_ADDR=f"127.0.0.1:{port}", ROBOHUB_APP_MANIFEST=str(ROOT / "module.yml"))
        env.setdefault("RHO_HOME", os.path.join(os.path.expanduser("~"), ".rho"))
        process = subprocess.Popen([str(ROOT / "build" / "aquarium")], cwd=ROOT, env=env,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        try:
            wait_for(base)
            page = get(base, "/expenses")
            CSRF = html.unescape(re.search(r'name="csrf" value="([^"]*)"', page).group(1))

            # 0.4's events are in the journal, as history; the presets are seeded;
            # a first tank was made.
            journal = json.loads(get(base, "/api/journal?since=0"))
            messages = [e["message"] for e in journal["entries"]]
            for wanted in ("water_change started", "Overheat triggered"):
                if wanted not in messages:
                    raise AssertionError(f"{wanted!r} was not moved to the journal: {messages}")
            with sqlite3.connect(db) as conn:
                categories = {r[0] for r in conn.execute("SELECT name FROM categories")}
                rules = {r[0] for r in conn.execute("SELECT name FROM rules")}
                chores = {r[0] for r in conn.execute("SELECT title FROM chores")}
                tank = conn.execute("SELECT id, handle FROM aquarium_tanks").fetchone()
                targets = conn.execute("SELECT COUNT(*) FROM aquarium_targets WHERE tank_id = ?", (tank[0],)).fetchone()[0]
            if not {"Filters", "Heaters", "Test kits"} <= categories:
                raise AssertionError(f"inventory presets: {categories}")
            if not {"keep-temperature", "lights", "filter-stopped"} <= rules or "Water change" not in chores:
                raise AssertionError(f"rule or schedule presets: {rules} {chores}")
            if targets != 8:
                raise AssertionError(f"the first tank has {targets} targets")

            # Every page draws in the shell.
            for path, needle in (("/", "Equipment"), ("/equipment", "Equipment"), ("/water", "Nitrate"),
                                 ("/water?tab=log", "Log the test"), ("/water?tab=targets", "Save the targets"),
                                 ("/water?tab=changes", "Log the change"), ("/dosing", "Dosing"),
                                 ("/livestock", "Livestock"), ("/tank", "Add a tank"), ("/settings", "Readings come from"),
                                 ("/settings?tab=about", "simulator"), ("/rules", "Feeding"), ("/journal", "Journal"),
                                 ("/scheduler", "Water change"), ("/widgets", "Widgets"), ("/docs", "Aquarium")):
                text = get(base, path)
                assert_contains(text, [needle, 'class="rh-rail"', "Water &amp; chemistry"], path)

            # A test kit and a fertiliser in the inventory.
            with sqlite3.connect(db) as conn:
                kits = conn.execute("SELECT id FROM categories WHERE name='Test kits'").fetchone()[0]
                ferts = conn.execute("SELECT id FROM categories WHERE name='Fertilisers'").fetchone()[0]
            post(base, "/expenses/items/add", {"name": "NO3 test", "category_id": str(kits), "handle": "no3-kit", "quantity": "10"})
            post(base, "/expenses/items/add", {"name": "Fertiliser", "category_id": str(ferts), "handle": "fert", "quantity": "100", "unit": "ml"})

            # A test above the target is a warning, uses up the kit, and is offered.
            assert_contains(post(base, "/water/test", {"tank": str(tank[0]), "v_no3": "28", "k_no3": "no3-kit", "v_ph": "6,9"}),
                            ["2 readings logged", "28 mg/L"], "a water test")
            journal = json.loads(get(base, "/api/journal?kind=test"))
            if not any(e["level"] == "warning" and "above the 25 target" in e["message"] for e in journal["entries"]):
                raise AssertionError(f"the out-of-band test is not a warning: {journal}")
            with sqlite3.connect(db) as conn:
                left = conn.execute("SELECT quantity_milli FROM items WHERE handle='no3-kit'").fetchone()[0]
            if left != 9000:
                raise AssertionError(f"the kit was not used up: {left}")
            values = {v["id"]: v["value"] for v in json.loads(get(base, "/api/v1/values"))["values"]}
            if values.get("no3") != "28" or values.get(tank[1] + ".ph") != "6.9":
                raise AssertionError(f"the results are not offered: {values}")

            # A dose takes the product off the shelf.
            assert_contains(post(base, "/dosing", {"tank": str(tank[0]), "product": "fert", "amount": "5"}), ["Dose logged"], "a dose")
            with sqlite3.connect(db) as conn:
                if conn.execute("SELECT quantity_milli FROM items WHERE handle='fert'").fetchone()[0] != 95000:
                    raise AssertionError("the dose did not reduce the fertiliser")

            # A water change is the water-change chore done.
            assert_contains(post(base, "/water/change", {"tank": str(tank[0]), "percent": "30"}), ["Water change logged"], "a water change")
            with sqlite3.connect(db) as conn:
                completed = conn.execute("SELECT last_completed_epoch FROM chores WHERE title='Water change'").fetchone()[0]
            if completed == 0:
                raise AssertionError("the water-change chore was not completed")

            # Livestock, and a loss.
            post(base, "/livestock", {"tank": str(tank[0]), "kind": "fish", "species": "Paracheirodon innesi", "count": "12"})
            with sqlite3.connect(db) as conn:
                fish = conn.execute("SELECT id FROM aquarium_livestock").fetchone()[0]
            post(base, "/livestock/loss", {"tank": str(tank[0]), "id": str(fish)})
            assert_contains(get(base, "/livestock"), ["Paracheirodon innesi", "11 animals"], "livestock")

            # A second tank, of another kind; changing the first tank's kind
            # gives it that kind's targets.
            assert_contains(post(base, "/tank/add", {"name": "Reef nano", "volume": "60", "kind": "reef"}), ["Tank added"], "a tank")
            post(base, "/tank", {"id": str(tank[0]), "name": "Living room", "volume": "240", "kind": "community"})
            with sqlite3.connect(db) as conn:
                low, high = conn.execute("SELECT low_milli, high_milli FROM aquarium_targets WHERE tank_id=? AND parameter='no3'", (tank[0],)).fetchone()
            if (low, high) != (0, 40000):
                raise AssertionError(f"the community targets were not taken: {low} {high}")
            assert_contains(get(base, "/"), ["Living room · 240 L Community"], "the overview")

            # Devices: the roles the rules name, filled by items bound to
            # sources the gateway (here the simulator) lists.
            page = get(base, "/devices")
            assert_contains(page, ["Heater", "Main filter", "not mapped", "sim-heater-plug.switch", "sim-probe.temperature"], "the devices page")
            assert_contains(post(base, "/devices", {"role": "heater", "item": "new", "src_switch": "sim-heater-plug.switch",
                                                    "src_temperature": "sim-probe.temperature", "src_power": "sim-heater-plug.power"}),
                            ["Heater: mapped"], "the heater mapped to a new item")
            with sqlite3.connect(db) as conn:
                heater = conn.execute("SELECT id, kind FROM items WHERE handle='heater'").fetchone()
                bound = dict(conn.execute("SELECT capability, source FROM item_bindings WHERE item_id=?", (heater[0],)).fetchall())
                lighting = conn.execute("SELECT id FROM categories WHERE name='Lighting'").fetchone()[0]
            if heater[1] != "equipment" or bound != {"switch": "sim-heater-plug.switch", "temperature": "sim-probe.temperature", "power": "sim-heater-plug.power"}:
                raise AssertionError(f"the heater mapping: {heater} {bound}")
            post(base, "/expenses/items/add", {"name": "LED bar", "category_id": str(lighting), "kind": "equipment"})
            post(base, "/expenses/items/add", {"name": "Spare LED", "category_id": str(lighting), "kind": "equipment"})
            with sqlite3.connect(db) as conn:
                bar = conn.execute("SELECT id FROM items WHERE name='LED bar'").fetchone()[0]
                spare = conn.execute("SELECT id FROM items WHERE name='Spare LED'").fetchone()[0]
            post(base, "/devices", {"role": "light", "item": str(bar), "src_switch": "sim-light-relay.switch"})
            taken = post(base, "/devices", {"role": "filter-main", "item": "new", "src_switch": "sim-light-relay.switch"})
            assert_contains(taken, ["already controlled by LED bar"], "one relay for two roles")
            post(base, "/devices", {"role": "light", "item": str(spare), "src_switch": ""})
            with sqlite3.connect(db) as conn:
                handles = dict(conn.execute("SELECT name, handle FROM items WHERE name IN ('LED bar', 'Spare LED')").fetchall())
            if handles != {"LED bar": "", "Spare LED": "light"}:
                raise AssertionError(f"the role did not move to the other item: {handles}")
            assert_contains(get(base, "/devices"), ["connected"], "a mapped role")

            # Settings choose where readings come from.
            post(base, "/settings?tab=gateway", {"provider": "robohub-provider-mesh", "transport": "http"})
            conf = open(os.path.join(workspace, "bind.conf")).read()
            if "simulator.enabled=false" not in conf or "robohub-provider-mesh.enabled=true" not in conf or "robohub-provider-mesh.transport=http" not in conf:
                raise AssertionError(f"the gateway was not switched: {conf}")
            post(base, "/settings?tab=gateway", {"provider": "simulator", "transport": "auto"})
            assert_contains(get(base, "/"), ["Simulator"], "back on the simulator")

            # 0.4's pages lead to where their work is now.
            for old, new in (("/chemistry", "Water &amp; chemistry"), ("/automation", "Rules &amp; modes"), ("/events", "Journal")):
                assert_contains(get(base, old), [new], old)
        finally:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
    return 0


if __name__ == "__main__":
    sys.exit(main())
