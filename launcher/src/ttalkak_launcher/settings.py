from __future__ import annotations

from pathlib import Path

from .models import LauncherConfig


def _first_existing(candidates: list[Path]) -> Path | None:
    for item in candidates:
        if item.exists():
            return item
    return None


def auto_config(project_root: Path, repo_ref: str, dry_run: bool) -> LauncherConfig:
    launcher_root = project_root / "launcher"
    assets = launcher_root / "assets"

    rpiboot = _first_existing(
        [
            assets / "rpiboot" / "rpiboot.exe",
            project_root / "tools" / "rpiboot" / "rpiboot.exe",
        ]
    ) or (assets / "rpiboot" / "rpiboot.exe")

    os_image = _first_existing(
        [
            assets / "os" / "ttlak-os.img",
            assets / "os" / "raspios.img",
        ]
    ) or (assets / "os" / "ttlak-os.img")

    flash_tool = _first_existing(
        [
            assets / "tools" / "rpi-imager-cli.exe",
            assets / "tools" / "rpi-imager-cli.cmd",
            Path(r"C:\Program Files\Raspberry Pi Imager\rpi-imager-cli.exe"),
            Path(r"C:\Program Files\Raspberry Pi Imager\rpi-imager-cli.cmd"),
            Path(r"C:\Program Files\Raspberry Pi Imager\rpi-imager.exe"),
            Path(r"C:\Program Files (x86)\Raspberry Pi Imager\rpi-imager-cli.cmd"),
        ]
    ) or (assets / "tools" / "rpi-imager-cli.exe")

    reg_log = launcher_root / "build" / "registration.jsonl"
    reg_log.parent.mkdir(parents=True, exist_ok=True)

    return LauncherConfig(
        rpiboot_exe=rpiboot,
        os_image=os_image,
        flash_tool=flash_tool,
        registration_log=reg_log,
        repo_ref=repo_ref,
        dry_run=dry_run,
    )
