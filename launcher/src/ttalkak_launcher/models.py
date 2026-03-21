from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from pathlib import Path


class Stage(str, Enum):
    IDLE = "idle"
    DEVICE_DETECTED = "device_detected"
    RAM_BOOTING = "ram_booting"
    STORAGE_EXPOSED = "storage_exposed"
    FLASHING_OS = "flashing_os"
    PROVISIONING = "provisioning"
    VERIFYING = "verifying"
    REGISTERING = "registering"
    COMPLETED = "completed"
    FAILED = "failed"


@dataclass(frozen=True)
class LauncherConfig:
    rpiboot_exe: Path
    os_image: Path
    flash_tool: Path
    registration_log: Path
    repo_ref: str
    target_disk: str | None = None
    skip_rpiboot: bool = False
    skip_flash: bool = False
    max_wait_seconds: int = 120
    dry_run: bool = False


@dataclass(frozen=True)
class DeviceInfo:
    device_id: str
    name: str
    disk_path: str | None = None
