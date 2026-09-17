#!/usr/bin/env python3
"""Generate original CC0 pixel sprites and simple SFX/BGM for this project.

Run from repo root: python3 tools/generate_assets.py
Output is overwritten under assets/sprites and assets/audio.
"""

from __future__ import annotations

import array
import math
import os
import random
import struct
import wave
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPR = ROOT / "assets" / "sprites"
AUD = ROOT / "assets" / "audio"

TRANSPARENT = (0, 0, 0, 0)

# Shared NES-like palette (original, not copied from any commercial game).
P = {
    "k": (16, 12, 20, 255),
    "h": (28, 22, 34, 255),
    "H": (52, 42, 62, 255),
    "w": (236, 236, 242, 255),
    "W": (176, 176, 188, 255),
    "s": (240, 196, 148, 255),
    "t": (196, 140, 96, 255),
    "e": (18, 14, 16, 255),
    "b": (48, 92, 214, 255),
    "B": (28, 52, 148, 255),
    "l": (98, 152, 238, 255),
    "r": (204, 44, 52, 255),
    "R": (140, 24, 32, 255),
    "p": (36, 48, 122, 255),
    "f": (24, 20, 28, 255),
    "m": (214, 222, 234, 255),
    "d": (112, 122, 144, 255),
    "g": (214, 176, 52, 255),
    "n": (248, 248, 252, 255),
    "o": (232, 120, 40, 255),  # boss orange
    "O": (168, 72, 20, 255),
    "y": (244, 196, 72, 255),
    "c": (168, 64, 196, 255),  # flyer purple
    "C": (112, 36, 148, 255),
    "v": (212, 140, 236, 255),
    "q": (196, 40, 40, 255),  # runner red
    "Q": (128, 20, 24, 255),
    "a": (92, 28, 28, 255),
    "x": (64, 48, 44, 255),  # ground dirt
    "z": (96, 72, 60, 255),
    "u": (140, 108, 84, 255),
    "i": (48, 36, 32, 255),
    "j": (72, 88, 64, 255),  # moss
    "1": (40, 56, 88, 255),
    "2": (28, 40, 64, 255),
    "3": (72, 92, 128, 255),
    "4": (18, 22, 40, 255),
    "5": (12, 14, 28, 255),
    "6": (220, 224, 180, 255),  # moon
    "7": (160, 168, 120, 255),
}


def chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + tag
        + data
        + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def write_png(path: Path, width: int, height: int, rgba: bytes) -> None:
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        raw.append(0)
        raw.extend(rgba[y * stride : (y + 1) * stride])
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


class Canvas:
    def __init__(self, w: int, h: int, fill=TRANSPARENT) -> None:
        self.w = w
        self.h = h
        self.px = [fill] * (w * h)

    def put(self, x: int, y: int, c) -> None:
        if c is None or c[3] == 0:
            return
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y * self.w + x] = c

    def get(self, x: int, y: int):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y * self.w + x]
        return TRANSPARENT

    def fill_rect(self, x: int, y: int, w: int, h: int, c) -> None:
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                self.put(xx, yy, c)

    def hline(self, x: int, y: int, w: int, c) -> None:
        for xx in range(x, x + w):
            self.put(xx, y, c)

    def vline(self, x: int, y: int, h: int, c) -> None:
        for yy in range(y, y + h):
            self.put(x, yy, c)

    def stamp(self, x: int, y: int, rows: list[str], pal: dict | None = None) -> None:
        pal = pal or P
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch == ".":
                    continue
                self.put(x + i, y + j, pal.get(ch, TRANSPARENT))

    def blit(self, other: "Canvas", ox: int, oy: int) -> None:
        for y in range(other.h):
            for x in range(other.w):
                self.put(ox + x, oy + y, other.get(x, y))

    def outline_pass(self, color=None) -> None:
        color = color or P["k"]
        orig = list(self.px)
        def occupied(x, y):
            if 0 <= x < self.w and 0 <= y < self.h:
                return orig[y * self.w + x][3] != 0
            return False
        for y in range(self.h):
            for x in range(self.w):
                if orig[y * self.w + x][3] != 0:
                    continue
                if occupied(x - 1, y) or occupied(x + 1, y) or occupied(x, y - 1) or occupied(x, y + 1):
                    self.put(x, y, color)

    def bytes(self) -> bytes:
        out = bytearray()
        for c in self.px:
            out.extend(c)
        return bytes(out)

    def save(self, path: Path) -> None:
        write_png(path, self.w, self.h, self.bytes())


