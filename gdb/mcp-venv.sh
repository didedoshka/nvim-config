#!/usr/bin/env bash
# Build the venv gdb/mcp.py imports fastmcp from. The system python is gdb's
# python (PEP 668 locks its site-packages), so the venv must use it too.
set -euo pipefail
VENV="$HOME/.local/share/gdb-mcp/venv"
python3 -m venv "$VENV"
"$VENV/bin/pip" install -q --upgrade fastmcp
"$VENV/bin/python" -c 'import fastmcp; print("fastmcp", fastmcp.__version__, "->", "'"$VENV"'")'
