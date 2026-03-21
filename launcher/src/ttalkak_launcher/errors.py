from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class LauncherErrorCode:
    code: str
    message: str


ERR_DEVICE_NOT_FOUND = LauncherErrorCode("E001", "BCM2835 boot device not found")
ERR_RPIBOOT_FAILED = LauncherErrorCode("E002", "rpiboot failed")
ERR_STORAGE_NOT_EXPOSED = LauncherErrorCode("E003", "mass storage not exposed")
ERR_FLASH_FAILED = LauncherErrorCode("E004", "os image flashing failed")
ERR_PROVISION_FAILED = LauncherErrorCode("E005", "firstboot provisioning failed")
ERR_VERIFY_FAILED = LauncherErrorCode("E006", "qa verification failed")
ERR_REGISTER_FAILED = LauncherErrorCode("E007", "device registration failed")


class LauncherException(RuntimeError):
    def __init__(self, err: LauncherErrorCode, detail: str = "") -> None:
        suffix = f" | {detail}" if detail else ""
        super().__init__(f"[{err.code}] {err.message}{suffix}")
        self.err = err
        self.detail = detail
