tool
extends PopupPanel

##### CLASSES #####

##### SIGNALS #####

signal filters_updated
signal item_sync_requested(p_popup, p_item)

##### CONSTANTS #####

const FilterMenuItemScene = preload("filter_menu_item.tscn")

const CONFIG_PATH = "res://addons/godot-inheritance-dock/godot_inheritance_dock.cfg"

##### EXPORTS #####

##### MEMBERS #####

# public
var filters = [] setget set_filters, get_filters
var type = ""

# public onready
onready var add_filter_button = $PanelContainer/VBoxContainer/HBoxContainer/AddFilterButton
onready var save_filters_button = $PanelContainer/VBoxContainer/HBoxContainer/SaveFiltersButton
onready var reload_filters_button = $PanelContainer/VBoxContainer/HBoxContainer/ReloadFiltersButton
onready var filter_vbox = $PanelContainer/VBoxContainer/FilterVbox

# private
var _config = null setget set_config

##### NOTIFICATIONS #####

func _ready():
	add_filter_button.connect("pressed", self, "_on_add_filter_button_pressed")
	save_filters_button.connect("pressed", self, "_on_save_filters_button_pressed")
	reload_filters_button.connect("pressed", self, "_on_reload_filters_button_pressed")
	reload_filters_button.disabled = false
	call_deferred("_set_save_disabled", true)

##### OVERRIDES #####

##### VIRTUALS #####

##### PUBLIC METHODS #####

func add_filter(p_name = "", p_regex_text = "", p_checked = false):
	var item = FilterMenuItemScene.instance()
	filter_vbox.add_child(item)
	_setup_item(item, p_name, p_regex_text, p_checked)

##### PRIVATE METHODS #####

# 1. on check pressed, emit "filters_updated"
# 2. on regex text changed, update icon
func _setup_item(p_item, p_name = "", p_regex_text = "", p_checked = false):
	if not p_item:
		return
	p_item.connect("checkbox_updated", self, "_update_filters") 
	p_item.connect("regex_updated", self, "_update_filters")
	p_item.connect("name_updated", self, "_ui_dirtied")
	p_item.connect("item_removed", self, "_ui_dirtied")
	p_item.connect("item_sync_requested", self, "_on_item_sync_requested")
	p_item.name_edit.text = p_name
	p_item.regex_edit.text = p_regex_text
	p_item.check.pressed = p_checked

func _ui_dirtied():
	if save_filters_button:
		_set_save_disabled(false)

func _update_filters():
	emit_signal("filters_updated")
	_ui_dirtied()

func _get_config_save_filters_dict():
	var dict = {}
	if not filter_vbox:
		return filters
	for an_item in filter_vbox.get_children():
		if not an_item.name_edit.text:
			continue
		dict[an_item.name_edit.text] = {
			"regex_text": an_item.get_regex().get_pattern(),
			"on": an_item.check.pressed
		}
	return dict

func _set_save_disabled(p_disabled):
	save_filters_button.self_modulate = save_filters_button.disabled_color if p_disabled else save_filters_button.natural_color
	save_filters_button.disabled = p_disabled

##### CONNECTIONS #####

func _on_add_filter_button_pressed():
	var item = FilterMenuItemScene.instance()
	filter_vbox.add_child(item)
	add_filter()
	_update_filters()

func _on_save_filters_button_pressed():
	if not _config:
		return
	_config.set_value("filters", type+"_filters", _get_config_save_filters_dict())
	_config.save(CONFIG_PATH)
	_set_save_disabled(true)

func _on_reload_filters_button_pressed():
	if not _config:
		print("WARNING: (res://addons/godot-inheritance-dock/filter_menu.gd::_on_reload_filters_button_pressed) Cannot reload filters! Reason: invalid config reference")
		return
	var new_filters = _config.get_value("filters", type+"_filters")
	set_filters(new_filters)
	_set_save_disabled(true)

func _on_item_sync_requested(p_item):
	emit_signal("item_sync_requested", self, p_item)

##### SETTERS AND GETTERS #####

func set_config(p_config):
	_config = p_config
	if _config.has_section_key("filters", type+"_filters"):
		set_filters(_config.get_value("filters", type+"_filters"))

func set_filters(p_filters = {}):
	if not filter_vbox:
		return
	
	for a_child in filter_vbox.get_children():
		a_child.queue_free()
	
	for a_name in p_filters:
		var regex_text = p_filters[a_name]["regex_text"]
		var checked = p_filters[a_name]["on"]
		add_filter(a_name, regex_text, checked)
	_update_filters()

func get_filters():
	var filters = []
	if not filter_vbox:
		return filters
	for an_item in filter_vbox.get_children():
		if an_item.check.pressed and an_item.is_valid():
			filters.append(an_item.get_regex())
	return filters
