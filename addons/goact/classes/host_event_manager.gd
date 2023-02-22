class_name HostEventManager

enum EventStatus {
    DISABLED,
    SUSPENDED,
    ENABLED,
}

# The Godot Node the manager is managing
var _instance: Node

# The queue of suspended events
var _suspended_event_queue: Array

# All the event connections being managed
# Events are indexed by a string key
var _connections: Dictionary

#   All the listeners being managed
#   These are stored distinctly from the connections
#   Connections can have their listeners replaced at runtime
var _listeners: Dictionary

#   The suspension status of the manager
#   Managers start disabled and are "resumed" after the initial render
var _status: EventStatus = EventStatus.DISABLED

#   If true, the manager is processing queued events right now.
var _is_resuming: bool = false


func _init(instance: Node):
    _suspended_event_queue = []
    _connections = {}
    _listeners = {}
    _instance = instance


func _connect(event_key: String, event: Signal, listener: Variant = null): # listener should be a callable or null
    # If the listener doesn't exist we can just disconnect the existing connection
    if typeof(listener) == TYPE_NIL:
        if _connections.has(event_key):
            var signal_listener: Array = _connections[event_key] # [Signal, Callable]
            signal_listener[0].disconnect(signal_listener[1])
            _connections.erase(event_key)
        
        _listeners.erase(event_key)
    else:
        if not _connections.has(event_key):
            var bound_callable = Goact.pack_args(func(signal_args: Array):
                if _status == EventStatus.ENABLED:
                    # call our listener with signal_args
                    _listeners[event_key].call(self._instance, signal_args)
                elif _status == EventStatus.SUSPENDED:
                    _suspended_event_queue.append([event_key, signal_args])
            )
            var _errmsg: int = event.connect(bound_callable)
            assert(_errmsg == OK, "Could not bind callable to event: " + str(_errmsg))
            # event went through successfully, add to active connections
            _connections[event_key] = [event, bound_callable]

        _listeners[event_key] = listener # its ok if there's already a listener set up, as it calls whatever is set to this key, no bindings necessary


func connect_event(key: String, listener: Variant = null):
    if not _instance.has_signal(key):
        #error
        return

    _connect(key, _instance.get(key), listener)


# godot does not have a way to get node property change signals like roblox does, so this might have to wait (or stay unimplemented)
func connect_property_change(_key, _listener):
    pass


func suspend():
    _status = EventStatus.SUSPENDED


func resume():
    # If we're already resuming events for this instance, trying to resume
	# again would cause a disaster.
    if _is_resuming: 
        return
    
    _is_resuming = true

    var index: int = 0

	# More events might be added to the queue when evaluating events, so we
	# need to be careful in order to preserve correct evaluation order.
    while index < _suspended_event_queue.size():
        #resume listeners
        var event_invocation = _suspended_event_queue[index]
        var key: String = event_invocation[0]
        if _listeners.has(key):
            _listeners[key].call_deferred(self._instance, event_invocation[1])

        index += 1

    _is_resuming = false
    _status = EventStatus.ENABLED
    _suspended_event_queue = []
    