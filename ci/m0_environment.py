"""仅采集 M0 云端环境证据，不安装工具、不启动模拟器或调用翻译服务。"""

import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys


def collect_environment(run=None, system=None, environ=None):
    """逐项检查真实运行环境；失败保留证据，不回退其他机器或工具版本。"""
    run = run or subprocess.run
    system = system or platform.system()
    environ = os.environ if environ is None else environ
    report = {"status": "FAIL", "system": system, "checks": {}, "errors": []}
    if system != "Darwin":
        report["errors"].append("必须在 macOS 云端运行，Windows 本地检查不能替代环境验收")
        return report

    # 仅允许开发分支；平台环境变量缺失时同样停止，避免错误来源通过验收。
    if environ.get("CM_BRANCH") != "dev":
        report["errors"].append("CM_BRANCH 必须为 dev")
        return report
    commands = {
        "commit": ["git", "rev-parse", "HEAD"],
        "xcode": ["xcodebuild", "-version"],
        "swift": ["xcrun", "swift", "--version"],
        "simulator_sdk": ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-version"],
        "simulators": ["xcrun", "simctl", "list", "devices", "available", "--json"],
        "package": ["swift", "package", "dump-package"],
    }
    for name, command in commands.items():
        try:
            result = run(command, capture_output=True, text=True, timeout=45, check=False)
            report["checks"][name] = {
                "exit_code": result.returncode,
                "stdout": result.stdout.strip(),
                "stderr": result.stderr.strip(),
            }
            if result.returncode:
                report["errors"].append(f"{name} 命令执行失败")
                continue
            if name == "xcode" and not result.stdout.startswith("Xcode 16.4\n"):
                report["errors"].append("Xcode 版本与固定的 16.4 不一致")
            if name == "commit":
                # 同时记录实际提交并核对平台声明，防止选错提交。
                if result.stdout.strip() != environ.get("CM_COMMIT"):
                    report["errors"].append("实际提交与 CM_COMMIT 不一致")
            if name == "simulators":
                devices = json.loads(result.stdout)["devices"]
                if not any(
                    rows for runtime, rows in devices.items() if ".iOS-" in runtime
                ):
                    report["errors"].append("缺少可用 iOS 模拟器设备")
            if name == "package":
                if json.loads(result.stdout).get("name") != "AIInterpreterIOS":
                    report["errors"].append("Swift 包名称不符")
        except (OSError, subprocess.TimeoutExpired, ValueError, KeyError) as error:
            report["errors"].append(f"{name}: {type(error).__name__}")
    # XcodeGen 只记录是否预装；缺失时不能宣称工程生成通过，也不在首轮安装。
    report["xcodegen_preinstalled"] = shutil.which("xcodegen") is not None
    report["status"] = "PASS" if not report["errors"] else "FAIL"
    return report


def main():
    """保存受限证据文件，任何失败返回非零退出码，不导出环境变量或凭据。"""
    report = collect_environment()
    output = Path("build/m0/environment.json")
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"status": report["status"], "errors": report["errors"]}, ensure_ascii=False))
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
