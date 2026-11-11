"""Exercise the real hook adapter against temporary repositories and check commands."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SOURCE = Path(os.environ.get("LUA_EDIT_HOOK", Path(__file__).resolve().parents[1] / ".agents/hooks/lua-check.py"))


class LuaEditHookTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.root = self.base / "config with spaces"
        self.dispatch = self.base / "plugins"
        self.log = self.base / "calls"
        self.make_repo(self.root)
        self.hook = self.root / ".agents/hooks/lua-check.py"
        self.hook.parent.mkdir(parents=True)
        shutil.copyfile(SOURCE, self.hook)

    def make_repo(self, root, exit_code=0):
        (root / "tests").mkdir(parents=True)
        (root / "tests/check-edit.sh").write_text(
            'test -z "${NVIM-}${NVIM_LISTEN_ADDRESS-}" || exit 42\n'
            'printf "%s\\n" "$PWD" >> "$HOOK_CALL_LOG"\n'
            f'echo "failure from {root.name}" >&2\nexit {exit_code}\n'
        )

    def run_hook(self, tool_input, *, cwd=None, response=None, dispatch=False, raw=None):
        event = {"cwd": str(cwd or self.root), "tool_input": tool_input}
        if response is not None:
            event["tool_response"] = response
        env = dict(os.environ, HOOK_CALL_LOG=str(self.log), NVIM="parent.sock", NVIM_LISTEN_ADDRESS="parent.sock")
        command = [sys.executable, "-B", str(self.hook)]
        if dispatch:
            command.append(str(self.dispatch))
        return subprocess.run(command, input=raw if raw is not None else json.dumps(event), text=True, capture_output=True, env=env)

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def assert_success(self, result, expected):
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")
        self.assertEqual(result.stderr, "")
        self.assertEqual(self.calls(), [str(path) for path in expected])

    def test_claude_write(self):
        self.assert_success(self.run_hook({"file_path": str(self.root / "init.lua")}), [self.root])

    def test_response_file_path(self):
        self.assert_success(self.run_hook({}, response={"filePath": str(self.root / "init.lua")}), [self.root])

    def test_codex_multi_file_patch_checks_repo_once(self):
        patch = "*** Begin Patch\n*** Add File: lua/a.lua\n+return 1\n*** Update File: init.lua\n*** Delete File: lua/b.lua\n*** End Patch"
        self.assert_success(self.run_hook({"command": patch}), [self.root])

    def test_codex_raw_patch(self):
        self.assert_success(self.run_hook("*** Add File: init.lua\n+return 1"), [self.root])

    def test_relative_path_from_subdirectory(self):
        cwd = self.root / "lua"
        cwd.mkdir()
        self.assert_success(self.run_hook({"command": "*** Update File: ../init.lua"}, cwd=cwd), [self.root])

    def test_move_into_lua_checks_destination(self):
        self.assert_success(self.run_hook({"command": "*** Update File: scratch.txt\n*** Move to: moved.lua"}), [self.root])

    def test_non_lua_and_external_files_are_ignored(self):
        patch = f"*** Update File: readme.md\n*** Update File: {self.base / 'elsewhere/file.lua'}"
        self.assert_success(self.run_hook({"command": patch}), [])

    def test_prefix_collision_is_not_owned(self):
        self.assert_success(self.run_hook({"file_path": str(self.root) + "-other/init.lua"}), [])

    def test_dispatch_checks_every_affected_repo_once(self):
        sibling = self.dispatch / "sibling.nvim"
        self.make_repo(sibling)
        patch = f"*** Update File: init.lua\n*** Update File: {sibling / 'a.lua'}\n*** Delete File: {sibling / 'b.lua'}"
        self.assert_success(self.run_hook({"command": patch}, dispatch=True), [self.root, sibling])

    def test_failure_does_not_skip_later_repos(self):
        (self.root / "tests/check-edit.sh").write_text('echo "broken suite" >&2\nexit 1\n')
        sibling = self.dispatch / "sibling.nvim"
        self.make_repo(sibling)
        patch = f"*** Update File: init.lua\n*** Update File: {sibling / 'a.lua'}"
        result = self.run_hook({"command": patch}, dispatch=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("broken suite", result.stderr)
        self.assertEqual(self.calls(), [str(sibling)])

    def test_missing_sibling_check_fails_loudly(self):
        result = self.run_hook({"file_path": str(self.dispatch / "unchecked.nvim/a.lua")}, dispatch=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("NOT verified", result.stderr)

    def test_codex_launcher_uses_shared_directory_list(self):
        source = Path(__file__).resolve().parents[1] / "scripts/codex"
        launcher = self.root / "scripts/codex"
        launcher.parent.mkdir()
        shutil.copyfile(source, launcher)
        (self.root / ".claude").mkdir()
        directories = [str(self.dispatch / "first.nvim"), "~/p/second.nvim"]
        (self.root / ".claude/settings.json").write_text(json.dumps({"permissions": {"additionalDirectories": directories}}))
        fake = self.base / "bin/codex"
        fake.parent.mkdir()
        fake.write_text(f"#!{sys.executable}\nimport json, sys\nprint(json.dumps(sys.argv[1:]))\n")
        fake.chmod(0o755)
        result = subprocess.run([sys.executable, str(launcher), "--sandbox", "workspace-write"], env=dict(os.environ, PATH=str(fake.parent)), capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), ["--cd", str(self.root), "--add-dir", directories[0], "--add-dir", str(Path(directories[1]).expanduser()), "--sandbox", "workspace-write"])

    def test_invalid_event_fails_loudly(self):
        result = self.run_hook({}, raw="not JSON")
        self.assertEqual(result.returncode, 2)
        self.assertIn("Lua edit hook failed", result.stderr)


if __name__ == "__main__":
    unittest.main()
