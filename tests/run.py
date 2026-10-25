"""Run plugin tests with Lua 5.4."""
import argparse
from pathlib import Path
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--lua-packages", type=Path, help="Directory containing lupa")
args = parser.parse_args()
if args.lua_packages:
    sys.path.insert(0, str(args.lua_packages.resolve()))
from lupa.lua54 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().pluginRoot = root.as_posix()
lua.execute("package.path = pluginRoot .. '/?.lua;' .. package.path")
lua.execute((root / "tests/runtime.lua").read_text(encoding="utf-8"))
