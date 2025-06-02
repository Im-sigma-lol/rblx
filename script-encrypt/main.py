#!/usr/bin/env python3
import re
import random
import string
from pathlib import Path

# Load Lua source
lua_path = Path("input.lua")
lua_code = lua_path.read_text()

# Find local variable declarations like: local myVar = ...
pattern = re.compile(r'\blocal\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*=')

# Keep track of renamed variables
renamed = {}

# Replace each match with a new randomized name
def generate_name():
    return ''.join(random.choices(string.ascii_letters + string.digits, k=12))

def replacer(match):
    old_name = match.group(1)
    if old_name not in renamed:
        renamed[old_name] = generate_name()
    return f"local {renamed[old_name]} ="

# Replace variable names only in their declarations
obfuscated_code = pattern.sub(replacer, lua_code)

# Write to output
Path("output.lua").write_text(obfuscated_code)
print("[+] Obfuscated variable names in declarations saved to output.lua")
