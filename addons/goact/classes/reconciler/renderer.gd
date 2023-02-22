class_name Renderer

func is_host_node(target: Variant) -> bool:
    return typeof(target) == null

func mount_host_node(_reconciler: Reconciler, _node: VirtualNode):
    pass

func unmount_host_node(_reconciler: Reconciler, _node: VirtualNode):
    pass

func update_host_node(_reconciler: Reconciler, _node: VirtualNode, _newElement: Element):
    pass