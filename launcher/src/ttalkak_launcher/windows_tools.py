from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path

from .errors import (
    ERR_DEVICE_NOT_FOUND,
    ERR_FLASH_FAILED,
    ERR_RPIBOOT_FAILED,
    ERR_STORAGE_NOT_EXPOSED,
    LauncherException,
)
from .models import DeviceInfo


def _run(cmd: list[str], timeout: int = 120) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=timeout,
        check=False,
    )


def _wrap_tool_cmd(tool: Path, args: list[str]) -> list[str]:
    tool_path = str(tool)
    if tool.suffix.lower() in {".cmd", ".bat"}:
        return ["cmd", "/c", tool_path, *args]
    return [tool_path, *args]


def _run_flash_candidates(candidates: list[list[str]], timeout: int) -> tuple[bool, str]:
    errors: list[str] = []
    for cmd in candidates:
        result = _run(cmd, timeout=timeout)
        if result.returncode == 0:
            return True, result.stdout.strip()
        errors.append(f"$ {' '.join(cmd)}\n{result.stderr.strip() or result.stdout.strip()}")
    return False, "\n\n".join(errors)


def _read_prefix(path: str, size: int) -> bytes:
    with open(path, "rb", buffering=0) as fp:
        return fp.read(size)


def _verify_flash_written(os_image: Path, physical_drive: str) -> tuple[bool, str]:
    check_size = 1024 * 1024  # 1 MiB
    try:
        image_prefix = _read_prefix(str(os_image), check_size)
        disk_prefix = _read_prefix(physical_drive, check_size)
    except Exception as exc:  # noqa: BLE001
        return False, f"verification read failed: {exc}"

    if not image_prefix or not disk_prefix:
        return False, "verification read returned empty data"

    if image_prefix != disk_prefix:
        return False, "disk header mismatch (flash may not have been applied)"

    return True, "verified"


def detect_bcm2835_device() -> DeviceInfo:
    ps = (
        "Get-PnpDevice | "
        "Where-Object { $_.FriendlyName -match 'BCM2835|RPi|Raspberry' } | "
        "Select-Object -First 1 -Property InstanceId,FriendlyName | ConvertTo-Json"
    )
    result = _run(["powershell", "-NoProfile", "-Command", ps], timeout=30)
    if result.returncode != 0 or not result.stdout.strip():
        raise LauncherException(ERR_DEVICE_NOT_FOUND, result.stderr.strip())

    try:
        payload = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise LauncherException(ERR_DEVICE_NOT_FOUND, str(exc)) from exc

    return DeviceInfo(
        device_id=payload.get("InstanceId", "unknown"),
        name=payload.get("FriendlyName", "unknown"),
    )


def run_rpiboot(rpiboot_exe: Path, timeout: int = 120) -> None:
    result = _run([str(rpiboot_exe)], timeout=timeout)
    if result.returncode != 0:
        raise LauncherException(ERR_RPIBOOT_FAILED, result.stderr.strip())


def detect_mass_storage_disk() -> str:
    ps = (
        "Get-Disk | "
        "Where-Object { $_.BusType -in @('USB','SD') -and $_.PartitionStyle -ne 'RAW' -or $_.PartitionStyle -eq 'RAW' } | "
        "Sort-Object Number -Descending | Select-Object -First 1 -ExpandProperty Number"
    )
    result = _run(["powershell", "-NoProfile", "-Command", ps], timeout=20)
    if result.returncode != 0 or not result.stdout.strip():
        raise LauncherException(ERR_STORAGE_NOT_EXPOSED, result.stderr.strip())
    disk_num = result.stdout.strip()
    return f"\\\\.\\PhysicalDrive{disk_num}"


def resolve_disk_spec(spec: str) -> str:
    value = spec.strip()
    if re.match(r"^\\\\\.\\PhysicalDrive\d+$", value, flags=re.IGNORECASE):
        return value

    if re.match(r"^[A-Za-z]:$", value):
        letter = value[0].upper()
        ps = (
            f"$p=Get-Partition -DriveLetter '{letter}' -ErrorAction Stop;"
            "$d=Get-Disk -Number $p.DiskNumber -ErrorAction Stop;"
            "Write-Output $d.Number"
        )
        result = _run(["powershell", "-NoProfile", "-Command", ps], timeout=20)
        if result.returncode != 0 or not result.stdout.strip():
            raise LauncherException(ERR_STORAGE_NOT_EXPOSED, result.stderr.strip() or result.stdout.strip())
        disk_num = result.stdout.strip().splitlines()[-1].strip()
        if not disk_num.isdigit():
            raise LauncherException(ERR_STORAGE_NOT_EXPOSED, f"invalid disk number from drive {value}: {disk_num}")
        return f"\\\\.\\PhysicalDrive{disk_num}"

    if value.isdigit():
        return f"\\\\.\\PhysicalDrive{value}"

    raise LauncherException(ERR_STORAGE_NOT_EXPOSED, f"unsupported disk spec: {spec}")


def flash_image_to_disk(
    flash_tool: Path,
    os_image: Path,
    physical_drive: str,
    timeout: int = 1800,
) -> None:
    if not flash_tool.exists():
        raise LauncherException(ERR_FLASH_FAILED, f"flash tool not found: {flash_tool}")

    if not os_image.exists():
        raise LauncherException(ERR_FLASH_FAILED, f"OS image not found: {os_image}")

    image = str(os_image)
    disk = physical_drive

    candidates = [
        _wrap_tool_cmd(flash_tool, ["--cli", image, disk]),
        _wrap_tool_cmd(flash_tool, ["--disable-telemetry", "--cli", image, disk]),
        _wrap_tool_cmd(flash_tool, ["burn", image, disk]),
    ]

    ok, output = _run_flash_candidates(candidates, timeout=timeout)
    if not ok:
        raise LauncherException(ERR_FLASH_FAILED, output)

    verified, reason = _verify_flash_written(os_image, physical_drive)
    if not verified:
        raise LauncherException(ERR_FLASH_FAILED, reason)
