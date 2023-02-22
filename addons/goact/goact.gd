@tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("Goact", "res://addons/goact/singletons/goact.gd")
	add_autoload_singleton("ElementUtils", "res://addons/goact/singletons/element_utils.gd")

func _exit_tree():
	remove_autoload_singleton("ElementUtils")

