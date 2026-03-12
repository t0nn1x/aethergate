# addons/aethergate_ui_builder/panels/inspector/ui_builder_inspector.gd
@tool
extends VBoxContainer

signal property_changed(node: Control, property: StringName, value: Variant)

@onready var _node_label: Label = %NodeLabel
@onready var _props_container: VBoxContainer = %PropertiesContainer

var _target: Control = null


func inspect(node: Control) -> void:
	_target = node
	_rebuild()


func _rebuild() -> void:
	for child in _props_container.get_children():
		child.queue_free()

	if _target == null:
		_node_label.text = "(nothing selected)"
		return

	_node_label.text = _target.get_class() + " — " + _target.name

	_add_section_header("RECT")
	_add_float_row("X", "position:x", _target.position.x)
	_add_float_row("Y", "position:y", _target.position.y)
	_add_float_row("W", "size:x", _target.size.x)
	_add_float_row("H", "size:y", _target.size.y)

	if _target.get_script() != null:
		var exports: Array[Dictionary] = _target.get_property_list().filter(
			func(p: Dictionary) -> bool:
				return p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.usage & PROPERTY_USAGE_EDITOR
		)
		if exports.size() > 0:
			_add_section_header("EXPORTS")
			for prop: Dictionary in exports:
				_add_property_row(prop)


func _add_section_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override(&"font_color", Color(0.6, 0.5, 0.85))
	_props_container.add_child(lbl)


func _add_float_row(label: String, prop_path: String, value: float) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label
	lbl.custom_minimum_size.x = 24.0
	var spin := SpinBox.new()
	spin.value = value
	spin.step = 1.0
	spin.allow_greater = true
	spin.allow_lesser = true
	spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin.value_changed.connect(_on_float_changed.bind(prop_path))
	row.add_child(lbl)
	row.add_child(spin)
	_props_container.add_child(row)


func _add_property_row(prop: Dictionary) -> void:
	match prop.type:
		TYPE_INT, TYPE_FLOAT:
			_add_float_row(prop.name, prop.name, float(_target.get(prop.name)))
		TYPE_BOOL:
			var row := HBoxContainer.new()
			var lbl := Label.new()
			lbl.text = prop.name
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var chk := CheckBox.new()
			chk.button_pressed = bool(_target.get(prop.name))
			chk.toggled.connect(func(v: bool) -> void: _emit_change(prop.name, v))
			row.add_child(lbl)
			row.add_child(chk)
			_props_container.add_child(row)
		TYPE_STRING, TYPE_STRING_NAME:
			var row := HBoxContainer.new()
			var lbl := Label.new()
			lbl.text = prop.name
			lbl.custom_minimum_size.x = 80.0
			var field := LineEdit.new()
			field.text = str(_target.get(prop.name))
			field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			field.text_submitted.connect(func(v: String) -> void: _emit_change(prop.name, v))
			row.add_child(lbl)
			row.add_child(field)
			_props_container.add_child(row)
		_:
			pass  # skip unsupported types (Texture2D, etc.)


func _on_float_changed(value: float, prop_path: String) -> void:
	if _target == null:
		return
	if prop_path == "position:x":
		_emit_change("position", Vector2(value, _target.position.y))
	elif prop_path == "position:y":
		_emit_change("position", Vector2(_target.position.x, value))
	elif prop_path == "size:x":
		_emit_change("size", Vector2(value, _target.size.y))
	elif prop_path == "size:y":
		_emit_change("size", Vector2(_target.size.x, value))
	else:
		_emit_change(prop_path, value)


func _emit_change(property: StringName, value: Variant) -> void:
	if _target == null:
		return
	_target.set(property, value)
	property_changed.emit(_target, property, value)
