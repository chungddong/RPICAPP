"""FastAPI 웹 런처 애플리케이션."""

from __future__ import annotations

from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from .api import router

app = FastAPI(title="TTalkak Launcher", version="0.2.0")
app.include_router(router, prefix="/api")

static_dir = Path(__file__).parent / "static"
app.mount("/", StaticFiles(directory=str(static_dir), html=True), name="static")
