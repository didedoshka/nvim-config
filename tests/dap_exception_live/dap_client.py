"""Minimal DAP client driving gdb the way ~/.config/nvim/lua/plugins/dap.lua does (without mcp.py)."""

import json
import os
import queue
import subprocess
import threading
import time

CONFIG = os.path.expanduser("~/.config/nvim/gdb")
FILES = ("dap_core.py", "dap_guard.py", "dap_step.py", "dap_exception.py")


class Dap:
    def __init__(self, root, files=FILES):
        args = ["gdb", "-q", "-ex", "maint set per-command time off", "-ex", "set history save off",
                "-ex", "set substitute-path /-S " + root]
        for f in files:
            args += ["-ex", "source %s/%s" % (CONFIG, f)]
        args.append("--interpreter=dap")
        self.p = subprocess.Popen(args, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.PIPE)
        self.seq = 0
        self.inbox = queue.Queue()
        self.seen = []
        threading.Thread(target=self._read, daemon=True).start()
        self.stderr = []
        threading.Thread(target=self._read_err, daemon=True).start()

    def _read(self):
        f = self.p.stdout
        while True:
            header = b""
            while not header.endswith(b"\r\n\r\n"):
                c = f.read(1)
                if not c:
                    self.inbox.put(None)
                    return
                header += c
            length = next(int(l.split(":")[1]) for l in header.decode().split("\r\n")
                          if l.lower().startswith("content-length"))
            self.inbox.put(json.loads(f.read(length)))

    def _read_err(self):
        for line in self.p.stderr:
            self.stderr.append(line.decode(errors="replace").rstrip())

    def drain(self):
        while not self.inbox.empty():
            m = self.inbox.get()
            if m is not None:
                self.seen.append(m)

    def send(self, command, arguments=None):
        self.seq += 1
        data = json.dumps({"seq": self.seq, "type": "request", "command": command,
                           "arguments": arguments or {}}).encode()
        self.p.stdin.write(b"Content-Length: %d\r\n\r\n" % len(data) + data)
        self.p.stdin.flush()
        return self.seq

    def wait(self, pred, since=0, timeout=120):
        deadline = time.monotonic() + timeout
        i = since
        while True:
            while i < len(self.seen):
                if pred(self.seen[i]):
                    return self.seen[i]
                i += 1
            left = deadline - time.monotonic()
            if left <= 0:
                raise TimeoutError("no matching DAP message")
            m = self.inbox.get(timeout=left)
            if m is None:
                raise EOFError("gdb exited")
            self.seen.append(m)

    def request(self, command, arguments=None, timeout=120):
        seq = self.send(command, arguments)
        r = self.wait(lambda m: m.get("type") == "response" and m.get("request_seq") == seq,
                      timeout=timeout)
        if not r.get("success"):
            raise RuntimeError("%s failed: %s" % (command, r.get("message")))
        return r

    def events(self, since, name):
        return [m for m in self.seen[since:] if m.get("type") == "event" and m.get("event") == name]

    def launch(self, program, args, breakpoints, cwd="/tmp"):
        self.request("initialize", {"clientID": "test", "adapterID": "gdb", "linesStartAt1": True,
                                    "columnsStartAt1": True, "pathFormat": "path"}, timeout=180)
        self.send("launch", {"program": program, "args": args, "cwd": cwd})
        for path, lines in breakpoints.items():
            self.request("setBreakpoints", {"source": {"path": path},
                                            "breakpoints": [{"line": l} for l in lines]})
        self.request("configurationDone")
        stop = self.wait_stop(0)
        r = self.request("evaluate", {"expression": "python print('dap_exception loaded:', '_DapExc' in globals())",
                                      "context": "repl"})
        print("  ", r["body"]["result"].strip())
        return stop

    def wait_stop(self, since, timeout=180):
        m = self.wait(lambda m: m.get("type") == "event" and m.get("event") in ("stopped", "exited", "terminated"),
                      since=since, timeout=timeout)
        return m

    def top(self, thread_id, levels=1):
        r = self.request("stackTrace", {"threadId": thread_id, "startFrame": 0, "levels": levels})
        return r["body"]["stackFrames"]

    def step(self, command, thread_id, timeout=180):
        time.sleep(0.3)
        self.drain()
        since = len(self.seen)
        started = time.monotonic()
        self.send(command, {"threadId": thread_id})
        stop = self.wait_stop(since, timeout)
        elapsed = time.monotonic() - started
        body = stop.get("body", {})
        if stop["event"] != "stopped":
            return {"event": stop["event"], "elapsed": elapsed}
        frames = self.top(body["threadId"], 3)
        f = frames[0]
        return {
            "reason": body.get("reason"),
            "thread": body["threadId"],
            "where": "%s:%s" % (os.path.basename(f.get("source", {}).get("path", "??")), f.get("line")),
            "name": f.get("name", "")[:80],
            "elapsed": round(elapsed, 2),
            "stopped": len(self.events(since, "stopped")),
            "continued": len(self.events(since, "continued")),
            "breakpoint_events": len(self.events(since, "breakpoint")),
            "output": [m["body"].get("output", "").strip()[:100] for m in self.events(since, "output")],
        }

    def close(self):
        try:
            self.send("disconnect", {"terminateDebuggee": True})
            self.p.wait(timeout=20)
        except Exception:
            self.p.kill()
