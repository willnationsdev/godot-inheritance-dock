tool
extends PanelContainer

##### CLASSES #####

##### SIGNALS #####

signal load_failed
signal add_script_request(p_script_path)
signal extend_script_request(p_script_path)
signal instance_script_request(p_script_path)
signal edit_script_request(p_script_path)
signal extend_scene_request(p_scene_path)
signal instance_scene_request(p_scene_path)
signal edit_scene_request(p_scene_path)
signal edit_res_request(p_res_path)
signal file_selected(p_file)

##### CONSTANTS #####

enum Mode { SCENE_MODE=0, SCRIPT_MODE=1, RES_MODE=2 }

const Util = preload("res_utility.gd")
const FilterMenuScene = preload("filter_menu.tscn")

const TITLE = "Inheritance"
const SCRIPT_ICON = preload("icons/icon_script.svg")
const RES_ICON = preload("icons/icon_resource.svg")
const SCENE_ICON = preload("icons/icon_scene.svg")
const BASETYPE_ICON = preload("icons/icon_basetype.svg")
const ICONS = {
	RES_MODE: RES_ICON,
	SCRIPT_MODE: SCRIPT_ICON,
	SCENE_MODE: SCENE_ICON
}

##### EXPORTS #####

##### MEMBERS #####

# public
var filters = []
var files = []
var selected = null
var filter_popup = null
var tree = null
var tree_dict = null

# public onready
onready var scene_tab_button = $VBoxContainer/TypeContainer/Scenes
onready var script_tab_button = $VBoxContainer/TypeContainer/Scripts
onready var resource_tab_button = $VBoxContainer/TypeContainer/Resources
onready var filter_menu_button = $VBoxContainer/HBoxContainer/FilterContainer/FilterMenuButton
onready var scene_tree = $VBoxContainer/TabContainer/Scenes
onready var script_tree = $VBoxContainer/TabContainer/Scripts
onready var resource_tree = $VBoxContainer/TabContainer/Resources
onready var search_edit = $VBoxContainer/SearchContainer/LineEdit
onready var add_script_button = $VBoxContainer/HBoxContainer/ToolContainer/AddScriptButton
onready var extend_button = $VBoxContainer/HBoxContainer/ToolContainer/ExtendButton
onready var instance_button = $VBoxContainer/HBoxContainer/ToolContainer/InstanceButton
onready var find_button = $VBoxContainer/HBoxContainer/ToolContainer/FindButton
onready var tab = $VBoxContainer/TabContainer

# private
var _config = ConfigFile.new()
var _config_loaded = false
var _scene_dict = null
var _script_dict = null
var _resource_dict = null
var _original_files = []
var _sort = Util.SORT_SCENE_INHERITANCE
var _mode = Mode.SCENE_MODE setget set_mode
var _scene_filter_popup = null
var _script_filter_popup = null
var _resource_filter_popup = null
var _search_filter = "" setget set_search_filter
var _ready_done = false

##### NOTIFICATIONS #####

func _init():
	_init_config()
	if not _config_loaded:
		emit_signal("load_failed")

func _ready():
	if not _config_loaded:
		return
	
	# Connections
	search_edit.connect("text_changed", self, "_on_search_text_changed")
	scene_tab_button.connect("pressed", self, "_on_scene_tab_button_pressed")
	script_tab_button.connect("pressed", self, "_on_script_tab_button_pressed")
	resource_tab_button.connect("pressed", self, "_on_resource_tab_button_pressed")
	add_script_button.connect("pressed", self, "_on_add_script_button_pressed")
	extend_button.connect("pressed", self, "_on_extend_button_pressed")
	instance_button.connect("pressed", self, "_on_instance_button_pressed")
	find_button.connect("pressed", self, "_on_find_button_pressed")
	filter_menu_button.connect("pressed", self, "_on_filter_menu_button_pressed")

	# Filters Initialization
	_scene_filter_popup = FilterMenuScene.instance()
	add_child(_scene_filter_popup)
	_scene_filter_popup.type = "scene"
	_scene_filter_popup.connect("filters_updated", self, "_update_filters")
	_scene_filter_popup.set_config(_config)
	
	_script_filter_popup = FilterMenuScene.instance()
	add_child(_script_filter_popup)
	_script_filter_popup.type = "script"
	_script_filter_popup.connect("filters_updated", self, "_update_filters")
	_script_filter_popup.set_config(_config)
	
	_resource_filter_popup = FilterMenuScene.instance()
	add_child(_resource_filter_popup)
	_resource_filter_popup.type = "resource"
	_resource_filter_popup.connect("filters_updated", self, "_update_filters")
	_resource_filter_popup.set_config(_config)
	
	# UI Initialization
	set_mode(_mode)
	
	_ready_done = true

