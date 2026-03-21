"""웹 런처 API 라우트."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from .device_discovery import check_pi_connected, configure_rndis_adapter, fetch_device_info
from .qr_generator import generate_qr_base64

router = APIRouter()

REGISTRATION_LOG = Path(__file__).resolve().parents[4] / "build" / "registration.jsonl"


class RegisterRequest(BaseModel):
    serial: str
    ble_mac: str
    ble_name: str
    hostname: str


@router.get("/status")
async def get_status():
    """Pi 연결 상태 확인."""
    connected = await check_pi_connected()
    return {"pi_connected": connected, "pi_ip": "192.168.7.2"}


@router.get("/device-info")
async def get_device_info():
    """Pi에서 기기 정보 조회 + QR 코드 생성."""
    info = await fetch_device_info()
    if info is None:
        raise HTTPException(status_code=503, detail="Pi에 연결할 수 없습니다")
    qr_base64 = generate_qr_base64(info.get("ble_mac", "unknown"))
    return {
        **info,
        "qr_data": f"rasplab://{info.get('ble_mac', 'unknown')}",
        "qr_image": qr_base64,
    }


@router.post("/register", status_code=201)
async def register_device(req: RegisterRequest):
    """기기 등록 → registration.jsonl에 저장."""
    entry = {
        "serial": req.serial,
        "ble_mac": req.ble_mac,
        "ble_name": req.ble_name,
        "hostname": req.hostname,
        "qr_data": f"rasplab://{req.ble_mac}",
        "registered_at": datetime.now(timezone.utc).isoformat(),
    }
    REGISTRATION_LOG.parent.mkdir(parents=True, exist_ok=True)
    with REGISTRATION_LOG.open("a", encoding="utf-8") as fp:
        fp.write(json.dumps(entry, ensure_ascii=False) + "\n")
    return entry


@router.get("/devices")
async def list_devices():
    """등록된 기기 목록 반환."""
    if not REGISTRATION_LOG.exists():
        return []
    devices = []
    with REGISTRATION_LOG.open("r", encoding="utf-8") as fp:
        for line in fp:
            line = line.strip()
            if line:
                try:
                    devices.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
    return devices


@router.post("/setup-network")
async def setup_network():
    """Windows RNDIS 어댑터 IP 자동 설정."""
    ok = configure_rndis_adapter()
    if not ok:
        raise HTTPException(status_code=500, detail="RNDIS 어댑터를 찾을 수 없거나 설정에 실패했습니다")
    return {"status": "ok", "pc_ip": "192.168.7.1"}
