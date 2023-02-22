class_name Element

enum ElementKind {
    Host,
    Function,
    Stateful,
    Portal,
    Fragment
}

const COMPONENT_TYPE_TO_KIND: Dictionary = {
    TYPE_STRING: ElementKind.Host,
    TYPE_CALLABLE: ElementKind.Function,
}
const MULTIPLE_CHILDREN_MESSAGE: String = """
    The prop `Goact.Children` was defined but was overridden by the third parameter to create_element!
    This can happen when a component passes props through to a child element but also uses the `children` argument:
    
        Roact.createElement('Frame', passed_props, {
            child = ...
        })
    
    Instead, consider using a utility function to merge tables of children together:
    
        var children = merge_tables(passed_props[Goact.Children], {
            child = ...
        })
    
        var full_props = merge_tables(passed_props, {
            [Goact.Children] = children
        })
    
        Goact.create_element('Frame', full_props)
"""

var element_kind: ElementKind #todo define element kind enums in singleton
var component: Variant # type can be a StatefulComponent (Resource), Function (Callable), Host (String -> Godot Node), or Portal (Symbol)
var props: Dictionary

var source: String # for debug tracebacks

static func from_component(_component: Variant) -> ElementKind:
    if typeof(_component) == TYPE_OBJECT:
        if _component is Symbol and _component == Goact.Portal:
            return ElementKind.Portal
        if _component is Script:
            return ElementKind.Stateful
    
    return COMPONENT_TYPE_TO_KIND[typeof(_component)]

func _init(_component, _props: Dictionary = {}, _children = null):
    if _children:
        if _props.has(Goact.Children):
            push_warning(MULTIPLE_CHILDREN_MESSAGE)
        _props[Goact.Children] = _children
    
    # makes things a lot easier having ref be indexable
    if not _props.has(Goact.Ref):
        _props[Goact.Ref] = null

    if not _props.has(Goact.Children):
        _props[Goact.Children] = null

    self.element_kind = Element.from_component(_component)
    self.component = _component
    self.props = _props

func _to_string():
    return "[Element]: {
        component: {0}
        props: {1}
    }".format([self.component, self.props])