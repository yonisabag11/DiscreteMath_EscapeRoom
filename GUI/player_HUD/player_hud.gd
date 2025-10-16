extends CanvasLayer


var hearts : Array[ HeartGUI ] = []


func _ready():
	for child in $Control/HFlowContainer.get_children():
		if child is HeartGUI:
			hearts.append( child )
			child.visible = false
	update_hp(6, 6)



func update_hp(_hp: int, _max_hp: int) -> void:
	update_max_hp(_max_hp)
	for i in range(hearts.size()):
		update_heart(i, _hp)


func update_heart(_index: int, _hp: int) -> void:
	var _value: int = clampi(_hp - _index * 2, 0, 2)
	hearts[_index].value = _value


func update_max_hp(_max_hp: int) -> void:
	var _heart_count: int = int(round(_max_hp * 0.5))
	for i in range(hearts.size()):
		hearts[i].visible = i < _heart_count
