#!/usr/bin/env python3
"""
Package the Luau sources into .rbxmx model files that can be inserted straight
into Roblox Studio (right-click a service -> Insert from File, called
"Import Roblox Model" in newer Studio versions).

    python3 roblox/tools/build_rbxmx.py

The tree is discovered from roblox/src, so adding a module needs no edit here.
Writes into roblox/build/. Re-run it after changing any script.
"""

import os
import sys
from xml.sax.saxutils import escape

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
SRC = os.path.join(ROOT, "src")
OUT = os.path.join(ROOT, "build")

HEADER = (
    '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
    'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n'
    "\t<External>null</External>\n"
    "\t<External>nil</External>\n"
)

# output file stem, where it goes in Studio, folder under src/ to package
BUNDLES = [
    ("CardSystem_ReplicatedStorage", "ReplicatedStorage", "ReplicatedStorage/CardSystem"),
    ("CardSystem_ServerScriptService", "ServerScriptService", "ServerScriptService/CardSystem"),
    (
        "CardClient_StarterPlayerScripts",
        "StarterPlayer > StarterPlayerScripts",
        "StarterPlayer/StarterPlayerScripts/CardClient",
    ),
]

# file suffix -> instance class for the folder's own script
INIT_CLASSES = {
    "init.luau": "ModuleScript",
    "init.server.luau": "Script",
    "init.client.luau": "LocalScript",
}


class Node:
    def __init__(self, name, class_name, path=None):
        self.name = name
        self.class_name = class_name
        self.path = path
        self.children = []


def class_for(filename: str):
    """Returns (instance class, instance name) for a non-init source file."""
    stem = filename[: -len(".luau")]
    if stem.endswith(".server"):
        return "Script", stem[: -len(".server")]
    if stem.endswith(".client"):
        return "LocalScript", stem[: -len(".client")]
    return "ModuleScript", stem


def scan(directory: str, name: str) -> Node:
    entries = sorted(os.listdir(directory))

    # A folder containing an init script becomes that script.
    node = Node(name, "Folder")
    for init_name, init_class in INIT_CLASSES.items():
        if init_name in entries:
            node.class_name = init_class
            node.path = os.path.join(directory, init_name)
            break

    for entry in entries:
        full = os.path.join(directory, entry)
        if os.path.isdir(full):
            node.children.append(scan(full, entry))
        elif entry.endswith(".luau") and entry not in INIT_CLASSES:
            class_name, child_name = class_for(entry)
            node.children.append(Node(child_name, class_name, full))
    return node


class Counter:
    def __init__(self):
        self.n = 0

    def next(self):
        self.n += 1
        return f"RBX{self.n}"


def source_property(path: str) -> str:
    with open(path, encoding="utf-8") as handle:
        code = handle.read()
    # CDATA ends at the first "]]>". Luau long comments contain "]]" but the
    # three-character sequence would break the file, so fall back to escaping.
    if "]]>" in code:
        return f'<ProtectedString name="Source">{escape(code)}</ProtectedString>'
    return f'<ProtectedString name="Source"><![CDATA[{code}]]></ProtectedString>'


def render(node: Node, counter: Counter, depth: int) -> str:
    pad = "\t" * depth
    out = [f'{pad}<Item class="{node.class_name}" referent="{counter.next()}">\n']
    out.append(f"{pad}\t<Properties>\n")
    out.append(f'{pad}\t\t<string name="Name">{escape(node.name)}</string>\n')
    if node.path:
        out.append(f"{pad}\t\t{source_property(node.path)}\n")
    out.append(f"{pad}\t</Properties>\n")
    for child in node.children:
        out.append(render(child, counter, depth + 1))
    out.append(f"{pad}</Item>\n")
    return "".join(out)


def describe(node: Node, depth: int = 0) -> str:
    lines = ["  " * depth + f"{node.name} ({node.class_name})"]
    for child in node.children:
        lines.append(describe(child, depth + 1))
    return "\n".join(lines)


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    for filename, destination, relative in BUNDLES:
        directory = os.path.join(SRC, relative)
        if not os.path.isdir(directory):
            print(f"missing source directory: {directory}", file=sys.stderr)
            return 1

        node = scan(directory, os.path.basename(relative))
        xml = HEADER + render(node, Counter(), 1) + "</roblox>\n"

        target = os.path.join(OUT, filename + ".rbxmx")
        with open(target, "w", encoding="utf-8") as handle:
            handle.write(xml)

        print(f"{os.path.relpath(target, os.path.dirname(ROOT))}  ->  {destination}")
        print(describe(node, 1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
