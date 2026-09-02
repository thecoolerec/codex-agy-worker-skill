from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_required_files() -> None:
    required = [
        "SKILL.md",
        "AGENTS.snippet.md",
        "scripts/invoke-agy.ps1",
        "scripts/install.ps1",
        "schemas/worker-result.schema.json",
        "schemas/task-meta.schema.json",
        "templates/task-contract.md",
        "templates/worker-preamble.md",
        "evals/README.md",
        "evals/cases.jsonl",
    ]
    missing = [p for p in required if not (ROOT / p).is_file()]
    assert not missing, f"missing files: {missing}"


def test_skill_frontmatter() -> None:
    text = (ROOT / "SKILL.md").read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    assert match, "SKILL.md must start with YAML frontmatter"
    frontmatter = match.group(1)
    assert re.search(r"(?m)^name:\s*agy-worker\s*$", frontmatter)
    assert re.search(r"(?m)^description:\s*.+$", frontmatter)


def test_worker_schema_is_valid_json_and_closed() -> None:
    schema = json.loads((ROOT / "schemas/worker-result.schema.json").read_text(encoding="utf-8"))
    assert schema["type"] == "object"
    assert schema["additionalProperties"] is False
    required = set(schema["required"])
    assert {"status", "summary", "files_changed", "blocker_type", "observed_state", "requested_decision"} <= required
    assert schema["properties"]["status"]["enum"] == ["SUCCESS", "BLOCKED", "FAILED"]


def test_task_meta_schema_is_v2_and_closed() -> None:
    schema = json.loads((ROOT / "schemas/task-meta.schema.json").read_text(encoding="utf-8"))
    assert schema["type"] == "object"
    assert schema["additionalProperties"] is False
    assert schema["properties"]["contract_version"]["const"] == "2"
    assert {"contract_version", "task_id", "task_class", "scope", "verification"} <= set(schema["required"])
    assert schema["properties"]["scope"]["properties"]["allow"]["minItems"] == 1


def test_contract_has_machine_readable_meta() -> None:
    text = (ROOT / "templates/task-contract.md").read_text(encoding="utf-8")
    match = re.search(r"(?s)<!--\s*AGY_META\s*(\{.*?\})\s*AGY_META\s*-->", text)
    assert match, "task contract must include AGY_META JSON"
    meta = json.loads(match.group(1))
    assert meta["contract_version"] == "2"
    assert meta["scope"]["allow"]


def test_contract_semantic_sections() -> None:
    text = (ROOT / "templates/task-contract.md").read_text(encoding="utf-8")
    for heading in [
        "OBJECTIVE", "CONFIRMED_FACTS", "ASSUMPTIONS", "UNKNOWNS", "SCOPE",
        "DECISIONS", "CONSTRAINTS", "MUST_NOT", "REQUIRED_ACTIONS",
        "IMPLEMENTATION_HINTS", "ACCEPTANCE_CRITERIA", "STOP_CONDITIONS",
    ]:
        assert f"## {heading}" in text


def test_eval_manifest_is_jsonl() -> None:
    lines = [line for line in (ROOT / "evals/cases.jsonl").read_text(encoding="utf-8").splitlines() if line.strip()]
    assert len(lines) >= 5
    rows = [json.loads(line) for line in lines]
    assert any(row["delegate_expected"] is True for row in rows)
    assert any(row["delegate_expected"] is False for row in rows)
