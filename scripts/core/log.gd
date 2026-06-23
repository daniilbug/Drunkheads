extends Object
class_name Log

var _tag: String

func _init(tag: String) -> void:
	self._tag = tag

func log(message: String) -> void:
	print("[%s] %s" % [self._tag, message])
