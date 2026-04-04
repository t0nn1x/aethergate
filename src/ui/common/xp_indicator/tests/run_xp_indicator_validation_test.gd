# XP Indicator Validation Test
# Comprehensive edge case testing for XP indicator component
extends SceneTree

const XpIndicator = preload("res://src/ui/common/xp_indicator/xp_indicator.gd")

func _init():
	print("Starting XP Indicator Validation Test...")

	var all_passed := true

	# Test 1: Number formatting edge cases
	all_passed = test_number_formatting() and all_passed

	# Test 2: Level/XP calculation edge cases
	all_passed = test_level_xp_calculations() and all_passed

	# Test 3: Signal handling edge cases
	all_passed = test_signal_handling() and all_passed

	# Test 4: Max level behavior
	all_passed = test_max_level_behavior() and all_passed

	# Test 5: Service availability edge cases
	all_passed = test_service_availability() and all_passed

	print("\n=== XP Indicator Validation Test Results ===")
	if all_passed:
		print("✓ ALL TESTS PASSED")
		quit(0)
	else:
		print("✗ SOME TESTS FAILED")
		quit(1)

func test_number_formatting() -> bool:
	print("\n--- Testing Number Formatting ---")
	var passed := true

	# Create test instance for access to _format_number
	var indicator := XpIndicator.new()

	# Test cases: [input, expected_output]
	var test_cases := [
		[0,           "0"],
		[1,           "1"],
		[999,         "999"],
		[1000,        "1k"],
		[1100,        "1.1k"],
		[2500,        "2.5k"],
		[9999,        "10k"],
		[10000,       "10k"],
		[15000,       "15k"],
		[100000,      "100k"],
		[999999,      "999k"],
		[1000000,     "1kk"],
		[1200000,     "1.2kk"],
		[9999999,     "10kk"],
		[10000000,    "10kk"],
		[500000000,   "500kk"],
		[999999999,   "999kk"],
		[1000000000,  "1kkk"],
		[1500000000,  "1.5kkk"],
	]

	for case in test_cases:
		var input: int = case[0]
		var expected: String = case[1]
		var actual: String = indicator._format_number(input)

		if actual != expected:
			print("✗ FAILED: %d -> expected '%s', got '%s'" % [input, expected, actual])
			passed = false
		else:
			print("✓ PASSED: %d -> '%s'" % [input, actual])

	indicator.queue_free()
	return passed

func test_level_xp_calculations() -> bool:
	print("\n--- Testing Level/XP Calculations ---")
	var passed := true

	var indicator := XpIndicator.new()

	# Test progress calculation edge cases
	var progress_cases := [
		[0, 1000, 1, 0.0],      # 0/1000 = 0%
		[500, 1000, 1, 0.5],    # 500/1000 = 50%
		[1000, 1000, 1, 1.0],   # 1000/1000 = 100%
		[1500, 1000, 1, 1.0],   # 1500/1000 = 150% -> clamped to 100%
		[0, 0, 1, 1.0],         # Edge case: 0 needed XP
		[100, 1, 100, 1.0]      # Max level case
	]

	for case in progress_cases:
		var current_xp: int = case[0]
		var xp_needed: int = case[1]
		var level: int = case[2]
		var expected: float = case[3]
		var actual: float = indicator._calculate_progress(current_xp, level)

		if not is_equal_approx(actual, expected):
			print("✗ FAILED progress: %d/%d at level %d -> expected %.2f, got %.2f" % [current_xp, xp_needed, level, expected, actual])
			passed = false
		else:
			print("✓ PASSED progress: %d/%d at level %d -> %.2f" % [current_xp, xp_needed, level, actual])

	indicator.queue_free()
	return passed

func test_signal_handling() -> bool:
	print("\n--- Testing Signal Handling ---")
	var passed := true

	var indicator := XpIndicator.new()
	var scene_root := Node.new()
	scene_root.add_child(indicator)

	# Test signal connection without services
	# This should not crash
	indicator._ready()

	# Test manual signal calls
	indicator._on_xp_gained(100, 600, 1000)
	indicator._on_level_up(2, null, 2)

	print("✓ PASSED: Signal handling without services doesn't crash")

	scene_root.queue_free()
	return passed

func test_max_level_behavior() -> bool:
	print("\n--- Testing Max Level Behavior ---")
	var passed := true

	var indicator := XpIndicator.new()

	# Test format text at max level
	var max_level_text := indicator._format_xp_text(0, 1000, 100)
	if max_level_text != "MAX LEVEL":
		print("✗ FAILED: Max level text expected 'MAX LEVEL', got '%s'" % max_level_text)
		passed = false
	else:
		print("✓ PASSED: Max level shows 'MAX LEVEL'")

	# Test progress at max level
	var max_level_progress := indicator._calculate_progress(0, 100)
	if not is_equal_approx(max_level_progress, 1.0):
		print("✗ FAILED: Max level progress expected 1.0, got %.2f" % max_level_progress)
		passed = false
	else:
		print("✓ PASSED: Max level progress is 1.0")

	indicator.queue_free()
	return passed

func test_service_availability() -> bool:
	print("\n--- Testing Service Availability Edge Cases ---")
	var passed := true

	var indicator := XpIndicator.new()
	var scene_root := Node.new()
	scene_root.add_child(indicator)

	# Test initialization without services
	# This should gracefully handle missing services
	indicator._initialize_from_profile()
	indicator._update_display()

	print("✓ PASSED: Handles missing services gracefully")

	# Test with labels present
	indicator._level_label = Label.new()
	indicator._progress_bar = ProgressBar.new()
	indicator._xp_label = Label.new()

	indicator.add_child(indicator._level_label)
	indicator.add_child(indicator._progress_bar)
	indicator.add_child(indicator._xp_label)

	# These should not crash
	indicator._update_level(1)
	indicator._update_progress(0, 1000)

	print("✓ PASSED: UI updates work with manual components")

	scene_root.queue_free()
	return passed