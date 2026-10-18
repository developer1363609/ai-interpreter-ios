"""Windows 可运行的配置与环境采集器测试，不冒充 macOS 实机结果。"""

import json
from pathlib import Path
import subprocess
import unittest

import yaml

from m0_environment import collect_environment


class M0Tests(unittest.TestCase):
    """检查预算边界及环境失败关闭行为。"""

    def test_configuration(self):
        """只允许一个手动 M2 工作流，禁止隐式发布及自动触发。"""
        document = yaml.safe_load(Path("codemagic.yaml").read_text(encoding="utf-8"))
        self.assertEqual(set(document), {"workflows"})
        self.assertEqual(set(document["workflows"]), {"m0-environment"})
        workflow = document["workflows"]["m0-environment"]
        self.assertEqual(set(workflow), {
            "name", "instance_type", "max_build_duration", "environment", "scripts", "artifacts"
        })
        self.assertEqual(workflow["instance_type"], "mac_mini_m2")
        self.assertEqual(workflow["max_build_duration"], 10)
        self.assertEqual(workflow["environment"], {"xcode": "16.4"})
        self.assertEqual(workflow["scripts"], [{
            "name": "核验提交与 macOS 开发环境", "script": "python3 ci/m0_environment.py"
        }])
        self.assertEqual(workflow["artifacts"], ["build/m0/environment.json"])

    def collect(self, replacements=None, branch="dev", system="Darwin"):
        """注入命令结果，不在 Windows 执行 Apple 工具。"""
        results = {
            "git": "a" * 40,
            "xcodebuild": "Xcode 16.4\nBuild version 16F6",
            "swift": json.dumps({"name": "AIInterpreterIOS"}),
            "--version": "Apple Swift version 6.1",
            "--show-sdk-version": "18.5",
            "--json": json.dumps({"devices": {"com.apple.CoreSimulator.SimRuntime.iOS-18-5": [{"name": "iPhone"}]}}),
        }
        results.update(replacements or {})

        def run(command, **kwargs):
            """按照命令关键字返回测试输出或明确的进程错误。"""
            key = command[-1] if command[0] == "xcrun" else command[0]
            value = results[key]
            if isinstance(value, Exception):
                raise value
            if isinstance(value, int):
                return subprocess.CompletedProcess(command, value, "", "测试命令失败")
            return subprocess.CompletedProcess(command, 0, value, "")

        return collect_environment(run=run, system=system, environ={
            "CM_BRANCH": branch, "CM_COMMIT": "a" * 40
        })

    def test_success(self):
        """所有预检条件满足时才返回通过。"""
        self.assertEqual(self.collect()["status"], "PASS")

    def test_reject_platform_and_branch(self):
        """拒绝 Windows 或错误分支。"""
        self.assertEqual(self.collect(system="Windows")["status"], "FAIL")
        self.assertEqual(self.collect(branch="main")["status"], "FAIL")

    def test_mismatch_and_missing_simulator(self):
        """错误版本、提交及缺少模拟器均应失败。"""
        for replacement in [
            {"git": "b" * 40}, {"xcodebuild": "Xcode 26.0"},
            {"--json": '{"devices": {}}'}, {"swift": '{"name": "other"}'},
        ]:
            with self.subTest(replacement=replacement):
                self.assertEqual(self.collect(replacement)["status"], "FAIL")

    def test_command_errors(self):
        """缺失工具、超时或无效 JSON 不得吞掉失败。"""
        for value in [OSError(), subprocess.TimeoutExpired("xcrun", 45), "invalid", 1]:
            with self.subTest(value=type(value).__name__):
                self.assertEqual(self.collect({"--json": value})["status"], "FAIL")


if __name__ == "__main__":
    unittest.main()
