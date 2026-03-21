from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass

from .models import LauncherConfig
from .pipeline import LauncherPipeline


@dataclass
class SlotResult:
    slot: int
    success: bool
    error: str = ""


def run_multi(slots: list[LauncherConfig], max_workers: int = 4) -> list[SlotResult]:
    results: list[SlotResult] = []

    with ThreadPoolExecutor(max_workers=max_workers) as pool:
        fut_map = {
            pool.submit(LauncherPipeline(cfg).run): idx
            for idx, cfg in enumerate(slots, start=1)
        }
        for fut in as_completed(fut_map):
            slot = fut_map[fut]
            try:
                fut.result()
                results.append(SlotResult(slot=slot, success=True))
            except Exception as exc:  # noqa: BLE001
                results.append(SlotResult(slot=slot, success=False, error=str(exc)))

    return sorted(results, key=lambda r: r.slot)
