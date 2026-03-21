from __future__ import annotations

import argparse
from pathlib import Path

from .models import LauncherConfig
from .multiflash import run_multi
from .pipeline import LauncherPipeline
from .settings import auto_config


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="ttl", description="딸깍 런처 CLI")
    parser.add_argument("--project-root", default=".", help="workspace root path")
    sub = parser.add_subparsers(dest="command", required=True)

    serve = sub.add_parser("serve", help="web dashboard for device provisioning")
    serve.add_argument("--port", type=int, default=8000, help="web server port (default: 8000)")
    serve.add_argument("--no-browser", action="store_true", help="do not open browser automatically")

    run = sub.add_parser("run", help="single device provisioning")
    run.add_argument("--rpiboot", help="rpiboot.exe path (optional, auto-discover by default)")
    run.add_argument("--image", help="OS image .img path (optional, auto-discover by default)")
    run.add_argument("--flash-tool", help="rpi-imager-cli path (optional, auto-discover by default)")
    run.add_argument("--disk", help="target disk spec (e.g. F: or \\\\.\\PhysicalDrive3)")
    run.add_argument("--ref", default="main", help="Git ref (main/develop/tag)")
    run.add_argument("--skip-flash", action="store_true", help="Skip flashing step (use when image is already written)")
    run.add_argument("--dry-run", action="store_true", help="Skip boot/flash and test flow only")

    multi = sub.add_parser("multi", help="multi device provisioning")
    multi.add_argument("--slots", type=int, default=2, help="number of concurrent slots")
    multi.add_argument("--rpiboot", help="rpiboot.exe path (optional, auto-discover by default)")
    multi.add_argument("--image", help="OS image .img path (optional, auto-discover by default)")
    multi.add_argument("--flash-tool", help="rpi-imager-cli path (optional, auto-discover by default)")
    multi.add_argument("--disk", help="target disk spec (single disk test only)")
    multi.add_argument("--ref", default="main", help="Git ref (main/develop/tag)")
    multi.add_argument("--skip-flash", action="store_true", help="Skip flashing step (use when image is already written)")
    multi.add_argument("--dry-run", action="store_true", help="Skip boot/flash and test flow only")

    return parser


def main() -> int:
    args = build_parser().parse_args()
    project_root = Path(args.project_root).resolve()

    if args.command == "serve":
        import webbrowser
        import uvicorn
        from .web.app import app

        port = args.port
        if not args.no_browser:
            import threading
            threading.Timer(1.5, lambda: webbrowser.open(f"http://localhost:{port}")).start()
        print(f"TTalkak Launcher 웹 대시보드: http://localhost:{port}")
        uvicorn.run(app, host="0.0.0.0", port=port, log_level="info")
        return 0

    base_cfg = auto_config(project_root, repo_ref=args.ref, dry_run=args.dry_run)

    def with_overrides(cfg: LauncherConfig) -> LauncherConfig:
        return LauncherConfig(
            rpiboot_exe=Path(args.rpiboot).resolve() if getattr(args, "rpiboot", None) else cfg.rpiboot_exe,
            os_image=Path(args.image).resolve() if getattr(args, "image", None) else cfg.os_image,
            flash_tool=Path(args.flash_tool).resolve() if getattr(args, "flash_tool", None) else cfg.flash_tool,
            registration_log=cfg.registration_log,
            repo_ref=cfg.repo_ref,
            target_disk=getattr(args, "disk", None),
            skip_rpiboot=bool(getattr(args, "disk", None)),
            skip_flash=bool(getattr(args, "skip_flash", False)),
            max_wait_seconds=cfg.max_wait_seconds,
            dry_run=cfg.dry_run,
        )

    if args.command == "run":
        config = with_overrides(base_cfg)
        pipeline = LauncherPipeline(config)
        sm = pipeline.run()
        for log in sm.history:
            print(f"[{log.at.isoformat()}] {log.prev.value} -> {log.next.value} {log.note}".rstrip())
        return 0

    if args.command == "multi":
        configs = [
            with_overrides(base_cfg)
            for _ in range(args.slots)
        ]
        results = run_multi(configs, max_workers=args.slots)
        for item in results:
            status = "OK" if item.success else f"FAIL ({item.error})"
            print(f"slot-{item.slot}: {status}")
        return 0 if all(r.success for r in results) else 1

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
