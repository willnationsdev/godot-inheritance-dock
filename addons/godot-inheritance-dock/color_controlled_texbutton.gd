tool
extends "color_controlled_button.gd"

export(Texture) var default_tex = null

func _ready():
	if self is TextureButton:
		if not self.texture_normal:
			self.texture_normal = default_tex
		if not self.texture_pressed:
			self.texture_pressed = default_tex
		if not self.texture_hover:
			self.texture_hover = default_tex
		if not self.texture_disabled:
			self.texture_disabled = default_tex
