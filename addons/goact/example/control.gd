# example of how to use Goact, attach to any control node in the scene tree

extends Node

# Stateful Components should be preloaded from scripts
const FPSButton: Script = preload("res://addons/goact/example/fps_button.gd")

const BUTTONS_TO_MAKE = 10

# might be a gdscript bug, but if these handles are defined in _ready, they get garbage collected and the unmount in the lambdas will not work
var handle: VirtualTree
var handle2: VirtualTree

func _ready():
	var func_comp: Callable = func(props: Dictionary):
		var list_children = {}
		for i in range(BUTTONS_TO_MAKE):
			list_children["Button"+str(i)] = Element.new(FPSButton, {
				size = props.button_size,
			})
		
		return Goact.create_element("VBoxContainer", {
			size = props.panel_size,
			position = props.panel_position,
		}, list_children)
	
	var element: Element = Goact.create_element(func_comp, {
		panel_position = Vector2(0, 0),
		panel_size = Vector2(300, 200),
		button_size = Vector2(100,100),
		unmount_callback = func():
			Goact.unmount(handle)
	})
	
	var element2: Element = Goact.create_element(func_comp, {
		panel_position = Vector2(500, 0),
		panel_size = Vector2(500, 200),
		button_size = Vector2(100,100),
		unmount_callback = func():
			Goact.unmount(handle2)
	})

	handle = Goact.mount(element, self, "MyNewFunctionalComponent")
	handle2 = Goact.mount(element2, self, "MyNewFunctionalComponent2")
	
func _process(_delta):
	pass