func _input(event):
	if event is InputEventMouseButton:
		if event.doubleclick and event.button_index == BUTTON_LEFT:
			if not tree:
				print("WARNING: (inheritance_dock.gd: 108) 'tree' is Nil!")
				return
			var item = tree.get_selected()
			if item:
				match _mode:
					SCENE_MODE, SCRIPT_MODE:
						emit_signal("edit_"+_mode_to_name()+"_request", item.get_metadata(0))
					RES_MODE:
						var meta = item.get_metadata(0)
						var ext = meta.get_extension()
						if ext:
							var is_res = ext.find("res", 0) != -1
							emit_signal("edit_"+ ("res" if is_res else "script") +"_request", meta)
						elif meta.find(".", 0) == -1:
							pass # TODO: It's an in-engine type. Open class API

##### OVERRIDES #####

##### VIRTUALS #####

##### PUBLIC METHODS #####

##### PRIVATE METHODS #####

func _init_config():
	var err = _config.load("res://addons/godot-inheritance-dock/godot_inheritance_dock.cfg")
	if err != OK:
		print("InheritanceDock-WARNING: godot_inheritance_dock.cfg failed to load!")
	_config_loaded = true
	if _config.has_section_key("window", "rect_min_size"):
		rect_min_size = _config.get_value("window", "rect_min_size")
	else:
		rect_min_size = Vector2(0,50)

func _init_files():
	_scene_dict = Util.build_file_tree_dict(Util.SORT_SCENE_INHERITANCE)
	_build_tree_from_tree_dict(scene_tree, _scene_dict)
	_script_dict = Util.build_file_tree_dict(Util.SORT_SCRIPT_INHERITANCE)
	_build_tree_from_tree_dict(script_tree, _script_dict)
	_resource_dict = Util.build_file_tree_dict(Util.SORT_RES_INHERITANCE)
	_build_tree_from_tree_dict(resource_tree, _resource_dict)
	match _mode:
		Mode.SCRIPT_MODE:
			tree = script_tree
			tree_dict = _script_dict
		Mode.RES_MODE:
			tree = resource_tree
			tree_dict = _resource_dict
		Mode.SCENE_MODE, _:
			tree = scene_tree
			tree_dict = _scene_dict

func _mode_to_name():
	match _mode:
		Mode.SCRIPT_MODE: return "script"
		Mode.RES_MODE: return "resource"
		Mode.SCENE_MODE, _: return "scene"

func _build_tree_from_tree_dict(p_tree, p_tree_dict):
	if not p_tree or not p_tree_dict or not _ready_done:
		return null
	p_tree.clear()
	p_tree.set_hide_root(true)
	p_tree.set_select_mode(Tree.SELECT_SINGLE)
	#p_tree.set_columns(2)
	#p_tree.set_column_min_width(0, 2)
	#p_tree.set_column_min_width(1, 6)
	var root = p_tree.create_item()

	var file = p_tree_dict
	var item = root
	var file_list = [file]
	var item_list = [item]

	while not file_list.empty():
		file = file_list.back()
		item = item_list.back()

		for a_filepath in file["children"]:
			var child = file["children"][a_filepath]
			var do_create = true

			if _search_filter and a_filepath.find(_search_filter) == -1:
				do_create = false
			if filter_popup:
				for a_regex in filter_popup.get_filters():
					if not a_regex.search(a_filepath):
						do_create = false
						break

			if do_create:
				var new_item = p_tree.create_item(item)
				new_item.set_text(0, a_filepath.get_file())
				new_item.set_tooltip(0, a_filepath)
				new_item.set_metadata(0, a_filepath)
				new_item.set_editable(0, false)
				match _mode:
					RES_MODE:
						var ext = a_filepath.get_extension()
						if a_filepath.find(".", 0) == -1:
							ext = ""
						var img = null
						if not ext:
							img = BASETYPE_ICON
						elif ext.find("res", 0) != -1:
							img = RES_ICON
						else:
							img = SCRIPT_ICON
						new_item.set_icon(0, img)
						new_item.set_selectable(0, ext != "")
					SCENE_MODE, SCRIPT_MODE, _:
						new_item.set_icon(0, ICONS[_mode])
						new_item.set_selectable(0, true)
			
				file_list.push_front(child)
				item_list.push_front(new_item)
	
		if not file_list.empty():
			file_list.pop_back()
			item_list.pop_back()

