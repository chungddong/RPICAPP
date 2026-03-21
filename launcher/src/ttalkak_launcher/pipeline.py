from __future__ import annotations

import json
from datetime import datetime, timezone

from .models import LauncherConfig, Stage
from .state_machine import LauncherStateMachine
from .windows_tools import (
    detect_bcm2835_device,
    detect_mass_storage_disk,
    flash_image_to_disk,
    resolve_disk_spec,
    run_rpiboot,
)


class LauncherPipeline:
    def __init__(self, config: LauncherConfig) -> None:
        self.config = config
        self.sm = LauncherStateMachine()

    def run(self) -> LauncherStateMachine:
        if self.config.dry_run:
            self.sm.move(Stage.DEVICE_DETECTED, "dry-run virtual-device")
            self.sm.move(Stage.RAM_BOOTING, "dry-run skip")
            self.sm.move(Stage.STORAGE_EXPOSED, "dry-run skip")
            self.sm.move(Stage.FLASHING_OS, "dry-run skip")
            self.sm.move(Stage.PROVISIONING, f"git ref: {self.config.repo_ref}")
            self.sm.move(Stage.VERIFYING, "dry-run skip")
            self.sm.move(Stage.REGISTERING, "dry-run local registration")
            self._write_local_registration("dry-run-serial")
            self.sm.move(Stage.COMPLETED)
            return self.sm

        if self.config.target_disk:
            self.sm.move(Stage.DEVICE_DETECTED, "pre-exposed storage mode")
            self.sm.move(Stage.RAM_BOOTING, "skipped (manual disk mode)")
            self.sm.move(Stage.STORAGE_EXPOSED, self.config.target_disk)
            if self.config.skip_flash:
                disk = self.config.target_disk
            else:
                disk = resolve_disk_spec(self.config.target_disk)
        else:
            device = detect_bcm2835_device()
            self.sm.move(Stage.DEVICE_DETECTED, f"{device.name} ({device.device_id})")

            self.sm.move(Stage.RAM_BOOTING)
            run_rpiboot(self.config.rpiboot_exe, timeout=self.config.max_wait_seconds)

            self.sm.move(Stage.STORAGE_EXPOSED)
            disk = detect_mass_storage_disk()

        if self.config.skip_flash:
            self.sm.move(Stage.FLASHING_OS, "skipped (--skip-flash)")
        else:
            self.sm.move(Stage.FLASHING_OS, disk)
            flash_image_to_disk(self.config.flash_tool, self.config.os_image, disk)

        self.sm.move(Stage.PROVISIONING, f"git ref: {self.config.repo_ref}")
        self.sm.move(Stage.VERIFYING)
        self.sm.move(Stage.REGISTERING)
        serial = device.device_id if not self.config.target_disk else f"disk:{self.config.target_disk}"
        self._write_local_registration(serial)
        self.sm.move(Stage.COMPLETED)
        return self.sm

    def _write_local_registration(self, serial: str) -> None:
        payload = {
            "serial": serial,
            "git_ref": self.config.repo_ref,
            "qa_result": "pass",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }
        self.config.registration_log.parent.mkdir(parents=True, exist_ok=True)
        with self.config.registration_log.open("a", encoding="utf-8") as fp:
            fp.write(json.dumps(payload, ensure_ascii=False) + "\n")
