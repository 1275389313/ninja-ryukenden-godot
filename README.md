# ninja-ryukenden-godot

仿 FC《忍者龙剑传》手感的 Godot 4.6 2D 横版游戏（原创像素图与音效，**不含**官方 ROM/素材）。

## 运行

用 Godot 4.6 打开本目录，主场景为 `scenes/main.tscn`。

操作：方向键 / WASD 移动，`K` / 空格跳跃，`J` / `Z` 攻击，Enter 开始。

## 资源怎么换

美术与音频由 `GameAssets` 从固定路径加载；文件不存在时回退为纯色占位纹理或静音，不会硬崩。

把同名文件丢进对应目录即可替换（建议 PNG 像素图、WAV 音效，过滤保持 Nearest）。

| 用途 | 路径 |
| --- | --- |
| 玩家表（16×24，4 列） | `assets/sprites/player/player.png` |
| 奔跑杂兵（16×16） | `assets/sprites/enemies/runner.png` |
| 飞行杂兵（16×16） | `assets/sprites/enemies/flyer.png` |
| Boss（24×32） | `assets/sprites/enemies/boss.png` |
| 地面砖 | `assets/sprites/tiles/ground.png` |
| 浮台 | `assets/sprites/tiles/platform.png` |
| 攀爬墙 | `assets/sprites/tiles/wall.png` |
| 夜空 / 月亮 | `assets/sprites/bg/sky.png`, `moon.png` |
| HUD 血格 | `assets/sprites/ui/health_pip.png`, `boss_pip.png` |
| 跳跃 / 挥砍 / 受伤 / 击中 | `assets/audio/sfx/jump.wav` 等 |
| 关卡 BGM 循环 | `assets/audio/bgm/level.wav` |

玩家表帧序（从左到右、从上到下，每行 4 帧）：idle×2, run×4, jump, fall, attack×3, hurt, climb×2, dead。可用 `python3 tools/generate_assets.py` 重新生成当前这套原创素材。

许可见 [`assets/LICENSES.md`](assets/LICENSES.md)。
