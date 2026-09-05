#!/usr/bin/env python3
"""
Package the Luau sources into three .rbxmx model files that can be inserted
straight into Roblox Studio (right-click a service -> Insert from File).

    python3 roblox/tools/build_rbxmx.py

Writes into roblox/build/. Re-run it after editing any script.
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

# name, class, source path (None = no source), children
BUNDLES = [
    (
        "CardSystem_ReplicatedStorage",
        "ReplicatedStorage",
        ("CardSystem", "Folder", None, [
            ("Config", "ModuleScript", "ReplicatedStorage/CardSystem/Config.luau", []),
            ("Rarities", "ModuleScript", "ReplicatedStorage/CardSystem/Rarities.luau", []),
            ("Cards", "ModuleScript", "ReplicatedStorage/CardSystem/Cards.luau", []),
            ("RollLogic", "ModuleScript", "ReplicatedStorage/CardSystem/RollLogic.luau", []),
            ("Remotes", "ModuleScript", "ReplicatedStorage/CardSystem/Remotes.luau", []),
        ]),
    ),
    (
        "CardSystem_ServerScriptService",
        "ServerScriptService",
        ("CardSystem", "Script", "ServerScriptService/CardSystem/init.server.luau", [
            ("Inventory", "ModuleScript", "ServerScriptService/CardSystem/Inventory.luau", []),
        ]),
    ),
    (
        "CardClient_StarterPlayerScripts",
        "StarterPlayer > StarterPlayerScripts",
        ("CardClient", "LocalScript", "StarterPlayer/StarterPlayerScripts/CardClient/init.client.luau", [
            ("CardVisual", "ModuleScript", "StarterPlayer/StarterPlayerScripts/CardClient/CardVisual.luau", []),
            ("RollUI", "ModuleScript", "StarterPlayer/StarterPlayerScripts/CardClient/RollUI.luau", []),
        ]),
    ),
]


class Counter:
    def __init__(self):
        self.n = 0

    def next(self):
        self.n += 1
        return f"RBX{self.n}"


def source_property(path: str) -> str:
    with open(os.path.join(SRC, path), encoding="utf-8") as handle:
        code = handle.read()
    # CDATA ends at the first "]]>". Luau long comments contain "]]" but the
    # three-character sequence would break the file, so fall back to escaping.
    if "]]>" in code:
        return f'<ProtectedString name="Source">{escape(code)}</ProtectedString>'
    return f'<ProtectedString name="Source"><![CDATA[{code}]]></ProtectedString>'


def render(node, counter: Counter, depth: int) -> str:
    name, class_name, path, children = node
    pad = "\t" * depth
    out = [f'{pad}<Item class="{class_name}" referent="{counter.next()}">\n']
    out.append(f"{pad}\t<Properties>\n")
    out.append(f'{pad}\t\t<string name="Name">{escape(name)}</string>\n')
    if path:
        out.append(f"{pad}\t\t{source_property(path)}\n")
    out.append(f"{pad}\t</Properties>\n")
    for child in children:
        out.append(render(child, counter, depth + 1))
    out.append(f"{pad}</Item>\n")
    return "".join(out)


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    for filename, destination, tree in BUNDLES:
        counter = Counter()
        xml = HEADER + render(tree, counter, 1) + "</roblox>\n"
        target = os.path.join(OUT, filename + ".rbxmx")
        with open(target, "w", encoding="utf-8") as handle:
            handle.write(xml)
        print(f"{os.path.relpath(target, os.path.dirname(ROOT))}  ->  insert into {destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
