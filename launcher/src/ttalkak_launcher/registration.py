from __future__ import annotations

import json
import urllib.request
from dataclasses import dataclass, asdict

from .errors import ERR_REGISTER_FAILED, LauncherException


@dataclass
class RegistrationRecord:
    serial: str
    model: str
    production_date: str
    git_ref: str
    build_version: str
    qa_result: str
    notes: str = ""


def register_device(api_url: str, token: str, record: RegistrationRecord) -> None:
    body = json.dumps(asdict(record)).encode("utf-8")
    req = urllib.request.Request(
        api_url,
        data=body,
        method="POST",
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            if resp.status >= 300:
                raise LauncherException(ERR_REGISTER_FAILED, f"http {resp.status}")
    except Exception as exc:  # noqa: BLE001
        raise LauncherException(ERR_REGISTER_FAILED, str(exc)) from exc
