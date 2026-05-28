# LFSE Python Cookbook

Install locally:

```bash
python -m pip install -e python
```

Run a scenario:

```python
import lfse

result = lfse.force_npv({"name": "demo"})
print(result["npv"])
```

Load CSV-like market data:

```python
market = lfse.load_market("test/fixtures/market_data.csv")
```
