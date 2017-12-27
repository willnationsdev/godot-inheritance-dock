tool
extends BaseButton

export var hover_color = Color(1.0, 1.0, 1.0, 0.7)
export var natural_color = Color(1.0, 1.0, 1.0, 1.0)
export var pressed_color = Color("54b7e7")
export var disabled_color = Color(0.5, 0.5, 0.5, 1.0)
export var use_material_pressed = true

var hovering = false

func _ready():
	connect("mouse_entered", self, "on_mouse_entered")
	connect("mouse_exited", self, "on_mouse_exited")
	if toggle_mode:
		connect("toggled", self, "on_toggled")
	else:
		connect("button_down", self, "on_button_down")
		connect("button_up", self, "on_button_up")
	if use_material_pressed and not material:
		use_material_pressed = false
	if pressed:
		update_button_group()

func on_mouse_entered():
	hovering = true
	if not pressed and not toggle_mode and not disabled:
		self_modulate = hover_color

func on_mouse_exited():
	hovering = false
	if not pressed and not toggle_mode and not disabled:
		self_modulate = natural_color

func on_button_down():
	if hovering:
		update_button_group()

func on_button_up():
	self_modulate = hover_color
	if use_material_pressed:
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX

func on_toggled(p_toggle):
	if p_toggle:
		update_button_group()

func update_button_group():
	if not group:
		pressed = true
		if use_material_pressed:
			material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
		else:
			self_modulate = pressed_color
		return
	for node in get_parent().get_children():
		if node is BaseButton and node.group == group:
			if node != self:
				if node.pressed:
					node.pressed = false
					if node.use_material_pressed:
						node.material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
					else:
						node.self_modulate = natural_color
			else:
				pressed = true
				if use_material_pressed:
					material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
				else:
					self_modulate = pressed_color


# hi
