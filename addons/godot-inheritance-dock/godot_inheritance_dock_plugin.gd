tool
extends EditorPlugin

##### CLASSES #####

##### SIGNALS #####

##### CONSTANTS #####

const InheritanceDock = preload("inheritance_dock.tscn")

##### EXPORTS #####

##### MEMBERS #####

# public
var dock = null
var selected = null
var scene_file_dialog = EditorFileDialog.new()
var res_file_dialog = EditorFileDialog.new()

# public onready

# private
var _scene_path = "" # for use in extending scenes
var _res_script_path = "" # for use in assigning a script or type to generated .(t)res files

##### NOTIFICATIONS #####

func _enter_tree():
	dock = InheritanceDock.instance()
	dock.set_name(dock.TITLE)
	add_control_to_dock(DOCK_SLOT_LEFT_UL, dock)
	dock.connect("add_script_request", self, "_on_add_script_request")
	dock.connect("extend_script_request", self, "_on_extend_script_request")
	dock.connect("instance_script_request", self, "_on_instance_script_request")
	dock.connect("edit_script_request", self, "_on_edit_script_request")
	dock.connect("extend_scene_request", self, "_on_extend_scene_request")
	dock.connect("instance_scene_request", self, "_on_instance_scene_request")
	dock.connect("edit_scene_request", self, "_on_edit_scene_request")
	dock.connect("new_res_request", self, "_on_new_res_request")
	dock.connect("edit_res_request", self, "_on_edit_res_request")
	dock.connect("file_selected", self, "_on_file_selected")
	get_editor_interface().get_resource_filesystem().connect("filesystem_changed", dock, "_scan_files")
	get_editor_interface().get_base_control().add_child(scene_file_dialog)
	scene_file_dialog.add_filter("*.tscn,*.scn; Scenes")
	scene_file_dialog.mode = FileDialog.MODE_SAVE_FILE
	scene_file_dialog.get_ok().connect("pressed", self, "_on_save_scene_pressed")
	get_editor_interface().get_base_control().add_child(res_file_dialog)
	res_file_dialog.add_filter("*.tres,*.res; Resources")
	res_file_dialog.mode = FileDialog.MODE_SAVE_FILE
	res_file_dialog.get_ok().connect("pressed", self, "_on_res_file_pressed")

func _exit_tree():
	remove_control_docks(dock)
	dock.queue_free()

##### OVERRIDES #####

##### VIRTUALS #####

##### PUBLIC METHODS #####

##### PRIVATE METHODS #####

# If this isn't call deferred, then you run into "file already exists, overwrite?" popups
func _make_extended_scene():
	var f = File.new()
	var path = scene_file_dialog.get_current_file()
	if not path.begins_with("res://") and not path.begins_with("user://"):
		path = "res://" + path
	if f.open(path, File.WRITE_READ) != OK:
		return
	# If the need ever arrives to revise this, simply create an inherited scene
	# and copy/paste its contents into here. It should remain consistent so long
	# as modifications to the extended version haven't been made yet.
	# TODO: create an API function in Godot to assign a scene's base scene.
	var type = load(_scene_path).get_state().get_node_type(0)
	f.store_string("[gd_scene load_steps=2 format=2]\n\n"
	+"[ext_resource path=\""+_scene_path+"\" type=\"PackedScene\" id=1]\n\n"
	+"[node name=\""+type+"\" index=\"0\" instance=ExtResource( 1 )]\n\n")
	f.close()
	get_editor_interface().open_scene_from_path(path)

func _make_res_file():
	var f = File.new()
	var path = res_file_dialog.get_current_file()
	if f.open(path, File.WRITE_READ) != OK:
		return

	var script = null
	var res_type = null
	if _res_script_path.find(".", 0) != -1:
		script = load(_res_script_path)
		res_type = script.get_instance_base_type() if script else "Resource"
	else:
		script = null
		res_type = _res_script_path
	f.store_string("[gd_resource type=\""+res_type+"\" format=2]\n\n[resource]\n\n")
	f.close()
	var res = load(path)
	res.set_script(script)
	get_editor_interface().edit_resource(script)
	get_editor_interface().edit_resource(res)


##### CONNECTIONS #####

func _on_add_script_request(p_script_path):
	var nodes = get_editor_interface().get_selection().get_selected_nodes()
	var script = load(p_script_path)
	if not script or not ClassDB.can_instance(script.get_instance_base_type()):
		return
	for a_node in nodes:
		a_node.set_script(script)

func _on_extend_script_request(p_script_path):
	var script = load(p_script_path)
	if not script:
		return
	var base_path = "\""+p_script_path+"\""
	var class_path = p_script_path.get_base_dir().plus_file("new_class")
	get_editor_interface().get_script_editor().open_script_create_dialog(base_path, class_path)

func _on_instance_script_request(p_script_path):
	var nodes = get_editor_interface().get_selection().get_selected_nodes()
	var script = load(p_script_path)
	if not script or not ClassDB.can_instance(script.get_instance_base_type()):
		return
	if not nodes.empty():
		get_editor_interface().get_selection().clear()
	for a_node in nodes:
		var new_node = script.new()
		a_node.add_child(new_node)
		new_node.set_owner(get_editor_interface().get_edited_scene_root())
		get_editor_interface().get_selection().add_node(new_node)

func _on_edit_script_request(p_script_path):
	var script = load(p_script_path)
	get_editor_interface().edit_resource(script)

func _on_extend_scene_request(p_scene_path):
	_scene_path = p_scene_path # make the path quickly accessible to connected functions
	scene_file_dialog.popup_centered_ratio()

func _on_instance_scene_request(p_scene_path):
	if get_editor_interface().get_edited_scene_root().get_filename() == p_scene_path:
		var err_dialog = AcceptDialog.new()
		get_editor_interface().get_base_control().add_child(err_dialog)
		err_dialog.get_label().text = "You cannot instance a scene within itself!"
		err_dialog.popup_centered_minsize()
		return
	var nodes = get_editor_interface().get_selection().get_selected_nodes()
	var scene = load(p_scene_path)
	if not scene:
		return
	if not nodes.empty():
		get_editor_interface().get_selection().clear()
	for a_node in nodes:
		var new_node = scene.instance()
		a_node.add_child(new_node)
		new_node.set_owner(get_editor_interface().get_edited_scene_root())
		get_editor_interface().get_selection().add_node(new_node)

func _on_edit_scene_request(p_scene_path):
	get_editor_interface().open_scene_from_path(p_scene_path)

func _on_save_scene_pressed():
	call_deferred("_make_extended_scene")

func _on_res_file_pressed():
	call_deferred("_make_res_file")

func _on_new_res_request(p_script_path):
	_res_script_path = p_script_path # make the path quickly accessible to connection functions
	res_file_dialog.popup_centered_ratio()

func _on_edit_res_request(p_res_path):
	var res = load(p_res_path)
	get_editor_interface().edit_resource(res)

func _on_file_selected(p_file):
	get_editor_interface().select_file(p_file)

##### SETTERS AND GETTERS #####
