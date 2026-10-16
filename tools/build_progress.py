"""Build the project dashboard from docs/progress.json; no third-party packages."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
data = json.loads((ROOT / "docs/progress.json").read_text())
template = (ROOT / "tools/progress_template.html").read_text()
payload = json.dumps(data, ensure_ascii=False).replace("<", "\\u003c")
target = ROOT / "docs/progress.html"
target.write_text(template.replace("__PROGRESS_DATA__", payload))
print(target)
