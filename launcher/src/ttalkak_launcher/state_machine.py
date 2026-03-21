from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime

from .models import Stage


@dataclass
class TransitionLog:
    at: datetime
    prev: Stage
    next: Stage
    note: str = ""


@dataclass
class LauncherStateMachine:
    current: Stage = Stage.IDLE
    history: list[TransitionLog] = field(default_factory=list)

    def move(self, next_stage: Stage, note: str = "") -> None:
        self.history.append(
            TransitionLog(
                at=datetime.utcnow(),
                prev=self.current,
                next=next_stage,
                note=note,
            )
        )
        self.current = next_stage
