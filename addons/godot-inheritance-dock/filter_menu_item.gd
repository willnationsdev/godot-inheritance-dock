tool
extends HBoxContainer

##### CLASSES #####

##### SIGNALS #####

signal checkbox_updated
signal name_updated
signal regex_updated
signal item_removed
signal item_sync_requested(p_item)

##### CONSTANTS #####

const REGEX_OK = preload("icons/icon_import_check.svg")
const REGEX_ERROR = preload("icons/icon_error_sign.svg")
const REGEX_MAP = {
	true: REGEX_OK,
	false: REGEX_ERROR
}

##### EXPORTS #####

##### MEMBERS #####

# public

# public onready
onready var check = $CheckBox
onready var name_edit = $NameEdit
onready var regex_edit = $RegExEdit
onready var sync_button = $SyncButton
onready var remove_button = $RemoveButton
onready var regex_valid = $RegExValid

# private
var _regex = RegEx.new() setget , get_regex

##### NOTIFICATIONS #####

func _ready():
	check.connect("toggled", self, "_on_check_toggled")
	name_edit.connect("text_changed", self, "_on_name_edit_text_changed")
	regex_edit.connect("text_changed", self, "_on_regex_edit_text_changed")
	sync_button.connect("pressed", self, "_on_sync_button_pressed")
	remove_button.connect("pressed", self, "_on_remove_button_pressed")
	_update_regex_valid()

##### OVERRIDES #####

##### VIRTUALS #####

##### PUBLIC METHODS #####

func is_valid():
	return _regex.is_valid() and _regex.get_pattern()

##### PRIVATE METHODS #####

func _update_regex_valid():
	regex_valid.texture = REGEX_MAP[is_valid()]

##### CONNECTIONS #####

func _on_check_toggled(p_toggle):
	emit_signal("checkbox_updated")

func _on_name_edit_text_changed(p_text):
	emit_signal("name_updated")

func _on_regex_edit_text_changed(p_text):
	_regex.compile(p_text)
	_update_regex_valid()
	emit_signal("regex_updated")

func _on_sync_button_pressed():
	emit_signal("item_sync_requested", self)

func _on_remove_button_pressed():
	emit_signal("item_removed")
	queue_free()

##### SETTERS AND GETTERS ####!#

func get_regex():
	return _regex
