# XP Indicator Scene Validation Test
# Validates scene file integrity and common issues
extends SceneTree

func _init():
	print("Starting XP Indicator Scene Validation Test...")

	var all_passed := true

	# Test 1: Scene file syntax validation
	all_passed = test_scene_syntax() and all_passed

	# Test 2: Node hierarchy validation
	all_passed = test_node_hierarchy() and all_passed

	# Test 3: Resource reference validation
	all_passed = test_resource_references() and all_passed

	print("\n=== XP Indicator Scene Validation Results ===")
	if all_passed:
		print("✓ ALL SCENE VALIDATION TESTS PASSED")
		quit(0)
	else:
		print("✗ SOME SCENE VALIDATION TESTS FAILED")
		quit(1)

func test_scene_syntax() -> bool:
	print("\n--- Testing Scene File Syntax ---")
	var passed := true

	var scene_files := [
		"res://src/ui/common/xp_indicator/xp_indicator.tscn",
		"res://src/ui/desktop/hud/system_hud/system_hud.tscn",
		"res://src/ui/mobile/hud/system_hud/system_hud_mobile.tscn"
	]

	for scene_path in scene_files:
		print("Testing: %s" % scene_path)

		# Try to load the scene
		var scene := load(scene_path)
		if scene == null:
			print("✗ FAILED: Could not load scene: %s" % scene_path)
			passed = false
			continue

		# Try to instantiate
		var instance := scene.instantiate()
		if instance == null:
			print("✗ FAILED: Could not instantiate scene: %s" % scene_path)
			passed = false
			continue

		print("✓ PASSED: Scene loads and instantiates: %s" % scene_path)
		instance.queue_free()

	return passed

func test_node_hierarchy() -> bool:
	print("\n--- Testing Node Hierarchy ---")
	var passed := true

	# Test XP indicator internal structure
	var xp_scene := load("res://src/ui/common/xp_indicator/xp_indicator.tscn")
	if xp_scene != null:
		var xp_instance := xp_scene.instantiate()

		# Check required internal nodes
		var required_paths := [
			"HBoxContainer",
			"HBoxContainer/LevelLabel",
			"HBoxContainer/Bar",
			"HBoxContainer/XpLabel"
		]

		for path in required_paths:
			var node := xp_instance.get_node_or_null(path)
			if node == null:
				print("✗ FAILED: Missing required node in XP indicator: %s" % path)
				passed = false
			else:
				print("✓ PASSED: Found required node: %s" % path)

		# Check node types
		var level_label := xp_instance.get_node_or_null("HBoxContainer/LevelLabel")
		if level_label != null and not level_label is Label:
			print("✗ FAILED: LevelLabel is not a Label node")
			passed = false

		var progress_bar := xp_instance.get_node_or_null("HBoxContainer/Bar")
		if progress_bar != null and not progress_bar is ProgressBar:
			print("✗ FAILED: Bar is not a ProgressBar node")
			passed = false

		var xp_label := xp_instance.get_node_or_null("HBoxContainer/XpLabel")
		if xp_label != null and not xp_label is Label:
			print("✗ FAILED: XpLabel is not a Label node")
			passed = false

		xp_instance.queue_free()

	# Test HUD integration
	var hud_scenes := [
		"res://src/ui/desktop/hud/system_hud/system_hud.tscn",
		"res://src/ui/mobile/hud/system_hud/system_hud_mobile.tscn"
	]

	for hud_path in hud_scenes:
		var hud_scene := load(hud_path)
		if hud_scene != null:
			var hud_instance := hud_scene.instantiate()
			var xp_indicator := hud_instance.get_node_or_null("Root/SafeAreaMargin/BottomAlign/XpIndicator")

			if xp_indicator == null:
				print("✗ FAILED: XP indicator not found in HUD: %s" % hud_path)
				passed = false
			else:
				print("✓ PASSED: XP indicator found in HUD: %s" % hud_path)

				# Check if it's positioned correctly relative to slot row
				var slot_row := hud_instance.get_node_or_null("Root/SafeAreaMargin/BottomAlign/SlotRow")
				if slot_row != null:
					if xp_indicator.get_index() < slot_row.get_index():
						print("✓ PASSED: XP indicator positioned above slot row")
					else:
						print("✗ FAILED: XP indicator not positioned above slot row")
						passed = false

			hud_instance.queue_free()

	return passed

func test_resource_references() -> bool:
	print("\n--- Testing Resource References ---")
	var passed := true

	# Check if XP indicator script exists and loads
	var script_path := "res://src/ui/common/xp_indicator/xp_indicator.gd"
	var script := load(script_path)
	if script == null:
		print("✗ FAILED: XP indicator script not found: %s" % script_path)
		passed = false
	else:
		print("✓ PASSED: XP indicator script loads successfully")

	# Check if referenced packed scene exists and has correct UID
	var xp_scene := load("res://src/ui/common/xp_indicator/xp_indicator.tscn")
	if xp_scene != null:
		print("✓ PASSED: XP indicator scene resource loads successfully")

		# Test that the scene has the expected components
		var instance := xp_scene.instantiate()
		if instance.has_method("_format_number"):
			print("✓ PASSED: XP indicator has required methods")
		else:
			print("✗ FAILED: XP indicator missing required methods")
			passed = false
		instance.queue_free()
	else:
		print("✗ FAILED: XP indicator scene not found")
		passed = false

	return passed