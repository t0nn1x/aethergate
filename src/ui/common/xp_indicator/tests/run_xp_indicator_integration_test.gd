# XP Indicator Integration Test
# Tests the XP indicator as instantiated in actual scene files
extends SceneTree

func _init():
	print("Starting XP Indicator Integration Test...")

	var all_passed := true

	# Test 1: Scene file integrity
	all_passed = test_scene_integrity() and all_passed

	# Test 2: HUD integration
	all_passed = test_hud_integration() and all_passed

	# Test 3: XP progression simulation
	all_passed = test_xp_progression_simulation() and all_passed

	# Test 4: Number formatting at scale
	all_passed = test_number_formatting_at_scale() and all_passed

	print("\n=== XP Indicator Integration Test Results ===")
	if all_passed:
		print("✓ ALL INTEGRATION TESTS PASSED")
		quit(0)
	else:
		print("✗ SOME INTEGRATION TESTS FAILED")
		quit(1)

func test_scene_integrity() -> bool:
	print("\n--- Testing Scene File Integrity ---")
	var passed := true

	# Test XP indicator scene loads correctly
	var xp_scene_path := "res://src/ui/common/xp_indicator/xp_indicator.tscn"
	var xp_scene := load(xp_scene_path)
	if xp_scene == null:
		print("✗ FAILED: Could not load XP indicator scene")
		passed = false
	else:
		print("✓ PASSED: XP indicator scene loads successfully")

		# Test instantiation
		var instance := xp_scene.instantiate()
		if instance == null:
			print("✗ FAILED: Could not instantiate XP indicator")
			passed = false
		else:
			print("✓ PASSED: XP indicator instantiates successfully")

			# Check required nodes exist
			var required_nodes := [
				"VBoxContainer/LevelLabel",
				"VBoxContainer/XpContainer/ProgressBar",
				"VBoxContainer/XpContainer/XpLabel"
			]

			for node_path in required_nodes:
				var node := instance.get_node(node_path)
				if node == null:
					print("✗ FAILED: Required node not found: %s" % node_path)
					passed = false
				else:
					print("✓ PASSED: Required node found: %s" % node_path)

			instance.queue_free()

	# Test desktop HUD scene loads correctly
	var desktop_hud_path := "res://src/ui/desktop/hud/system_hud/system_hud.tscn"
	var desktop_scene := load(desktop_hud_path)
	if desktop_scene == null:
		print("✗ FAILED: Could not load desktop HUD scene")
		passed = false
	else:
		print("✓ PASSED: Desktop HUD scene loads successfully")

	# Test mobile HUD scene loads correctly
	var mobile_hud_path := "res://src/ui/mobile/hud/system_hud/system_hud_mobile.tscn"
	var mobile_scene := load(mobile_hud_path)
	if mobile_scene == null:
		print("✗ FAILED: Could not load mobile HUD scene")
		passed = false
	else:
		print("✓ PASSED: Mobile HUD scene loads successfully")

	return passed

func test_hud_integration() -> bool:
	print("\n--- Testing HUD Integration ---")
	var passed := true

	# Test desktop HUD integration
	var desktop_hud_scene := load("res://src/ui/desktop/hud/system_hud/system_hud.tscn")
	if desktop_hud_scene != null:
		var desktop_instance := desktop_hud_scene.instantiate()
		var xp_indicator := desktop_instance.get_node("Root/SafeAreaMargin/BottomAlign/XpIndicator")

		if xp_indicator == null:
			print("✗ FAILED: XP indicator not found in desktop HUD")
			passed = false
		else:
			print("✓ PASSED: XP indicator found in desktop HUD")

			# Check positioning
			var slot_row := desktop_instance.get_node("Root/SafeAreaMargin/BottomAlign/SlotRow")
			if slot_row != null:
				var xp_index := xp_indicator.get_index()
				var slot_index := slot_row.get_index()
				if xp_index < slot_index:
					print("✓ PASSED: XP indicator positioned above slot row in desktop")
				else:
					print("✗ FAILED: XP indicator not positioned above slot row in desktop")
					passed = false

		desktop_instance.queue_free()

	# Test mobile HUD integration
	var mobile_hud_scene := load("res://src/ui/mobile/hud/system_hud/system_hud_mobile.tscn")
	if mobile_hud_scene != null:
		var mobile_instance := mobile_hud_scene.instantiate()
		var xp_indicator := mobile_instance.get_node("Root/SafeAreaMargin/BottomAlign/XpIndicator")

		if xp_indicator == null:
			print("✗ FAILED: XP indicator not found in mobile HUD")
			passed = false
		else:
			print("✓ PASSED: XP indicator found in mobile HUD")

			# Check positioning
			var slot_row := mobile_instance.get_node("Root/SafeAreaMargin/BottomAlign/SlotRow")
			if slot_row != null:
				var xp_index := xp_indicator.get_index()
				var slot_index := slot_row.get_index()
				if xp_index < slot_index:
					print("✓ PASSED: XP indicator positioned above slot row in mobile")
				else:
					print("✗ FAILED: XP indicator not positioned above slot row in mobile")
					passed = false

		mobile_instance.queue_free()

	return passed

func test_xp_progression_simulation() -> bool:
	print("\n--- Testing XP Progression Simulation ---")
	var passed := true

	var xp_scene := load("res://src/ui/common/xp_indicator/xp_indicator.tscn")
	var indicator := xp_scene.instantiate()

	# Add to scene tree for proper initialization
	var test_root := Node.new()
	add_child(test_root)
	test_root.add_child(indicator)

	# Wait one frame for _ready to complete
	await get_process_frame()

	# Simulate various XP scenarios
	var test_scenarios := [
		{"name": "Small XP gain", "xp": 50, "new_xp": 550, "needed": 1000},
		{"name": "Level up boundary", "xp": 1000, "new_xp": 0, "needed": 970},
		{"name": "Large XP gain", "xp": 5000, "new_xp": 2000, "needed": 2500},
		{"name": "Zero XP gain", "xp": 0, "new_xp": 550, "needed": 1000}
	]

	for scenario in test_scenarios:
		indicator._on_xp_gained(scenario.xp, scenario.new_xp, scenario.needed)
		print("✓ PASSED: %s simulation completed" % scenario.name)

	# Simulate level ups
	for level in [2, 10, 50, 99, 100]:
		indicator._on_level_up(level, null, 2)
		print("✓ PASSED: Level %d simulation completed" % level)

	test_root.queue_free()
	return passed

func test_number_formatting_at_scale() -> bool:
	print("\n--- Testing Number Formatting at Scale ---")
	var passed := true

	var xp_scene := load("res://src/ui/common/xp_indicator/xp_indicator.tscn")
	var indicator := xp_scene.instantiate()

	# Test extreme values
	var extreme_cases := [
		999999,     # Near 1M
		1000000,    # 1M
		10000000,   # 10M
		100000000   # 100M
	]

	for value in extreme_cases:
		var formatted := indicator._format_number(value)
		if formatted.is_empty():
			print("✗ FAILED: Empty result for %d" % value)
			passed = false
		else:
			print("✓ PASSED: %d -> '%s'" % [value, formatted])

	# Test boundary conditions around thresholds
	var boundary_cases := [
		998, 999, 1000, 1001, 1002,
		9998, 9999, 10000, 10001, 10002
	]

	for value in boundary_cases:
		var formatted := indicator._format_number(value)
		if formatted.is_empty():
			print("✗ FAILED: Empty result for boundary case %d" % value)
			passed = false
		else:
			print("✓ PASSED: Boundary %d -> '%s'" % [value, formatted])

	indicator.queue_free()
	return passed