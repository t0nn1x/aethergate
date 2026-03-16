class_name CombatVfxConfig
extends RefCounted

## Value object describing one VFX effect.
## Constructed inline at the call site — never saved to .tres.

var texture: Texture2D = null
var hframes: int = 1
var fps: float = 12.0
var impact_frame: int = 0
var scale: float = 1.0
