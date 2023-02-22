class_name VirtualTree

var root_node: VirtualNode
var mounted: bool = true

func set_root_node(root: VirtualNode):
    self.root_node = root