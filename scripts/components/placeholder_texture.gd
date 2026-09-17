class_name PlaceholderTexture
## 通用占位纹理工具：生成纯色 ImageTexture。
## GameAssets 在 assets/sprites 文件缺失时回退到这里，游戏不应因此崩溃。

static func make(size: Vector2i, color: Color) -> ImageTexture:
	var img := Image.create(maxi(1, size.x), maxi(1, size.y), false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
