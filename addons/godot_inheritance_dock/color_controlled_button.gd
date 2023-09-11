@tool
extends BaseButton

@export var hover_color = Color(1.0, 1.0, 1.0, 0.7)
@export var natural_color = Color(1.0, 1.0, 1.0, 1.0)
@export var pressed_color = Color("54b7e7")
@export var disabled_color = Color(0.5, 0.5, 0.5, 1.0)
@export var use_material_pressed = true

var hovering = false

func _ready():
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)
	if toggle_mode:
		toggled.connect(on_toggled)
	else:
		button_down.connect(on_button_down)
		button_up.connect(on_button_up)
	if use_material_pressed and not material:
		use_material_pressed = false
	if button_pressed:
		update_button_group()

func on_mouse_entered():
	hovering = true
	if not button_pressed and not toggle_mode and not disabled:
		self_modulate = hover_color

func on_mouse_exited():
	hovering = false
	if not button_pressed and not toggle_mode and not disabled:
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
	if not button_group:
		button_pressed = true
		if use_material_pressed:
			material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
		else:
			self_modulate = pressed_color
		return
	for node in get_parent().get_children():
		if node is BaseButton and node.button_group == button_group:
			if node != self:
				if node.button_pressed:
					node.button_pressed = false
					if node.use_material_pressed:
						node.material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
					else:
						node.self_modulate = natural_color
			else:
				button_pressed = true
				if use_material_pressed:
					material.blend_mode = CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
				else:
					self_modulate = pressed_color
