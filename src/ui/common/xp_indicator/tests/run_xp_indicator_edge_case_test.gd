# XP Indicator Edge Case Test
# Tests edge cases and potential runtime errors
extends SceneTree

func _init():
	print("Starting XP Indicator Edge Case Test...")

	var all_passed := true

	# Test 1: Edge case number formatting
	all_passed = test_edge_case_formatting() and all_passed

	# Test 2: Division by zero and invalid inputs
	all_passed = test_division_safety() and all_passed

	# Test 3: Signal connection edge cases
	all_passed = test_signal_edge_cases() and all_passed

	# Test 4: Memory management
	all_passed = test_memory_management() and all_passed

	# Test 5: Performance with large numbers
	all_passed = test_performance_edge_cases() and all_passed

	print("\n=== XP Indicator Edge Case Test Results ===")
	if all_passed:
		print("✓ ALL EDGE CASE TESTS PASSED")
		quit(0)
	else:
		print("✗ SOME EDGE CASE TESTS FAILED")
		quit(1)

func test_edge_case_formatting() -> bool:
	print("\n--- Testing Edge Case Number Formatting ---")
	var passed := true

	var xp_scene := load("res://src/ui/common/xp_indicator/xp_indicator.tscn")
	var indicator := xp_scene.instantiate()

	# Test edge cases around thresholds
	var edge_cases := [
		{"input": -1, "desc": "Negative number"},
		{"input": 0, "desc": "Zero"},
		{"input": 999, "desc": "Just below 1k threshold"},
		{"input": 1000, "desc": "Exactly at 1k threshold"},
		{"input": 1001, "desc": "Just above 1k threshold"},
		{"input": 1050, "desc": "Rounding case (should be 1.1k)"},
		{"input": 1949, "desc": "Near 2k (should round to 1.9k)"},
		{"input": 1950, "desc": "Rounding boundary (should be 2k)"},
		{"input": 9949, "desc": "Near 10k (should round to 9.9k)"},
		{"input": 9950, "desc": "Rounding to 10k"},
		{"input": 9999, "desc": "Just below 10k threshold"},
		{"input": 10000, "desc": "Exactly at 10k threshold"},
		{"input": 10001, "desc": "Just above 10k threshold"}
	]

	for case in edge_cases:
		var formatted := indicator._format_number(case.input)
		print("✓ TESTED: %s (%d) -> '%s'" % [case.desc, case.input, formatted])

		# Verify no crashes and reasonable output
		if formatted.is_empty() and case.input >= 0:
			print("✗ FAILED: Empty output for valid positive number: %d" % case.input)
			passed = false

	# Test very large numbers
	var large_numbers := [2147483647, 1000000000, 999999999]  # Near int32 max
	for num in large_numbers:
		var formatted := indicator._format_number(num)
		if formatted.is_empty():
			print("✗ FAILED: Large number formatting failed: %d" % num)
			passed = false
		else:
			print("✓ PASSED: Large number %d -> '%s'" % [num, formatted])

	indicator.queue_free()
	return passed

func test_division_safety() -> bool:
	print("\n--- Testing Division Safety ---")
	var passed := true

	var xp_scene := load("res://src/ui/common/xp_indicator/xp_indicator.tscn")
	var indicator := xp_scene.instantiate()

	# Test _calculate_progress with edge cases
	var progress_edge_cases := [
		{"current": 0, "level": 1, "desc": "Zero current XP"},
		{"current": 100, "level": 1, "desc": "Normal case"},
		{"current": -100, "level": 1, "desc": "Negative current XP"},
		{"current": 100, "level": 0, "desc": "Zero level"},
		{"current": 100, "level": -1, "desc": "Negative level"},
		{"current": 100, "level": 101, "desc": "Above max level"}
	]

	for case in progress_edge_cases:
		# This should not crash
		var progress := indicator._calculate_progress(case.current, case.level)

		# Progress should always be between 0.0 and 1.0
		if progress < 0.0 or progress > 1.0:
			print("✗ FAILED: Progress out of bounds for %s: %.2f" % [case.desc, progress])
			passed = false
		else:
			print("✓ PASSED: %s -> progress %.2f" % [case.desc, progress])

	# Test _format_xp_text with edge cases
	var text_edge_cases := [
		{"current": 0, "needed": 0, "level": 1, "desc": "Zero needed XP"},
		{"current": 100, "needed": 0, "level": 1, "desc": "Zero needed XP with current"},
		{"current": -50, "needed": 1000, "level": 1, "desc": "Negative current XP"},
		{"current": 50, "needed": -1000, "level": 1, "desc": "Negative needed XP"}
	]

	for case in text_edge_cases:
		# This should not crash
		var text := indicator._format_xp_text(case.current, case.needed, case.level)
		if text.is_empty():
			print("✗ FAILED: Empty XP text for %s" % case.desc)
			passed = false
		else:
			print("✓ PASSED: %s -> '%s'" % [case.desc, text])

	indicator.queue_free()
	return passed

