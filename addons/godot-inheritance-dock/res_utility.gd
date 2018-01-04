# A collection of shared static functions for the plugin's nodes
tool
extends Reference

##### CLASSES #####

##### SIGNALS #####

##### CONSTANTS #####

const REGEX_EXT_SCRIPT = "\\.gd|\\.vs|\\.cs|\\.gdns"
const REGEX_EXT_SCENE = "\\.t?scn"
const REGEX_EXT_RES = "\\.t?res"

enum { SORT_SCENE_INHERITANCE, SORT_SCRIPT_INHERITANCE, SORT_RES_INHERITANCE }

const REGEX = {
	SORT_SCRIPT_INHERITANCE: REGEX_EXT_SCRIPT,
	SORT_SCENE_INHERITANCE: REGEX_EXT_SCENE,
	SORT_RES_INHERITANCE: REGEX_EXT_RES
}

##### EXPORTS #####

##### MEMBERS #####

##### NOTIFICATIONS #####

##### OVERRIDES #####

##### VIRTUALS #####

##### PUBLIC METHODS #####

static func search_res(p_regex = ""):
	var regex = null
	if p_regex:
		regex = RegEx.new()
		regex.compile(p_regex)
		if not regex.is_valid():
			print("WARNING: (res://addons/godot-inheritance-dock/res_utility.gd::search_res) regex failed to compile: ", p_regex)
			return {}	

	var dirs = ["res://"]
	var first = true
	var data = {}
	while not dirs.empty():
		var dir = Directory.new()
		var dir_name = dirs.back()
		dirs.pop_back()

		if dir.open(dir_name) == OK:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if not dir_name == "res://":
					first = false
				# ignore hidden content
				if not file_name.begins_with("."):
					# If a directory, then add to list of directories to visit
					if dir.current_is_dir():
						dirs.push_back(dir.get_current_dir() + "/" + file_name)
					# If a file, check if we already have a record for the same name
					else:
						if not data.has(file_name):
							# if not regex, setup a default value
							var path = dir.get_current_dir() + ("/" if not first else "") + file_name
							if not p_regex:
								data[file_name] = {
									"path": path,
									"title": file_name
								}
							else:
								# if regex, check for a match. Only create a record if there is a match
								var regex_match = regex.search(file_name)
								if regex_match != null:
									if not data.has(file_name):
										# people can provide an alternate label by capturing a "title" group
										var filter_name = regex_match.get_string("title")
										data[file_name] = {
											"path": path,
											"title": filter_name if filter_name else file_name
										}
				# Move on to the next file in this directory
				file_name = dir.get_next()
			# We've exhausted all files in this directory. Close the iterator.
			dir.list_dir_end()
	return data

static func build_file_tree_dict(p_sort = SORT_SCENE_INHERITANCE):
	# Initialize the tree dict
	var r_root = {
		"children": {}
	}

	# fetch all new files from res://
	var this = load("res://addons/godot-inheritance-dock/res_utility.gd")
	assert(this)
	var temp_files = this.search_res(REGEX[p_sort])
	var inserted_map = {}

	for a_filename in temp_files:
		var file_path = temp_files[a_filename]["path"]
		if file_path.get_extension() in ["tmp", "import"]:
			continue

		var file_hierarchy = []

		var resource = load(file_path)

		match p_sort:
			SORT_SCRIPT_INHERITANCE:
				while resource:
					file_hierarchy.push_front(resource.resource_path)
					resource = resource.get_base_script()
			SORT_SCENE_INHERITANCE:
				while resource:
					file_hierarchy.push_front(resource.resource_path)
					resource = resource.get_state().get_node_instance(0)
			SORT_RES_INHERITANCE:
				file_hierarchy.push_front(resource.resource_path)
				var type = resource.get_class()
				var script = resource.get_script()
				while script:
					file_hierarchy.push_front(script.resource_path)
					script = script.get_base_script()
				while type != "Reference":
					file_hierarchy.push_front(type)
					type = ClassDB.get_parent_class(type)
		
		if file_path.find("res://addons/", 0) != -1:
			var plugin_sub_path = file_path.replace("res://addons/", "")
			var plugin_name = plugin_sub_path.substr(0, plugin_sub_path.find("/",0))
			file_hierarchy.push_front("/"+plugin_name+"/")
		else:
			file_hierarchy.push_front("res://")
		
		var section = file_hierarchy.front()
		if not inserted_map.has(section):
			inserted_map[section] = {}
		
		var file = r_root
		for a_file_path in file_hierarchy:
			if not inserted_map[section].has(a_file_path):
				var new_file = {
					"children": {}
				}
				inserted_map[section][a_file_path] = new_file
				file["children"][a_file_path] = new_file
				file = new_file
			else:
				file = inserted_map[section][a_file_path]
		
	return r_root

##### PRIVATE METHODS #####

##### CONNECTIONS #####

##### SETTERS AND GETTERS #####
