"""Build the item search catalog from an RS3 cache item-index JSON file."""
import argparse
import json
from pathlib import Path
import re

parser = argparse.ArgumentParser()
parser.add_argument("source", type=Path)
args = parser.parse_args()
records = json.loads(args.source.read_text(encoding="utf-8"))
items = {}
for record in records:
    item_id = record["id"]
    assert isinstance(item_id, int) and 0 <= item_id <= 2147483647
    name = re.sub(r"<[^>]*>", "", record["name"]).strip()
    assert not any(ord(char) < 32 for char in name)
    if name:
        assert item_id not in items, f"Duplicate item ID {item_id}"
        items[item_id] = name
output = Path(__file__).resolve().parents[1] / "lib/item_data.lua"
lines = ["-- Item names from RS3 cache 2736, build 950, captured 2026-10-12.", "return {"]
for item_id, name in sorted(items.items()):
    lines.append(f"    {item_id},{json.dumps(name, ensure_ascii=False)},")
lines.append("}")
output.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Wrote {len(items)} item names to {output}")