def sheet_from_frames(frames: list[Canvas], fw: int, fh: int, columns: int) -> Canvas:
    rows = math.ceil(len(frames) / columns)
    sheet = Canvas(columns * fw, rows * fh)
    for i, fr in enumerate(frames):
        cx = (i % columns) * fw
        cy = (i // columns) * fh
        sheet.blit(fr, cx, cy)
    return sheet


# ---- Player (16x24) ----------------------------------------------------------

def _ninja_head(c: Canvas, hx: int, hy: int, hurt: bool = False) -> None:
    c.stamp(
        hx,
        hy,
        [
            ".hhhhhh.",
            "hhwwwwwh",
            "hhsseess",
            "hhsssssh",
            ".hssssh.",
        ],
    )
    if hurt:
        c.put(hx + 2, hy + 2, P["r"])
        c.put(hx + 5, hy + 2, P["r"])
    else:
        c.put(hx + 3, hy + 2, P["n"])
        c.put(hx + 6, hy + 2, P["n"])
    # headband tails
    c.put(hx - 1, hy + 1, P["w"])
    c.put(hx - 2, hy + 2, P["W"])


def _ninja_torso(c: Canvas, tx: int, ty: int) -> None:
    c.stamp(
        tx,
        ty,
        [
            ".BBBBBB.",
            "BbbrrrbB",
            "BbbbbbbB",
            "lBbbbbBl",
            ".BBBBBB.",
        ],
    )


def _ninja_leg(c: Canvas, x: int, y: int, kick: int = 0, lift: int = 0) -> None:
    yy = y - lift
    xx = x + kick
    c.fill_rect(xx, yy, 2, 5, P["p"])
    c.fill_rect(xx, yy + 5, 2, 2, P["f"])
    c.put(xx, yy, P["B"])


def _ninja_arm(c: Canvas, x: int, y: int, dx: int, dy: int, hand: bool = True) -> None:
    c.put(x, y, P["l"])
    c.put(x + dx, y + dy, P["b"])
    if hand:
        c.put(x + dx * 2, y + dy * 2, P["s"])


def _sword(c: Canvas, x: int, y: int, mode: str) -> None:
    if mode == "back":
        c.vline(x, y, 8, P["d"])
        c.vline(x + 1, y, 8, P["m"])
        c.put(x, y + 8, P["g"])
        c.put(x + 1, y + 8, P["R"])
    elif mode == "low":
        c.hline(x, y, 7, P["m"])
        c.put(x - 1, y, P["g"])
        c.put(x + 6, y, P["n"])
        c.hline(x, y + 1, 6, P["d"])
    elif mode == "mid":
        c.hline(x, y, 9, P["m"])
        c.put(x - 1, y, P["g"])
        c.put(x + 8, y, P["n"])
        c.put(x, y - 1, P["d"])
        c.put(x + 1, y + 1, P["d"])
    elif mode == "high":
        for i in range(8):
            c.put(x + i, y - i // 2, P["m"])
            c.put(x + i, y - i // 2 + 1, P["d"])
        c.put(x - 1, y, P["g"])
        c.put(x + 7, y - 3, P["n"])


def make_player_frame(kind: str, n: int = 0) -> Canvas:
    c = Canvas(16, 24)
    bob = 0
    hurt = False
    sword = "back"
    if kind == "idle":
        bob = n
        _sword(c, 3, 3 + bob, "back")
        _ninja_leg(c, 5, 14 + bob, kick=0)
        _ninja_leg(c, 9, 14 + bob, kick=0)
        _ninja_torso(c, 4, 8 + bob)
        _ninja_head(c, 4, 2 + bob)
        _ninja_arm(c, 4, 11 + bob, -1, 1)
        _ninja_arm(c, 11, 11 + bob, 1, 1)
    elif kind == "run":
        kicks = [( -1, 1, 1, 0), (0, 0, 0, 1), (1, -1, 0, 1), (0, 0, 1, 0)]
        ll, lr, al, ar = kicks[n % 4]
        bob = n % 2
        _sword(c, 3, 2 + bob, "back")
        _ninja_leg(c, 5, 14 + bob, kick=ll, lift=1 if n % 2 == 0 else 0)
        _ninja_leg(c, 9, 14 + bob, kick=lr, lift=0 if n % 2 == 0 else 1)
        _ninja_torso(c, 4, 8 + bob)
        _ninja_head(c, 4, 2 + bob)
        _ninja_arm(c, 4, 11 + bob, -1 if al else 0, 1 if al else 0)
        _ninja_arm(c, 11, 11 + bob, 1 if ar else 0, 1 if ar else 0)
    elif kind == "jump":
        _sword(c, 3, 1, "back")
        _ninja_leg(c, 4, 13, kick=-1, lift=2)
        _ninja_leg(c, 10, 13, kick=1, lift=1)
        _ninja_torso(c, 4, 7)
        _ninja_head(c, 4, 1)
        _ninja_arm(c, 4, 10, -1, -1)
        _ninja_arm(c, 11, 10, 1, -1)
    elif kind == "fall":
        _sword(c, 3, 2, "back")
        _ninja_leg(c, 5, 14, kick=-1)
        _ninja_leg(c, 9, 15, kick=1, lift=0)
        _ninja_torso(c, 4, 8)
        _ninja_head(c, 4, 2)
        _ninja_arm(c, 3, 11, -1, 1)
        _ninja_arm(c, 12, 11, 1, 1)
    elif kind == "attack":
        poses = [
            ("high", 0, 0, 1),
            ("mid", 1, 0, 0),
            ("low", 0, 1, 0),
        ]
        sm, kick, bob, arm_up = poses[n]
        _ninja_leg(c, 5, 14 + bob, kick=-kick)
        _ninja_leg(c, 9, 14 + bob, kick=kick)
        _ninja_torso(c, 4, 8 + bob)
        _ninja_head(c, 4, 2 + bob)
        _ninja_arm(c, 4, 11 + bob, -1, 1)
        if sm == "high":
            _ninja_arm(c, 11, 9 + bob, 1, -1)
            _sword(c, 12, 8 + bob, "high")
        elif sm == "mid":
            _ninja_arm(c, 12, 11 + bob, 1, 0)
            _sword(c, 13, 11 + bob, "mid")
        else:
            _ninja_arm(c, 12, 12 + bob, 1, 1)
            _sword(c, 13, 14 + bob, "low")
    elif kind == "hurt":
        hurt = True
        _ninja_leg(c, 4, 14, kick=-1)
        _ninja_leg(c, 10, 14, kick=1)
        _ninja_torso(c, 4, 9)
        _ninja_head(c, 4, 3, hurt=True)
        _ninja_arm(c, 3, 11, -1, -1)
        _ninja_arm(c, 12, 12, 1, 1)
    elif kind == "climb":
        shift = n
        _ninja_leg(c, 6, 14, kick=0, lift=shift)
        _ninja_leg(c, 9, 14, kick=0, lift=1 - shift)
        _ninja_torso(c, 4, 8)
        _ninja_head(c, 4, 2)
        _ninja_arm(c, 5, 9, 0, -1)
        _ninja_arm(c, 10, 9, 0, -1)
        c.put(6, 7 - shift, P["s"])
        c.put(10, 8 - (1 - shift), P["s"])
        _sword(c, 3, 4, "back")
    elif kind == "dead":
        # crumpled on side
        c.stamp(
            1,
            14,
            [
                "...hhhhhh.......",
                "..hwwwwssb......",
                ".ksssseebbrrm...",
                ".....BBBrrr.m...",
                "....pp....ff....",
            ],
        )
    if kind != "dead":
        c.outline_pass()
    else:
        c.outline_pass()
    return c


def build_player_sheet() -> None:
    order = (
        ["idle"] * 2
        + ["run"] * 4
        + ["jump"]
        + ["fall"]
        + ["attack"] * 3
        + ["hurt"]
        + ["climb"] * 2
        + ["dead"]
    )
    frames: list[Canvas] = []
    counts: dict[str, int] = {}
    for kind in order:
        n = counts.get(kind, 0)
        counts[kind] = n + 1
        frames.append(make_player_frame(kind, n))
    sheet_from_frames(frames, 16, 24, 4).save(SPR / "player" / "player.png")


# ---- Runner (16x16) ----------------------------------------------------------

def make_runner_frame(n: int) -> Canvas:
    c = Canvas(16, 16)
    bob = n % 2
    kick_l = [-1, 0, 1, 0][n]
    kick_r = [1, 0, -1, 0][n]
    # horns + head
    c.stamp(
        4,
        1 + bob,
        [
            "q..q",
            "QQQQ",
            "qeeq",
            "qttq",
        ],
    )
    # body
    c.fill_rect(5, 5 + bob, 6, 5, P["q"])
    c.fill_rect(6, 6 + bob, 4, 3, P["Q"])
    c.put(7, 7 + bob, P["g"])
    # arms
    c.put(4, 6 + bob, P["q"])
    c.put(3, 7 + bob, P["a"])
    c.put(11, 6 + bob, P["q"])
    c.put(12, 7 + bob, P["a"])
    # legs
    c.fill_rect(5 + kick_l, 10 + bob, 2, 4, P["a"])
    c.fill_rect(9 + kick_r, 10 + bob, 2, 4, P["a"])
    c.fill_rect(5 + kick_l, 13 + bob, 2, 2, P["f"])
    c.fill_rect(9 + kick_r, 13 + bob, 2, 2, P["f"])
    c.outline_pass()
    return c


def build_runner_sheet() -> None:
    frames = [make_runner_frame(i) for i in range(4)]
    sheet_from_frames(frames, 16, 16, 4).save(SPR / "enemies" / "runner.png")


# ---- Flyer (16x16) -----------------------------------------------------------

def make_flyer_frame(n: int) -> Canvas:
    c = Canvas(16, 16)
    wing = [
        [
            "..v..........v..",
            ".vvv........vvv.",
            "vvvv........vvvv",
        ],
        [
            "................",
            "vvv..........vvv",
            ".vvvv......vvvv.",
        ],
        [
            "..v..........v..",
            ".vvv........vvv.",
            "vvvv........vvvv",
        ],
        [
            "v..............v",
            "vvv..........vvv",
            ".vv..........vv.",
        ],
    ][n]
    c.stamp(0, 2 + (n % 2), wing)
    c.stamp(
        5,
        4,
        [
            ".CCCC.",
            "CceecC",
            "CccccC",
            ".CCCC.",
            "..cc..",
        ],
    )
    c.put(7, 5, P["n"])
    c.put(10, 5, P["n"])
    # fangs
    c.put(7, 8, P["w"])
    c.put(10, 8, P["w"])
    c.outline_pass()
    return c


def build_flyer_sheet() -> None:
    frames = [make_flyer_frame(i) for i in range(4)]
    sheet_from_frames(frames, 16, 16, 4).save(SPR / "enemies" / "flyer.png")


# ---- Boss (24x32) ------------------------------------------------------------

def make_boss_frame(kind: str, n: int = 0) -> Canvas:
    c = Canvas(24, 32)
    bob = 0 if kind != "idle" else n
    if kind == "dead":
        c.stamp(
            2,
            18,
            [
                "....OOOOOOOO........",
                "...OOyyyyyyOO.......",
                "..OOyeeeeeyyOm......",
                ".OOyyyyyyyyyOmm.....",
                "OOOOooooOOOO.m......",
                "pp..........ff......",
            ],
        )
        c.outline_pass()
        return c
    walk = 0
    if kind == "walk":
        walk = [-1, 0, 1, 0][n]
        bob = n % 2
    # cape
    c.fill_rect(5, 10 + bob, 3, 10, P["R"])
    c.fill_rect(4, 12 + bob, 2, 8, P["r"])
    # legs
    lk = walk if kind == "walk" else (1 if kind == "attack" and n == 1 else 0)
    rk = -walk if kind == "walk" else 0
    c.fill_rect(8 + lk, 20 + bob, 3, 8, P["O"])
    c.fill_rect(13 + rk, 20 + bob, 3, 8, P["O"])
    c.fill_rect(8 + lk, 27 + bob, 3, 3, P["f"])
    c.fill_rect(13 + rk, 27 + bob, 3, 3, P["f"])
    # torso armor
    c.fill_rect(7, 10 + bob, 10, 11, P["o"])
    c.fill_rect(8, 11 + bob, 8, 9, P["O"])
    c.fill_rect(9, 13 + bob, 6, 3, P["y"])
    c.put(11, 14 + bob, P["g"])
    c.put(12, 14 + bob, P["g"])
    # head / mask
    c.fill_rect(8, 3 + bob, 8, 8, P["o"])
    c.fill_rect(9, 4 + bob, 6, 6, P["y"])
    c.put(10, 6 + bob, P["e"])
    c.put(14, 6 + bob, P["e"])
    c.put(11, 6 + bob, P["r"])
    c.put(13, 6 + bob, P["r"])
    c.hline(10, 8 + bob, 4, P["k"])
    # horns
    c.put(8, 2 + bob, P["y"])
    c.put(7, 1 + bob, P["y"])
    c.put(15, 2 + bob, P["y"])
    c.put(16, 1 + bob, P["y"])
    # arms + weapon
    if kind == "attack":
        if n == 0:
            c.fill_rect(16, 8 + bob, 3, 6, P["o"])
            c.put(18, 7 + bob, P["s"])
            _sword(c, 17, 4 + bob, "high")
        elif n == 1:
            c.fill_rect(16, 12 + bob, 5, 3, P["o"])
            c.put(21, 13 + bob, P["s"])
            _sword(c, 14, 13 + bob, "mid")
        else:
            c.fill_rect(16, 14 + bob, 3, 5, P["o"])
            c.put(18, 19 + bob, P["s"])
            _sword(c, 14, 18 + bob, "low")
    else:
        c.fill_rect(5, 12 + bob, 3, 6, P["o"])
        c.put(4, 17 + bob, P["s"])
        c.fill_rect(16, 12 + bob, 3, 6, P["o"])
        c.put(19, 17 + bob, P["s"])
        _sword(c, 19, 6 + bob, "back")
    c.outline_pass()
    return c


def build_boss_sheet() -> None:
    frames = (
        [make_boss_frame("idle", 0), make_boss_frame("idle", 1)]
        + [make_boss_frame("walk", i) for i in range(4)]
        + [make_boss_frame("attack", i) for i in range(3)]
        + [make_boss_frame("dead", 0)]
    )
    sheet_from_frames(frames, 24, 32, 4).save(SPR / "enemies" / "boss.png")


# ---- Tiles / background / UI -------------------------------------------------

def _speckle(c: Canvas, rng: random.Random, colors: list, chance: float = 0.08) -> None:
    for y in range(c.h):
        for x in range(c.w):
            if rng.random() < chance:
                c.put(x, y, rng.choice(colors))


def build_tiles() -> None:
    rng = random.Random(7)
    ground = Canvas(16, 16, P["x"])
    # two brick rows
    for y, y0 in ((0, 0), (8, 8)):
        ground.hline(0, y0, 16, P["i"])
        ground.hline(0, y0 + 7, 16, P["i"])
        ground.vline(0, y0, 8, P["i"])
        ground.vline(15, y0, 8, P["i"])
        if y0 == 0:
            ground.vline(8, y0, 8, P["i"])
        else:
            ground.vline(4, y0, 8, P["i"])
            ground.vline(12, y0, 8, P["i"])
    # highlights and moss
    for x in range(16):
        for y in range(16):
            if ground.get(x, y) == P["x"] and (x + y) % 5 == 0:
                ground.put(x, y, P["z"])
    ground.hline(1, 1, 6, P["u"])
    ground.hline(9, 1, 6, P["u"])
    ground.put(3, 14, P["j"])
    ground.put(10, 13, P["j"])
    ground.put(12, 15, P["j"])
    _speckle(ground, rng, [P["z"], P["i"]], 0.06)
    ground.save(SPR / "tiles" / "ground.png")

    plat = Canvas(16, 16, P["z"])
    plat.hline(0, 0, 16, P["u"])
    plat.hline(0, 1, 16, P["g"])
    plat.hline(0, 2, 16, P["u"])
    plat.hline(0, 15, 16, P["i"])
    for x in (0, 5, 10, 15):
        plat.vline(x, 3, 12, P["i"])
    plat.fill_rect(1, 4, 4, 10, P["x"])
    plat.fill_rect(6, 4, 4, 10, P["x"])
    plat.fill_rect(11, 4, 4, 10, P["x"])
    plat.save(SPR / "tiles" / "platform.png")

    wall = Canvas(16, 16, P["1"])
    for y in range(0, 16, 4):
        wall.hline(0, y, 16, P["2"])
    for x in (0, 8, 15):
        wall.vline(x, 0, 16, P["2"])
    wall.fill_rect(1, 1, 6, 2, P["3"])
    wall.fill_rect(9, 5, 6, 2, P["3"])
    wall.fill_rect(1, 9, 6, 2, P["4"])
    _speckle(wall, rng, [P["2"], P["4"]], 0.05)
    wall.save(SPR / "tiles" / "wall.png")

    brick = Canvas(16, 16, P["O"])
    for y in (0, 8):
        brick.hline(0, y, 16, P["k"])
        brick.hline(0, y + 7, 16, P["k"])
        brick.vline(0, y, 8, P["k"])
        brick.vline(15, y, 8, P["k"])
        brick.vline(8 if y == 0 else 4, y, 8, P["k"])
    brick.hline(1, 1, 6, P["y"])
    brick.save(SPR / "tiles" / "brick.png")


def build_background() -> None:
    rng = random.Random(42)
    sky = Canvas(256, 240, P["5"])
    for y in range(240):
        t = y / 239.0
        r = int(10 + 18 * t)
        g = int(12 + 22 * t)
        b = int(28 + 48 * t)
        sky.hline(0, y, 256, (r, g, b, 255))
    # stars
    for _ in range(90):
        x = rng.randint(0, 255)
        y = rng.randint(0, 150)
        bright = rng.choice([P["n"], P["w"], P["W"], (255, 252, 220, 255)])
        sky.put(x, y, bright)
        if rng.random() < 0.2:
            sky.put(x + 1, y, P["W"])
    sky.save(SPR / "bg" / "sky.png")

    moon = Canvas(16, 16)
    moon.stamp(
        2,
        1,
        [
            "..6666..",
            ".666766.",
            "66666676",
            "66666666",
            "66666666",
            "76666666",
            ".666666.",
            "..6666..",
        ],
    )
    moon.put(5, 4, P["7"])
    moon.put(8, 7, P["7"])
    moon.put(6, 9, P["7"])
    moon.save(SPR / "bg" / "moon.png")

    # Distant mountain dither strip (tiled horizontally).
    mtn = Canvas(64, 48, TRANSPARENT)
    for x in range(64):
        h1 = 18 + int(8 * math.sin(x / 9.0) + 5 * math.sin(x / 5.0))
        h2 = 10 + int(6 * math.sin(x / 7.0 + 1.2))
        for y in range(48 - h1, 48):
            mtn.put(x, y, P["4"])
        for y in range(48 - h2, 48):
            mtn.put(x, y, P["2"])
    mtn.save(SPR / "bg" / "mountains.png")


def build_ui() -> None:
    pip = Canvas(6, 4, P["b"])
    pip.hline(0, 0, 6, P["l"])
    pip.hline(0, 3, 6, P["B"])
    pip.vline(0, 0, 4, P["l"])
    pip.vline(5, 0, 4, P["B"])
    pip.save(SPR / "ui" / "health_pip.png")

    boss_pip = Canvas(6, 4, P["r"])
    boss_pip.hline(0, 0, 6, P["q"])
    boss_pip.hline(0, 3, 6, P["R"])
    boss_pip.vline(0, 0, 4, P["q"])
    boss_pip.vline(5, 0, 4, P["R"])
    boss_pip.save(SPR / "ui" / "boss_pip.png")

    banner = Canvas(16, 16)
    # miniature player idle for title deco
    mini = make_player_frame("idle", 0)
    banner.blit(mini, 0, -4)
    banner.save(SPR / "ui" / "title_ninja.png")


# ---- Audio -------------------------------------------------------------------

RATE = 22050


def midi_hz(n: float) -> float:
    return 440.0 * (2.0 ** ((n - 69.0) / 12.0))


def clamp16(v: float) -> int:
    return max(-32767, min(32767, int(v * 32767.0)))


def write_wav(path: Path, samples: list[float], rate: int = RATE) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = array.array("h", (clamp16(s) for s in samples))
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(data.tobytes())


def square(t: float, hz: float) -> float:
    return 1.0 if math.sin(2 * math.pi * hz * t) >= 0 else -1.0


def triangle(t: float, hz: float) -> float:
    return 2.0 * abs(2.0 * (t * hz % 1.0) - 1.0) - 1.0


def noise() -> float:
    return random.random() * 2.0 - 1.0


def env_decay(t: float, dur: float, power: float = 2.5) -> float:
    if t < 0 or t > dur:
        return 0.0
    return (1.0 - t / dur) ** power


def sfx_jump() -> list[float]:
    dur = 0.12
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        hz = 280.0 + 420.0 * (t / dur)
        out.append(0.28 * square(t, hz) * env_decay(t, dur, 1.4))
    return out


def sfx_attack() -> list[float]:
    dur = 0.11
    n = int(RATE * dur)
    out = []
    random.seed(3)
    for i in range(n):
        t = i / RATE
        hz = 880.0 - 500.0 * (t / dur)
        out.append(0.18 * square(t, hz) * env_decay(t, dur, 1.2) + 0.16 * noise() * env_decay(t, dur, 3.0))
    return out


def sfx_hurt() -> list[float]:
    dur = 0.18
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        hz = 420.0 - 260.0 * (t / dur)
        out.append(0.32 * square(t, hz) * env_decay(t, dur, 1.1))
    return out


def sfx_hit() -> list[float]:
    dur = 0.08
    n = int(RATE * dur)
    out = []
    random.seed(9)
    for i in range(n):
        t = i / RATE
        out.append(0.22 * square(t, 160.0) * env_decay(t, dur, 2.0) + 0.2 * noise() * env_decay(t, dur, 4.0))
    return out


def build_sfx() -> None:
    write_wav(AUD / "sfx" / "jump.wav", sfx_jump())
    write_wav(AUD / "sfx" / "attack.wav", sfx_attack())
    write_wav(AUD / "sfx" / "hurt.wav", sfx_hurt())
    write_wav(AUD / "sfx" / "hit.wav", sfx_hit())


def note_tone(hz: float, dur: float, kind: str, vol: float) -> list[float]:
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        if hz <= 0:
            out.append(0.0)
            continue
        wave_v = triangle(t, hz) if kind == "tri" else square(t, hz)
        # tiny click-free envelope
        a = min(1.0, i / 80.0)
        r = min(1.0, (n - i) / 120.0)
        out.append(vol * wave_v * a * r)
    return out


def mix_add(dst: list[float], src: list[float], at: int) -> None:
    if at + len(src) > len(dst):
        dst.extend([0.0] * (at + len(src) - len(dst)))
    for i, s in enumerate(src):
        dst[at + i] += s


def build_bgm() -> None:
    random.seed(11)
    bpm = 132.0
    eighth = 60.0 / bpm / 2.0
    # 4 bars of 8 eighths, then repeat once = 8 bars (~7.3s)
    lead = [
        76, 72, 76, 81, 79, 76, 74, 72,
        69, 72, 76, 74, 72, 69, 67, 69,
        76, 76, 72, 81, 79, 77, 76, 74,
        72, 76, 81, 76, 74, 72, 71, 69,
    ]
    bass = [
        45, 45, 45, 40, 41, 41, 48, 48,
        45, 45, 40, 40, 43, 43, 38, 38,
        45, 45, 45, 40, 41, 41, 48, 48,
        45, 48, 40, 45, 43, 40, 38, 33,
    ]
    samples: list[float] = []
    loops = 2
    for rep in range(loops):
        for i, (ln, bn) in enumerate(zip(lead, bass)):
            t0 = int((rep * len(lead) + i) * eighth * RATE)
            mix_add(samples, note_tone(midi_hz(ln), eighth, "sq", 0.11), t0)
            mix_add(samples, note_tone(midi_hz(bn), eighth, "tri", 0.14), t0)
            # hats on every 8th, snare-ish on 2 and 4
            hat = []
            for h in range(int(RATE * 0.03)):
                hat.append(0.04 * noise() * env_decay(h / RATE, 0.03, 2.0))
            mix_add(samples, hat, t0)
            if i % 4 == 2:
                sn: list[float] = []
                for h in range(int(RATE * 0.06)):
                    sn.append(0.09 * noise() * env_decay(h / RATE, 0.06, 2.2))
                mix_add(samples, sn, t0)
    # normalize softly
    peak = max(1e-6, max(abs(s) for s in samples))
    gain = 0.85 / peak
    samples = [s * gain for s in samples]
    write_wav(AUD / "bgm" / "level.wav", samples)


def main() -> None:
    build_player_sheet()
    build_runner_sheet()
    build_flyer_sheet()
    build_boss_sheet()
    build_tiles()
    build_background()
    build_ui()
    build_sfx()
    build_bgm()
    print("Wrote sprites under", SPR)
    print("Wrote audio under", AUD)


if __name__ == "__main__":
    main()
