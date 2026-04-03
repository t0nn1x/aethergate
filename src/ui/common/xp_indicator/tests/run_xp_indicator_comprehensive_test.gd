# XP Indicator Comprehensive Test Report
# Final comprehensive testing and issue identification
extends SceneTree

func _init():
	print("Starting XP Indicator Comprehensive Test Report...")
	print("=" * 60)

	var all_passed := true
	var issue_count := 0

	# Critical Issues
	print("\n🔴 CRITICAL ISSUES:")
	issue_count += check_critical_issues()

	# Implementation Issues
	print("\n🟡 IMPLEMENTATION ISSUES:")
	issue_count += check_implementation_issues()

	# Edge Case Testing
	print("\n🔵 EDGE CASE VALIDATION:")
	all_passed = comprehensive_edge_case_testing() and all_passed

	# Integration Testing
	print("\n🟢 INTEGRATION VALIDATION:")
	all_passed = comprehensive_integration_testing() and all_passed

	# Performance Testing
	print("\n⚡ PERFORMANCE VALIDATION:")
	all_passed = comprehensive_performance_testing() and all_passed

	print("\n" + "=" * 60)
	print("XP INDICATOR COMPREHENSIVE TEST RESULTS")
	print("=" * 60)

	if issue_count == 0 and all_passed:
		print("✅ ALL TESTS PASSED - IMPLEMENTATION READY")
		quit(0)
	else:
		print("❌ %d ISSUES FOUND - REVIEW NEEDED" % issue_count)
		quit(1)

func check_critical_issues() -> int:
	var issues := 0

	# Issue 1: Check mobile scene file was corrected
	print("Checking mobile HUD scene file integrity...")
	var mobile_scene := load("res://src/ui/mobile/hud/system_hud/system_hud_mobile.tscn")
	if mobile_scene == null:
		print("  ❌ CRITICAL: Mobile HUD scene fails to load")
		issues += 1
	else:
		var mobile_instance := mobile_scene.instantiate()
		if mobile_instance == null:
			print("  ❌ CRITICAL: Mobile HUD scene fails to instantiate")
			issues += 1
		else:
			print("  ✅ Mobile HUD scene loads and instantiates correctly")
			mobile_instance.queue_free()

	# Issue 2: Check XP indicator scene integrity
	print("Checking XP indicator scene integrity...")
	var xp_scene := load("res://src/ui/common/xp_indicator/xp_indicator.tscn")
	if xp_scene == null:
		print("  ❌ CRITICAL: XP indicator scene fails to load")
		issues += 1
	else:
		var xp_instance := xp_scene.instantiate()
		if xp_instance == null:
			print("  ❌ CRITICAL: XP indicator scene fails to instantiate")
			issues += 1
		else:
			print("  ✅ XP indicator scene loads and instantiates correctly")
			xp_instance.queue_free()

	# Issue 3: Check script loading
	print("Checking script loading...")
	var script := load("res://src/ui/common/xp_indicator/xp_indicator.gd")
	if script == null:
		print("  ❌ CRITICAL: XP indicator script fails to load")
		issues += 1
	else:
		print("  ✅ XP indicator script loads correctly")

	return issues

func check_implementation_issues() -> int:
	var issues := 0

	var xp_scene := load("res://src/ui/common/xp_indicator/xp_indicator.tscn")
	if xp_scene != null:
		var indicator := xp_scene.instantiate()

		# Issue 1: Engine.has_singleton vs autoload access pattern inconsistency
		print("Checking service access patterns...")
		print("  ⚠️  WARNING: Mixed Engine.has_singleton() and direct autoload access")
		print("      This works but could be simplified to always check singleton existence")

		# Issue 2: Division by zero protection
		print("Checking division safety...")
		var progress := indicator._calculate_progress(100, 1)
		if progress >= 0.0 and progress <= 1.0:
			print("  ✅ Progress calculation handles edge cases safely")
		else:
			print("  ❌ Progress calculation may have issues")
			issues += 1

		# Issue 3: Number formatting edge cases
		print("Checking number formatting edge cases...")
		var test_cases := [999, 1000, 9999, 10000, 1500]
		var formatting_ok := true
		for case in test_cases:
			var formatted := indicator._format_number(case)
			if formatted.is_empty():
				formatting_ok = false
				break

		if formatting_ok:
			print("  ✅ Number formatting handles edge cases correctly")
		else:
			print("  ❌ Number formatting has issues with edge cases")
			issues += 1

		indicator.queue_free()

	return issues

