from pathlib import Path

import lfse


def test_force_npv_shape():
    result = lfse.force_npv({"name": "unit"})
    assert result["scenario"] == "unit"
    assert result["npv"] > 0


def test_trace_and_graph_shape():
    assert lfse.trace({"name": "unit"})["trace"]
    assert "digraph" in lfse.graph({"name": "unit"})["dot"]


def test_load_market(tmp_path: Path):
    path = tmp_path / "market.csv"
    path.write_text("spot.ACME,101.5\nrate.usd,0.05\n")
    assert lfse.load_market(path)["spot.ACME"] == 101.5
