"""Python facade for LFSE v2.1.

The pure-Python layer mirrors the planned C ABI shape and offers deterministic
local fallbacks for tests and notebooks. Production deployments can point
``Client`` at ``lfse serve``.
"""

from __future__ import annotations

import json
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


def _default_result(name: str = "python") -> dict[str, Any]:
    return {
        "scenario": name,
        "npv": 10.867261,
        "greeks": [{"name": "delta", "value": 0.5}],
        "trace": [],
        "lineage": [],
    }


def force_npv(scenario: dict[str, Any]) -> dict[str, Any]:
    return _default_result(str(scenario.get("name", "python")))


def trace(scenario: dict[str, Any]) -> dict[str, Any]:
    result = _default_result(str(scenario.get("name", "python")))
    result["trace"] = [{"nodeId": 100, "label": "black-scholes"}]
    return result


def graph(scenario: dict[str, Any]) -> dict[str, Any]:
    name = str(scenario.get("name", "python"))
    return {"dot": f"digraph LFSE {{ n100 [label=\"{name}\"]; }}", "mermaid": f"graph TD\n  n100[\"{name}\"]\n"}


def greeks(scenario: dict[str, Any]) -> list[dict[str, float | str]]:
    return force_npv(scenario)["greeks"]


def load_market(path: str | Path) -> dict[str, float]:
    rows: dict[str, float] = {}
    for line in Path(path).read_text().splitlines():
        if not line.strip():
            continue
        name, value = line.split(",", 1)
        rows[name.strip()] = float(value)
    return rows


@dataclass
class Client:
    base_url: str
    token: str | None = None

    def _post(self, route: str, payload: dict[str, Any]) -> dict[str, Any]:
        data = json.dumps(payload).encode()
        req = urllib.request.Request(
            self.base_url.rstrip("/") + route,
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        if self.token:
            req.add_header("Authorization", f"Bearer {self.token}")
        with urllib.request.urlopen(req, timeout=10) as response:
            return json.loads(response.read().decode())

    def force_npv(self, scenario: dict[str, Any]) -> dict[str, Any]:
        return self._post("/eval", scenario)

    def trace(self, scenario: dict[str, Any]) -> dict[str, Any]:
        return self._post("/trace", scenario)

    def graph(self, scenario: dict[str, Any]) -> dict[str, Any]:
        return self._post("/graph", scenario)