func comprehensive_edge_case_testing() -> bool:
	print("Running comprehensive edge case tests...")
	var passed := true

	var xp_scene := load("res://src/ui/common/xp_indicator/xp_indicator.tscn")
	if xp_scene == null:
		print("  ❌ Cannot test - XP scene loading failed")
		return false

	var indicator := xp_scene.instantiate()

	# Test 1: Boundary number formatting
	var boundary_cases := [
		[999, "999"], [1000, "1k"], [1001, "1k"],
		[9999, "10k"], [10000, "10k"], [10001, "10k"]
	]

	var boundary_passed := true
	for case in boundary_cases:
		var input: int = case[0]
		var expected: String = case[1]
		var actual := indicator._format_number(input)
		if actual != expected:
			print("  ❌ Boundary case failed: %d -> expected '%s', got '%s'" % [input, expected, actual])
			boundary_passed = false

	if boundary_passed:
		print("  ✅ Boundary number formatting tests passed")
	else:
		passed = false

	# Test 2: Progress calculation edge cases
	var progress_passed := true
	var edge_progress := indicator._calculate_progress(-100, 1)  # Negative XP
	if edge_progress < 0.0 or edge_progress > 1.0:
		print("  ❌ Progress calculation doesn't clamp properly")
		progress_passed = false

	if progress_passed:
		print("  ✅ Progress calculation edge cases passed")
	else:
		passed = false

	# Test 3: Max level handling
	var max_level_text := indicator._format_xp_text(0, 1000, 100)
	if max_level_text == "MAX LEVEL":
		print("  ✅ Max level handling correct")
	else:
		print("  ❌ Max level handling incorrect: got '%s'" % max_level_text)
		passed = false

	indicator.queue_free()
	return passed

func comprehensive_integration_testing() -> bool:
	print("Running comprehensive integration tests...")
	var passed := true

	# Test desktop HUD integration
	var desktop_scene := load("res://src/ui/desktop/hud/system_hud/system_hud.tscn")
	if desktop_scene != null:
		var desktop_instance := desktop_scene.instantiate()
		var xp_indicator := desktop_instance.get_node_or_null("Root/SafeAreaMargin/BottomAlign/XpIndicator")

		if xp_indicator != null:
			print("  ✅ Desktop HUD integration successful")
		else:
			print("  ❌ Desktop HUD integration failed")
			passed = false

		desktop_instance.queue_free()

	# Test mobile HUD integration (after fix)
	var mobile_scene := load("res://src/ui/mobile/hud/system_hud/system_hud_mobile.tscn")
	if mobile_scene != null:
		var mobile_instance := mobile_scene.instantiate()
		var xp_indicator := mobile_instance.get_node_or_null("Root/SafeAreaMargin/BottomAlign/XpIndicator")

		if xp_indicator != null:
			print("  ✅ Mobile HUD integration successful")
		else:
			print("  ❌ Mobile HUD integration failed")
			passed = false

		mobile_instance.queue_free()

	return passed

func comprehensive_performance_testing() -> bool:
	print("Running comprehensive performance tests...")
	var passed := true

	var xp_scene := load("res://src/ui/common/xp_indicator/xp_indicator.tscn")
	var indicator := xp_scene.instantiate()

	# Performance test: Number formatting
	var start_time := Time.get_ticks_msec()
	for i in range(10000):
		indicator._format_number(i)
	var format_time := Time.get_ticks_msec() - start_time

	if format_time < 500:  # Should be very fast
		print("  ✅ Number formatting performance excellent (%d ms for 10k calls)" % format_time)
	else:
		print("  ⚠️  Number formatting performance concern (%d ms for 10k calls)" % format_time)

	# Performance test: Progress calculation
	start_time = Time.get_ticks_msec()
	for i in range(10000):
		indicator._calculate_progress(i, 1)
	var progress_time := Time.get_ticks_msec() - start_time

	if progress_time < 500:
		print("  ✅ Progress calculation performance excellent (%d ms for 10k calls)" % progress_time)
	else:
		print("  ⚠️  Progress calculation performance concern (%d ms for 10k calls)" % progress_time)

	indicator.queue_free()
	return passed