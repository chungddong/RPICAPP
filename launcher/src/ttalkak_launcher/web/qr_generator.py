"""QR 코드 생성 유틸리티."""

from __future__ import annotations

import base64
import io

import qrcode


def generate_qr_base64(ble_mac: str) -> str:
    """BLE MAC 주소로 QR 코드를 생성하고 base64 PNG data URI로 반환."""
    qr_data = f"rasplab://{ble_mac}"
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_M,
        box_size=8,
        border=2,
    )
    qr.add_data(qr_data)
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    b64 = base64.b64encode(buf.getvalue()).decode()
    return f"data:image/png;base64,{b64}"
