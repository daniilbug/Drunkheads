class_name TransportStop
extends Marker2D

# Both services reserve the same bay before spawning a vehicle. A reservation
# lasts until that vehicle leaves the road, so nobody blocks its approach.
var _bay_owner: Node
var _waiting_services: Array[Node] = []

func request_bay(service: Node) -> bool:
	if not multiplayer.is_server():
		return false
	if _bay_owner == service:
		return true
	if not _waiting_services.has(service):
		_waiting_services.append(service)
	if is_instance_valid(_bay_owner):
		return false
	while not _waiting_services.is_empty() and not is_instance_valid(_waiting_services[0]):
		_waiting_services.pop_front()
	if not _waiting_services.is_empty() and _waiting_services[0] == service:
		_waiting_services.pop_front()
		_bay_owner = service
		return true
	return false

func release_bay(service: Node) -> void:
	if _bay_owner == service:
		_bay_owner = null
	_waiting_services.erase(service)

func get_exit_position(passenger_index := 0) -> Vector2:
	# Spread the group along the pavement while keeping the first exit by the door.
	var side := 1.0 if passenger_index % 2 == 1 else -1.0
	var offset := Vector2(ceilf(passenger_index / 2.0) * 12.0 * side, 0)
	return to_global(($PassengerExit as Marker2D).position + offset)