##### CONNECTIONS #####

func _on_scene_tab_button_pressed():
	set_mode(Mode.SCENE_MODE)

func _on_script_tab_button_pressed():
	set_mode(Mode.SCRIPT_MODE)

func _on_resource_tab_button_pressed():
	set_mode(Mode.RES_MODE)

func _on_search_text_changed(p_text):
	set_search_filter(p_text)

func _on_add_script_button_pressed():
	if script_tree and script_tree.get_selected():
		emit_signal("add_script_request", script_tree.get_selected().get_metadata(0))

func _on_extend_button_pressed():
	if tree and tree.get_selected():
		emit_signal("extend_"+_mode_to_name()+"_request", tree.get_selected().get_metadata(0))

func _on_instance_button_pressed():
	if tree and tree.get_selected():
		emit_signal("instance_"+_mode_to_name()+"_request", tree.get_selected().get_metadata(0))

func _on_find_button_pressed():
	if tree and tree.get_selected():
		emit_signal("file_selected", tree.get_selected().get_metadata(0))

func _on_file_selected(p_file):
	emit_signal("file_selected", p_file)

func _on_filter_menu_button_pressed():
	print("filter_menu_button_pressed")
	if not filter_popup:
		return
	print("popping up")
	filter_popup.visible = !filter_popup.visible
	if filter_popup.visible:
		var x = Vector2(get_tree().get_root().size.x,0) / 2
		var pos = filter_menu_button.get_global_position()
		var side = 1 if pos > x else 0
		print(side)
		filter_popup.set_global_position(filter_menu_button.get_global_position()+Vector2(side * -300,20))

func _update_filters(p_filters = []):
	_build_tree_from_tree_dict(tree, tree_dict)

func _scan_files():
	print("Scanning files")
	if scene_tree:
		scene_tree.clear()
	if script_tree:
		script_tree.clear()
	if resource_tree:
		resource_tree.clear()
	_init_files()
	_original_files = files.duplicate()

##### SETTERS AND GETTERS #####

func set_mode(p_mode):
	_mode = p_mode
	tab.current_tab = p_mode
	if filter_popup:
		filter_popup.visible = false
	match p_mode:
		Mode.SCRIPT_MODE:
			filter_popup = _script_filter_popup
			_sort = Util.SORT_SCRIPT_INHERITANCE
			add_script_button.disabled = false
			add_script_button.self_modulate = add_script_button.natural_color
			extend_button.disabled = false
			extend_button.self_modulate = extend_button.natural_color
			instance_button.disabled = false
			instance_button.self_modulate = extend_button.natural_color
			tree = script_tree
			tree_dict = _script_dict
		Mode.RES_MODE:
			filter_popup = _resource_filter_popup
			_sort = Util.SORT_RES_INHERITANCE
			add_script_button.disabled = true
			add_script_button.self_modulate = add_script_button.disabled_color
			extend_button.disabled = true
			extend_button.self_modulate = extend_button.disabled_color
			instance_button.disabled = true
			instance_button.self_modulate = extend_button.disabled_color
			tree = resource_tree
			tree_dict = _resource_dict
		Mode.SCENE_MODE, _:
			filter_popup = _scene_filter_popup
			_sort = Util.SORT_SCENE_INHERITANCE
			add_script_button.disabled = true
			add_script_button.self_modulate = add_script_button.disabled_color
			extend_button.disabled = false
			extend_button.self_modulate = extend_button.natural_color
			instance_button.disabled = false
			instance_button.self_modulate = extend_button.natural_color
			tree = scene_tree
			tree_dict = _scene_dict
	search_edit.placeholder_text = "filter " + _mode_to_name() + "s"
	_build_tree_from_tree_dict(tree, tree_dict)
	
func set_search_filter(p_value):
	_search_filter = p_value
	_build_tree_from_tree_dict(tree, tree_dict)
