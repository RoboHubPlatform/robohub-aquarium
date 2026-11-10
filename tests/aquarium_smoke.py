#!/usr/bin/env python3
"""Smoke test for the aquarium modular monolith."""

import json
import os
import re
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve()
APP = HERE.parents[1]
ROBOHUB = APP.parents[1]
PROJECTS = ROBOHUB.parent
RHO = PROJECTS / "rho" / "bin" / "rho"
SESSION = "smoke-session"


def free_port() -> int:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def wait_for(base: str) -> None:
    deadline = time.time() + 20
    while time.time() < deadline:
        try:
            request = urllib.request.Request(base + "/healthz")
            with urllib.request.urlopen(request, timeout=1) as response:
                if response.status == 200:
                    return
        except (urllib.error.URLError, ConnectionError):
            time.sleep(0.2)
    raise SystemExit(f"aquarium did not start at {base}")


def get(base: str, path: str) -> str:
    request = urllib.request.Request(base + path)
    request.add_header("Cookie", f"keeper_session={SESSION}")
    with urllib.request.urlopen(request, timeout=10) as response:
        return response.read().decode("utf-8", "replace")


def post(base: str, path: str, fields: dict) -> str:
    body = urllib.parse.urlencode(fields).encode()
    request = urllib.request.Request(base + path, data=body, method="POST")
    request.add_header("Content-Type", "application/x-www-form-urlencoded")
    request.add_header("Cookie", f"keeper_session={SESSION}")
    with urllib.request.urlopen(request, timeout=20) as response:
        return response.read().decode("utf-8", "replace")


def csrf(base: str, path: str = "/widgets") -> str:
    match = re.search(r'name="csrf" value="([^"]+)"', get(base, path))
    if not match:
        raise AssertionError(f"no CSRF token on {path}")
    return match.group(1)


def assert_contains(haystack: str, needles: list, label: str) -> None:
    for needle in needles:
        if needle not in haystack:
            raise AssertionError(f"{label} does not contain {needle!r}")


def build() -> Path:
    binary = APP / "build" / "aquarium"
    rho = str(RHO) if RHO.exists() else "rho"
    result = subprocess.run([rho, "build", str(APP)], cwd=ROBOHUB, text=True,
                            capture_output=True)
    if result.returncode != 0:
        raise SystemExit("aquarium build failed:\n" + result.stdout + result.stderr)
    if not binary.exists():
        raise SystemExit(f"aquarium build wrote no binary at {binary}")
    return binary


def main() -> int:
    binary = build()
    port = free_port()
    base = f"http://127.0.0.1:{port}"
    with tempfile.TemporaryDirectory(prefix="aquarium-") as workspace:
        env = dict(os.environ)
        env["ROBOHUB_WORKSPACE"] = str(ROBOHUB)
        env["ROBOHUB_APP_WORKSPACE"] = workspace
        env["ROBOHUB_APP_MANIFEST"] = str(APP / "module.yml")
        env["RHO_HTTP_ADDR"] = f":{port}"
        home = Path(workspace) / "home"
        sessions = home / ".rho" / "keeper"
        sessions.mkdir(parents=True, exist_ok=True)
        (sessions / "auth-sessions.txt").write_text(
            f"{SESSION}|{int(time.time()) + 3600}|smoke\n", encoding="utf-8")
        env["HOME"] = str(home)
        process = subprocess.Popen([str(binary)], cwd=APP, env=env,
                                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   text=True)
        try:
            wait_for(base)
            for page in ["/expenses", "/scheduler", "/widgets", "/equipment",
                         "/automation", "/chemistry", "/modes", "/events"]:
                get(base, page)

            post(base, "/equipment/add", {"name": "Return pump", "kind": "pump", "state": "off"})
            assert_contains(get(base, "/equipment"), ["Return pump", "pump"], "equipment")

            post(base, "/automation/add", {
                "name": "Overheat", "kind": "thermal", "metric": "water_temp",
                "operator": ">", "threshold": "28", "action": "cool_on",
            })
            post(base, "/automation/simulate", {"id": "1", "value": "29.5"})
            assert_contains(get(base, "/automation"), ["Overheat", "triggered"], "automation")

            post(base, "/chemistry/add", {
                "parameter": "Nitrate", "value": "5", "unit": "ppm",
                "tested_at": "2026-11-02", "note": "ok",
            })
            assert_contains(get(base, "/chemistry"), ["Nitrate", "ppm"], "chemistry")

            post(base, "/modes/start", {"name": "water_change", "minutes": "30"})
            assert_contains(get(base, "/events"), ["water_change started", "Overheat triggered"],
                            "audit trail")

            post(base, "/widgets/add", {
                "title": "Water temperature", "kind": "numeric",
                "source_kind": "manual", "unit": "C",
                "csrf": csrf(base),
            })
            post(base, "/widgets/value", {"id": "1", "value": "25.4"})
            assert_contains(get(base, "/"), ["Water temperature", "25.4"], "dashboard")

            db = Path(workspace) / "data" / "app.db"
            if not db.exists():
                raise AssertionError("the application database is not in its workspace")
        finally:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=5)
    return 0


if __name__ == "__main__":
    sys.exit(main())
