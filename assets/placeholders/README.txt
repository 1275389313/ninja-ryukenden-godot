占位纹理由 scripts/components/placeholder_texture.gd 的 PlaceholderTexture.make()
在运行时生成。正式像素图与音效应放在下列路径（缺失则自动回退占位/静音）：

  assets/sprites/player/player.png
  assets/sprites/enemies/runner.png
  assets/sprites/enemies/flyer.png
  assets/sprites/enemies/boss.png
  assets/sprites/tiles/ground.png
  assets/sprites/tiles/platform.png
  assets/sprites/tiles/wall.png
  assets/sprites/tiles/brick.png
  assets/sprites/bg/sky.png
  assets/sprites/bg/moon.png
  assets/sprites/bg/mountains.png
  assets/sprites/ui/health_pip.png
  assets/sprites/ui/boss_pip.png
  assets/audio/sfx/jump.wav
  assets/audio/sfx/attack.wav
  assets/audio/sfx/hurt.wav
  assets/audio/sfx/hit.wav
  assets/audio/bgm/level.wav

替换方式：同路径覆盖即可，无需改脚本。详见仓库 README 与 assets/LICENSES.md。
