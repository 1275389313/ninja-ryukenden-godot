本项目所有美术为占位资源，正式资源放入 assets/ 后按同名替换。

占位纹理统一由脚本 res://scripts/components/placeholder_texture.gd
中的 PlaceholderTexture.make(size, color) 在运行时生成纯色 ImageTexture，
不要在 assets/ 中提交临时图片文件。
