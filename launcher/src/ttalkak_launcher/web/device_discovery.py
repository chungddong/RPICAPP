"""Pi 연결 감지 및 RNDIS 네트워크 자동 설정."""

from __future__ import annotations

import subprocess

import httpx

PI_IP = "192.168.7.2"
PI_API_PORT = 5000
PI_API_URL = f"http://{PI_IP}:{PI_API_PORT}/device-info"
PC_RNDIS_IP = "192.168.7.1"


async def check_pi_connected() -> bool:
    """Pi가 RNDIS로 연결되어 있는지 ping으로 확인."""
    try:
        result = subprocess.run(
            ["ping", "-n", "1", "-w", "1000", PI_IP],
            capture_output=True,
            timeout=5,
        )
        return result.returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False


async def fetch_device_info() -> dict | None:
    """Pi의 Device Info API에서 기기 정보를 가져옴."""
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            resp = await client.get(PI_API_URL)
            resp.raise_for_status()
            return resp.json()
    except (httpx.HTTPError, httpx.TimeoutException, Exception):
        return None


def configure_rndis_adapter() -> bool:
    """Windows에서 RNDIS 어댑터에 고정 IP를 자동 설정."""
    ps_script = f"""
    $adapter = Get-NetAdapter | Where-Object {{
        $_.InterfaceDescription -match 'RNDIS|Linux USB Ethernet|USB Ethernet'
    }} | Select-Object -First 1

    if (-not $adapter) {{ exit 1 }}

    $existing = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {{ $_.IPAddress -eq '{PC_RNDIS_IP}' }}

    if ($existing) {{ exit 0 }}

    # 기존 IP 제거 후 새로 설정
    Remove-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceIndex $adapter.ifIndex -IPAddress '{PC_RNDIS_IP}' -PrefixLength 24 -ErrorAction Stop
    exit 0
    """
    try:
        result = subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps_script],
            capture_output=True,
            text=True,
            timeout=15,
        )
        return result.returncode == 0
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False