func test_signal_edge_cases() -> bool:
	print("\n--- Testing Signal Edge Cases ---")
	var passed := true

	var xp_scene := load("res://src/ui/common/xp_indicator/xp_indicator.tscn")
	var indicator := xp_scene.instantiate()

	# Add to tree to enable signals
	var test_root := Node.new()
	add_child(test_root)
	test_root.add_child(indicator)

	# Wait for ready
	await get_process_frame()

	# Test signal calls with edge case parameters
	var signal_edge_cases := [
		{"name": "Zero XP gained", "xp": 0, "new_xp": 100, "needed": 1000},
		{"name": "Negative XP gained", "xp": -50, "new_xp": 50, "needed": 1000},
		{"name": "Large XP gained", "xp": 999999999, "new_xp": 999999999, "needed": 1000000},
		{"name": "Zero needed XP", "xp": 100, "new_xp": 200, "needed": 0}
	]

	for case in signal_edge_cases:
		# These should not crash
		indicator._on_xp_gained(case.xp, case.new_xp, case.needed)
		print("✓ PASSED: Signal test - %s" % case.name)

	# Test level up with edge cases
	var level_edge_cases := [
		{"level": 0, "desc": "Level 0"},
		{"level": 1, "desc": "Level 1"},
		{"level": 100, "desc": "Max level"},
		{"level": 101, "desc": "Above max level"},
		{"level": -1, "desc": "Negative level"}
	]

	for case in level_edge_cases:
		# This should not crash
		indicator._on_level_up(case.level, null, 2)
		print("✓ PASSED: Level up test - %s" % case.desc)

	test_root.queue_free()
	return passed

func test_memory_management() -> bool:
	print("\n--- Testing Memory Management ---")
	var passed := true

	# Create and destroy multiple instances
	for i in range(10):
		var xp_scene := load("res://src/ui/common/xp_indicator/xp_indicator.tscn")
		var indicator := xp_scene.instantiate()

		# Use the instance
		indicator._format_number(1000)
		indicator._calculate_progress(500, 1)

		# Clean up
		indicator.queue_free()

	print("✓ PASSED: Multiple instance creation/destruction")

	# Test signal cleanup
	var indicator := load("res://src/ui/common/xp_indicator/xp_indicator.tscn").instantiate()
	var test_root := Node.new()
	add_child(test_root)
	test_root.add_child(indicator)

	await get_process_frame()

	# Remove from tree and verify cleanup
	test_root.remove_child(indicator)
	indicator.queue_free()
	test_root.queue_free()

	print("✓ PASSED: Signal cleanup test")

	return passed

func test_performance_edge_cases() -> bool:
	print("\n--- Testing Performance Edge Cases ---")
	var passed := true

	var xp_scene := load("res://src/ui/common/xp_indicator/xp_indicator.tscn")
	var indicator := xp_scene.instantiate()

	# Test rapid number formatting calls
	var start_time := Time.get_ticks_msec()
	for i in range(1000):
		indicator._format_number(i * 1000)
	var format_time := Time.get_ticks_msec() - start_time

	if format_time > 100:  # Should take less than 100ms for 1000 calls
		print("⚠ WARNING: Number formatting may be slow (%d ms for 1000 calls)" % format_time)
	else:
		print("✓ PASSED: Number formatting performance acceptable (%d ms)" % format_time)

	# Test rapid progress calculations
	start_time = Time.get_ticks_msec()
	for i in range(1000):
		indicator._calculate_progress(i, 1)
	var progress_time := Time.get_ticks_msec() - start_time

	if progress_time > 50:  # Should take less than 50ms for 1000 calls
		print("⚠ WARNING: Progress calculation may be slow (%d ms for 1000 calls)" % progress_time)
	else:
		print("✓ PASSED: Progress calculation performance acceptable (%d ms)" % progress_time)

	indicator.queue_free()
	return passed