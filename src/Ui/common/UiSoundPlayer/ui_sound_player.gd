class_name UiSoundPlayer
extends Node

## Reusable UI hover/click sound wiring for any screen.
##
## Configures the MusicPlayer service with UI sound paths and volumes on _ready().
## Drop it as a child node of any screen, then call play_hover()/play_click() directly.
##
## Usage:
##   var _sfx := UiSoundPlayer.new()
##   add_child(_sfx)
##   # wire: _button_group.button_focused.connect(func(_b): _sfx.play_hover())

@export var service_path: NodePath = ^"/root/MusicPlayer"
@export_file("*.mp3", "*.wav", "*.ogg") var hover_sound_path: String = "res://src/Ui/Assets/Sounds/UI_Button_Click_2.mp3"
@export_file("*.mp3", "*.wav", "*.ogg") var click_sound_path: String = "res://src/Ui/Assets/Sounds/UI_Button_Click_8.mp3"
@export_range(-40.0, 12.0, 0.1) var hover_volume_db: float = -10.0
@export_range(-40.0, 12.0, 0.1) var click_volume_db: float = -3.0
@export var sfx_bus_name: String = "SFX"

var _service: Node


func _ready() -> void:
	_service = get_node_or_null(service_path)
	if _service == null:
		push_warning("UiSoundPlayer: MusicPlayer service not found at '%s'." % service_path)
		return
	_service.configure_ui_sounds(
		hover_sound_path, hover_volume_db,
		click_sound_path, click_volume_db,
		sfx_bus_name
	)


func play_hover() -> void:
	if _service:
		_service.play_ui_hover()


func play_click() -> void:
	if _service:
		_service.play_ui_click()
