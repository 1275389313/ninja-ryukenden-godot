class_name PlaceholderTexture
## 通用占位纹理工具：生成纯色 ImageTexture。
## 所有占位精灵统一使用它，避免外部图片依赖。

static func make(size: Vector2i, color: Color) -> ImageTexture:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
