from __future__ import annotations

import subprocess

from .errors import ERR_VERIFY_FAILED, LauncherException


def run_smoke_qa(host: str, user: str, timeout: int = 30) -> None:
    cmd = [
        "ssh",
        f"{user}@{host}",
        "python3 - <<'PY'\nprint('qa-ok')\nPY",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, check=False)
    if result.returncode != 0 or "qa-ok" not in result.stdout:
        raise LauncherException(ERR_VERIFY_FAILED, result.stderr.strip() or result.stdout.strip())
