#!/usr/bin/env python3
"""
Export every script as one plain text file with the comments stripped, for
sending the code to someone outside the repo.

    python3 roblox/tools/export_plain.py

Writes roblox/build/card-system-source.txt. The sources under roblox/src are
left untouched.

Stripping is done with a character scanner rather than a regular expression,
because "--" only starts a comment outside of a string. Lua short strings,
Luau backtick strings and long bracket strings all have to be skipped over
intact, or code like `Slot{index}` or "a -- b" would be mangled.
"""

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, ".."))
SRC = os.path.join(ROOT, "src")
OUT = os.path.join(ROOT, "build", "card-system-source.txt")

# Where each folder lands in Studio, in the order a reader wants them.
PLACEMENT = [
    ("ReplicatedStorage/CardSystem", "ReplicatedStorage > CardSystem (Folder)"),
    ("ServerScriptService/CardSystem", "ServerScriptService > CardSystem (Script)"),
    (
        "StarterPlayer/StarterPlayerScripts/CardClient",
        "StarterPlayer > StarterPlayerScripts > CardClient (LocalScript)",
    ),
]

INIT_KINDS = {
    "init.luau": "ModuleScript",
    "init.server.luau": "Script",
    "init.client.luau": "LocalScript",
}


def long_bracket(source: str, index: int):
    """
    If a long bracket opens at `index` ("[[", "[=[", "[==[" ...), return the
    index just past its matching close. Returns None when it is not one.
    """
    if index >= len(source) or source[index] != "[":
        return None

    level = 0
    cursor = index + 1
    while cursor < len(source) and source[cursor] == "=":
        level += 1
        cursor += 1
    if cursor >= len(source) or source[cursor] != "[":
        return None

    close = "]" + "=" * level + "]"
    end = source.find(close, cursor + 1)
    if end == -1:
        return len(source)  # unterminated; take the rest
    return end + len(close)


def strip_comments(source: str) -> str:
    out = []
    i = 0
    size = len(source)

    while i < size:
        char = source[i]

        # Short strings, including Luau's backtick interpolation.
        if char in "\"'`":
            delimiter = char
            out.append(char)
            i += 1
            while i < size:
                if source[i] == "\\":
                    out.append(source[i : i + 2])
                    i += 2
                    continue
                out.append(source[i])
                i += 1
                if source[i - 1] == delimiter:
                    break
            continue

        # Long strings are data, not comments.
        if char == "[":
            end = long_bracket(source, i)
            if end is not None:
                out.append(source[i:end])
                i = end
                continue

        if char == "-" and source[i + 1 : i + 2] == "-":
            block_end = long_bracket(source, i + 2)
            if block_end is not None:
                i = block_end  # --[[ block comment ]]
                continue
            while i < size and source[i] != "\n":  # -- line comment
                i += 1
            continue

        out.append(char)
        i += 1

    return "".join(out)


def tidy(source: str) -> str:
    """Drop the whitespace a removed comment leaves behind."""
    lines = [line.rstrip() for line in source.split("\n")]

    tidied = []
    for line in lines:
        if line == "" and (not tidied or tidied[-1] == ""):
            continue  # no leading or doubled blank lines
        tidied.append(line)

    while tidied and tidied[-1] == "":
        tidied.pop()
    return "\n".join(tidied)


def kind_and_name(filename: str):
    if filename in INIT_KINDS:
        return INIT_KINDS[filename], None
    stem = filename[: -len(".luau")]
    if stem.endswith(".server"):
        return "Script", stem[: -len(".server")]
    if stem.endswith(".client"):
        return "LocalScript", stem[: -len(".client")]
    return "ModuleScript", stem


def main() -> int:
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    blocks = []
    count = 0

    header = [
        "ROBLOX CARD SYSTEM - FULL SOURCE",
        "",
        "Comments stripped. Create each script below with the exact name shown,",
        "in the location shown, and paste its body in. Names matter: every",
        "require looks the modules up by name.",
        "",
    ]
    for relative, placement in PLACEMENT:
        header.append(f"  {placement}")
    blocks.append("\n".join(header))

    for relative, placement in PLACEMENT:
        directory = os.path.join(SRC, relative)
        folder_name = os.path.basename(relative)

        for filename in sorted(os.listdir(directory)):
            if not filename.endswith(".luau"):
                continue

            kind, name = kind_and_name(filename)
            label = f"{placement}" if name is None else f"{placement} > {name} ({kind})"

            with open(os.path.join(directory, filename), encoding="utf-8") as handle:
                body = tidy(strip_comments(handle.read()))

            rule = "=" * 78
            blocks.append(f"{rule}\n{label}\n{rule}\n\n{body}")
            count += 1

    with open(OUT, "w", encoding="utf-8") as handle:
        handle.write("\n\n\n".join(blocks) + "\n")

    size = os.path.getsize(OUT)
    print(f"{os.path.relpath(OUT, os.path.dirname(ROOT))}: {count} scripts, {size:,} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
