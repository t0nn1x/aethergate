# Combat System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver a working 1v1 turn-based combat loop — tap creature → preview card → full-screen combat → simultaneous round resolution → return to overworld.

**Architecture:** Self-contained bounded context under `src/Entities/Systems/Combat/` for logic and `src/World/Combat/` for the scene entry point. A stateless `CombatRoundResolver` takes two actions and returns a pure `CombatRoundResult` resource — no side effects. `CombatFlowController` owns the round loop and timer. All combat events route through a new `CombatEvents` autoload.

**Tech Stack:** Godot 4.6, GDScript, existing event singleton pattern, existing `AdaptiveOverlayPanel` base, existing `GameManager` COMBAT state.

**Design doc:** `doc/plans/2026-03-09-combat-system-design.md`

---

## What already exists (do NOT recreate)

- `GameManager.GameState.COMBAT` — state and transitions already registered
- `CreatureEvents.creature_fight_requested` — signal already declared and emitted by `OverworldCreatureSelectionController._on_creature_action_hud_fight_pressed`
- `CreatureData` — has `max_health`, `damage`, `armor`, `experience_reward` already
- `src/Entities/Skills/Combat/Fireball/`, `Slash/`, `Heal/` — folders scaffolded, need data resources
- `src/Entities/Systems/Equipment/` — scaffolded, implement here in Task 9
- `src/Ui/Common/AdaptiveOverlayPanel` — base class for all overlay panels

## Testing pattern

Tests are headless GDScript files that extend `SceneTree`. Run with:
```bash
godot4 --headless --path . --script res://src/Entities/Systems/Combat/Tests/run_combat_tests.gd
```
Exit code 0 = all pass, 1 = any failure. Print `[PASS]` / `[FAIL]` per assertion.

---

## Phase 1 — Core Data Resources

### Task 1: CombatStats resource

**Files:**
- Create: `src/Entities/Systems/Combat/Data/combat_stats.gd`

**Step 1: Write the file**

```gdscript
class_name CombatStats
extends Resource

@export var max_hp: int = 100
@export var max_energy: int = 100
@export var attack: float = 10.0
@export var defense: float = 5.0

func duplicate_stats() -> CombatStats:
	var copy := CombatStats.new()
	copy.max_hp = max_hp
	copy.max_energy = max_energy
	copy.attack = attack
	copy.defense = defense
	return copy
```

**Step 2: Verify** — open Godot editor, confirm no parse errors in output panel.

**Step 3: Commit**
```bash
git add src/Entities/Systems/Combat/Data/combat_stats.gd
git commit -m "feat(combat): add CombatStats resource"
```

---

### Task 2: SkillData resource

**Files:**
- Create: `src/Entities/Skills/Combat/skill_data.gd`

**Step 1: Write the file**

```gdscript
class_name SkillData
extends Resource

enum Element { NONE, FIRE, WATER, EARTH, ARCANE }
enum SkillType { ATTACK, DEFEND, HEAL, BUFF, DEBUFF }

@export var skill_id: StringName = &""
@export var display_name: String = "Skill"
@export var energy_cost: int = 10
@export var base_power: float = 15.0
@export var element: Element = Element.NONE
@export var skill_type: SkillType = SkillType.ATTACK
## Icon shown on the skill bar button.
@export var icon: Texture2D
## Mastery variants unlocked at tiers 3, 6, 10. Leave empty for base version only.
@export var mastery_variants: Array[Resource] = []
```

**Step 2: Verify** — no parse errors.

**Step 3: Commit**
```bash
git add src/Entities/Skills/Combat/skill_data.gd
git commit -m "feat(combat): add SkillData resource"
```

---

### Task 3: CombatAction and CombatantSnapshot resources

**Files:**
- Create: `src/Entities/Systems/Combat/Data/combat_action.gd`
- Create: `src/Entities/Systems/Combat/Data/combatant_snapshot.gd`

**Step 1: Write CombatAction**

```gdscript
class_name CombatAction
extends Resource

## Identifies which combatant took this action.
var actor_id: StringName = &""
## The skill chosen. Null means auto-attack (base attack, no energy cost).
var skill_used: SkillData = null


static func make(actor: StringName, skill: SkillData = null) -> CombatAction:
	var action := CombatAction.new()
	action.actor_id = actor
	action.skill_used = skill
	return action
```

**Step 2: Write CombatantSnapshot**

```gdscript
class_name CombatantSnapshot
extends Resource

## Immutable snapshot of a combatant taken at combat start.
## Live HP/energy are tracked in CombatContext, not here.

var combatant_id: StringName = &""
var display_name: String = ""
var portrait: Texture2D = null
var level: int = 1
var base_stats: CombatStats = null
## Resolved skill loadout: base skills + gear-granted skills.
var skill_loadout: Array[SkillData] = []


static func from_creature(creature_data: CreatureData) -> CombatantSnapshot:
	var snap := CombatantSnapshot.new()
	snap.combatant_id = StringName(creature_data.get_effective_creature_id())
	snap.display_name = creature_data.display_name
	snap.level = 1

	var stats := CombatStats.new()
	stats.max_hp = int(creature_data.max_health)
	stats.attack = creature_data.damage
	stats.defense = creature_data.armor
	snap.base_stats = stats

	if creature_data.has_method("get_skill_loadout"):
		snap.skill_loadout = creature_data.call("get_skill_loadout") as Array[SkillData]

	return snap
```

**Step 3: Commit**
```bash
git add src/Entities/Systems/Combat/Data/combat_action.gd \
        src/Entities/Systems/Combat/Data/combatant_snapshot.gd
git commit -m "feat(combat): add CombatAction and CombatantSnapshot resources"
```

---

### Task 4: CombatRoundResult resource

**Files:**
- Create: `src/Entities/Systems/Combat/Data/combat_round_result.gd`

**Step 1: Write the file**

```gdscript
class_name CombatRoundResult
extends Resource

var round_number: int = 0
var player_action: CombatAction = null
var enemy_action: CombatAction = null
## Negative = damage taken, positive = healing received.
var hp_delta_player: int = 0
var hp_delta_enemy: int = 0
## True when either combatant reached 0 HP this round.
var combat_ended: bool = false
## StringName of the winner's combatant_id. Empty if combat continues.
var winner_id: StringName = &""
```

**Step 2: Commit**
```bash
git add src/Entities/Systems/Combat/Data/combat_round_result.gd
git commit -m "feat(combat): add CombatRoundResult resource"
```

---

## Phase 2 — CombatEvents Autoload

### Task 5: CombatEvents singleton

**Files:**
- Create: `src/Core/Events/combat_events.gd`
- Modify: `project.godot` — add autoload entry

**Step 1: Write combat_events.gd**

```gdscript
extends Node

## Combat bounded-context events.

## Emitted when a combat round resolves. UI and progression systems listen here.
signal round_resolved(result: CombatRoundResult)

## Emitted when the combat is fully over (win, loss, or flee).
signal combat_ended(result: CombatRoundResult)

## Emitted when the player confirms they want to fight from the preview panel.
signal combat_confirmed(player_snapshot: CombatantSnapshot, enemy_snapshot: CombatantSnapshot)
```

**Step 2: Register in project.godot**

Open `project.godot` and add under `[autoload]`:
```ini
CombatEvents="*res://src/Core/Events/combat_events.gd"
```
Add it after `CreatureEvents` to keep the load order consistent with the other event singletons.

**Step 3: Verify** — run the game (F5), confirm no autoload errors in the Output panel.

**Step 4: Commit**
```bash
git add src/Core/Events/combat_events.gd project.godot
git commit -m "feat(combat): add CombatEvents autoload"
```

---

## Phase 3 — CombatRoundResolver (pure, testable)

### Task 6: Write the resolver

**Files:**
- Create: `src/Entities/Systems/Combat/combat_round_resolver.gd`

**Step 1: Write the resolver**

```gdscript
class_name CombatRoundResolver
extends Node

## Pure, stateless round resolver.
## Takes two actions + live HP values → returns CombatRoundResult.
## Has no side effects. All state lives in CombatContext, not here.

## Element damage multipliers. Extend as elements are added.
const ELEMENT_MULTIPLIERS: Dictionary = {
	# [attacker_element][defender_element] = multiplier
}

## Minimum damage dealt before defense, so combat never stalls.
const MIN_DAMAGE: int = 1


func resolve(
	round_number: int,
	player_action: CombatAction,
	enemy_action: CombatAction,
	player_snapshot: CombatantSnapshot,
	enemy_snapshot: CombatantSnapshot,
	player_current_hp: int,
	enemy_current_hp: int
) -> CombatRoundResult:
	var result := CombatRoundResult.new()
	result.round_number = round_number
	result.player_action = player_action
	result.enemy_action = enemy_action

	result.hp_delta_enemy = -_calculate_damage(player_action, player_snapshot, enemy_snapshot)
	result.hp_delta_player = -_calculate_damage(enemy_action, enemy_snapshot, player_snapshot)

	# Apply defend skill: halve incoming damage when skill_type is DEFEND.
	if _is_defend(player_action):
		result.hp_delta_player = result.hp_delta_player / 2
	if _is_defend(enemy_action):
		result.hp_delta_enemy = result.hp_delta_enemy / 2

	# Apply healing: HEAL skill_type adds HP instead of dealing damage.
	if _is_heal(player_action):
		result.hp_delta_player = _calculate_heal(player_action, player_snapshot)
	if _is_heal(enemy_action):
		result.hp_delta_enemy = _calculate_heal(enemy_action, enemy_snapshot)

	var new_player_hp: int = clampi(player_current_hp + result.hp_delta_player, 0, player_snapshot.base_stats.max_hp)
	var new_enemy_hp: int = clampi(enemy_current_hp + result.hp_delta_enemy, 0, enemy_snapshot.base_stats.max_hp)

	if new_enemy_hp <= 0 or new_player_hp <= 0:
		result.combat_ended = true
		if new_enemy_hp <= 0 and new_player_hp > 0:
			result.winner_id = player_snapshot.combatant_id
		elif new_player_hp <= 0 and new_enemy_hp > 0:
			result.winner_id = enemy_snapshot.combatant_id
		# Simultaneous kill → no winner (draw).

	return result


func _calculate_damage(
	action: CombatAction,
	attacker: CombatantSnapshot,
	defender: CombatantSnapshot
) -> int:
	if _is_heal(action) or _is_defend(action):
		return 0

	var power: float = attacker.base_stats.attack
	if action.skill_used:
		power += action.skill_used.base_power

	var damage: float = maxf(power - defender.base_stats.defense, float(MIN_DAMAGE))
	return int(damage)


func _calculate_heal(action: CombatAction, caster: CombatantSnapshot) -> int:
	if action.skill_used == null:
		return 0
	return int(action.skill_used.base_power + caster.base_stats.attack * 0.5)


func _is_defend(action: CombatAction) -> bool:
	return action.skill_used != null and action.skill_used.skill_type == SkillData.SkillType.DEFEND


func _is_heal(action: CombatAction) -> bool:
	return action.skill_used != null and action.skill_used.skill_type == SkillData.SkillType.HEAL
```

**Step 2: Commit**
```bash
git add src/Entities/Systems/Combat/combat_round_resolver.gd
git commit -m "feat(combat): add CombatRoundResolver"
```

---

### Task 7: Write headless resolver tests

**Files:**
- Create: `src/Entities/Systems/Combat/Tests/combat_resolver_test.gd`
- Create: `src/Entities/Systems/Combat/Tests/run_combat_tests.gd`

**Step 1: Write the test helper**

```gdscript
# combat_resolver_test.gd
## Headless unit tests for CombatRoundResolver.

const CombatRoundResolverScript = preload(
	"res://src/Entities/Systems/Combat/combat_round_resolver.gd"
)

var _pass_count: int = 0
var _fail_count: int = 0


func run() -> bool:
	test_basic_attack_deals_damage()
	test_defend_halves_incoming_damage()
	test_combat_ends_when_hp_reaches_zero()
	test_simultaneous_kill_has_no_winner()
	print("[CombatResolverTest] %d passed, %d failed." % [_pass_count, _fail_count])
	return _fail_count == 0


func test_basic_attack_deals_damage() -> void:
	var resolver = CombatRoundResolverScript.new()

	var p_snap := _make_snapshot(&"player", 100, 10.0, 0.0)
	var e_snap := _make_snapshot(&"enemy", 100, 10.0, 0.0)
	var p_action := CombatAction.make(&"player", null)
	var e_action := CombatAction.make(&"enemy", null)

	var result: CombatRoundResult = resolver.resolve(1, p_action, e_action, p_snap, e_snap, 100, 100)

	_assert(result.hp_delta_enemy < 0, "player attack should deal damage to enemy")
	_assert(result.hp_delta_player < 0, "enemy attack should deal damage to player")
	_assert(not result.combat_ended, "combat should not end at full HP")


func test_defend_halves_incoming_damage() -> void:
	var resolver = CombatRoundResolverScript.new()

	var p_snap := _make_snapshot(&"player", 100, 10.0, 0.0)
	var e_snap := _make_snapshot(&"enemy", 100, 10.0, 0.0)

	var defend_skill := SkillData.new()
	defend_skill.skill_type = SkillData.SkillType.DEFEND
	defend_skill.base_power = 0.0
	defend_skill.energy_cost = 5

	var p_action_defend := CombatAction.make(&"player", defend_skill)
	var e_action := CombatAction.make(&"enemy", null)

	var result: CombatRoundResult = resolver.resolve(1, p_action_defend, e_action, p_snap, e_snap, 100, 100)

	# With defend, player should take half the normal damage.
	var p_action_plain := CombatAction.make(&"player", null)
	var result_plain: CombatRoundResult = resolver.resolve(1, p_action_plain, e_action, p_snap, e_snap, 100, 100)

	_assert(
		result.hp_delta_player > result_plain.hp_delta_player,
		"defending player should take less damage (delta closer to 0)"
	)


func test_combat_ends_when_hp_reaches_zero() -> void:
	var resolver = CombatRoundResolverScript.new()

	# Give enemy 1 HP and player massive attack so enemy dies.
	var p_snap := _make_snapshot(&"player", 100, 999.0, 0.0)
	var e_snap := _make_snapshot(&"enemy", 1, 5.0, 0.0)
	var p_action := CombatAction.make(&"player", null)
	var e_action := CombatAction.make(&"enemy", null)

	var result: CombatRoundResult = resolver.resolve(1, p_action, e_action, p_snap, e_snap, 100, 1)

	_assert(result.combat_ended, "combat should end when enemy HP reaches 0")
	_assert(result.winner_id == &"player", "player should be the winner")


func test_simultaneous_kill_has_no_winner() -> void:
	var resolver = CombatRoundResolverScript.new()

	var p_snap := _make_snapshot(&"player", 1, 999.0, 0.0)
	var e_snap := _make_snapshot(&"enemy", 1, 999.0, 0.0)
	var p_action := CombatAction.make(&"player", null)
	var e_action := CombatAction.make(&"enemy", null)

	var result: CombatRoundResult = resolver.resolve(1, p_action, e_action, p_snap, e_snap, 1, 1)

	_assert(result.combat_ended, "combat should end on simultaneous kill")
	_assert(result.winner_id == &"", "simultaneous kill should have no winner")


func _make_snapshot(id: StringName, hp: int, attack: float, defense: float) -> CombatantSnapshot:
	var stats := CombatStats.new()
	stats.max_hp = hp
	stats.attack = attack
	stats.defense = defense
	var snap := CombatantSnapshot.new()
	snap.combatant_id = id
	snap.base_stats = stats
	return snap


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
		_pass_count += 1
	else:
		push_error("[FAIL] %s" % message)
		_fail_count += 1
```

**Step 2: Write the headless runner**

```gdscript
# run_combat_tests.gd
extends SceneTree

## Headless runner for combat system tests.
## Usage:
##   godot4 --headless --path . --script res://src/Entities/Systems/Combat/Tests/run_combat_tests.gd

const TEST_SCRIPT = preload(
	"res://src/Entities/Systems/Combat/Tests/combat_resolver_test.gd"
)


func _initialize() -> void:
	var test = TEST_SCRIPT.new()
	var passed: bool = test.run()
	quit(0 if passed else 1)
```

**Step 3: Run tests**
```bash
godot4 --headless --path . --script res://src/Entities/Systems/Combat/Tests/run_combat_tests.gd
```
Expected: all `[PASS]`, exit code 0.

**Step 4: Commit**
```bash
git add src/Entities/Systems/Combat/Tests/
git commit -m "test(combat): add headless resolver tests"
```

---

## Phase 4 — CombatContext and CombatFlowController

### Task 8: CombatContext (live state)

**Files:**
- Create: `src/Entities/Systems/Combat/combat_context.gd`

**Step 1: Write the file**

```gdscript
class_name CombatContext
extends Resource

## Mutable live state for an ongoing combat session.
## CombatantSnapshots are immutable; only HP/energy/round change here.

var player_snapshot: CombatantSnapshot = null
var enemy_snapshot: CombatantSnapshot = null

var player_current_hp: int = 0
var player_current_energy: int = 0
var enemy_current_hp: int = 0
var enemy_current_energy: int = 0
var current_round: int = 0


static func from_snapshots(
	player: CombatantSnapshot,
	enemy: CombatantSnapshot
) -> CombatContext:
	var ctx := CombatContext.new()
	ctx.player_snapshot = player
	ctx.enemy_snapshot = enemy
	ctx.player_current_hp = player.base_stats.max_hp
	ctx.player_current_energy = player.base_stats.max_energy
	ctx.enemy_current_hp = enemy.base_stats.max_hp
	ctx.enemy_current_energy = enemy.base_stats.max_energy
	ctx.current_round = 0
	return ctx


func apply_result(result: CombatRoundResult) -> void:
	player_current_hp = clampi(
		player_current_hp + result.hp_delta_player, 0, player_snapshot.base_stats.max_hp
	)
	enemy_current_hp = clampi(
		enemy_current_hp + result.hp_delta_enemy, 0, enemy_snapshot.base_stats.max_hp
	)
	## Deduct energy for skills used (skip for null / auto-attack).
	if result.player_action and result.player_action.skill_used:
		player_current_energy = maxi(
			player_current_energy - result.player_action.skill_used.energy_cost, 0
		)
	if result.enemy_action and result.enemy_action.skill_used:
		enemy_current_energy = maxi(
			enemy_current_energy - result.enemy_action.skill_used.energy_cost, 0
		)
	current_round += 1
```

**Step 2: Commit**
```bash
git add src/Entities/Systems/Combat/combat_context.gd
git commit -m "feat(combat): add CombatContext"
```

---

### Task 9: CombatFlowController (round loop + timer)

**Files:**
- Create: `src/Entities/Systems/Combat/combat_flow_controller.gd`

**Step 1: Write the file**

```gdscript
class_name CombatFlowController
extends Node

## Owns the round loop, action timer, and AI submission.
## Emits CombatEvents signals. Delegates damage math to CombatRoundResolver.

const ACTION_TIMEOUT_SECONDS: float = 20.0

signal round_started(round_number: int)
signal awaiting_player_action()
signal round_result_ready(result: CombatRoundResult)

@onready var _resolver: CombatRoundResolver = $CombatRoundResolver

var _context: CombatContext = null
var _ai_strategy: CombatAiStrategy = null
var _player_action: CombatAction = null
var _timer: float = 0.0
var _waiting_for_player: bool = false


func start_combat(context: CombatContext, ai_strategy: CombatAiStrategy) -> void:
	_context = context
	_ai_strategy = ai_strategy
	_start_next_round()


## Called by UI when player taps a skill button.
func submit_player_action(skill: SkillData) -> void:
	if not _waiting_for_player:
		return
	_player_action = CombatAction.make(_context.player_snapshot.combatant_id, skill)
	_waiting_for_player = false
	_resolve_round()


func _process(delta: float) -> void:
	if not _waiting_for_player:
		return
	_timer -= delta
	if _timer <= 0.0:
		# Timeout: auto-attack with no skill.
		submit_player_action(null)


func _start_next_round() -> void:
	_context.current_round += 1
	_player_action = null
	_timer = ACTION_TIMEOUT_SECONDS
	_waiting_for_player = true
	round_started.emit(_context.current_round)
	awaiting_player_action.emit()


func _resolve_round() -> void:
	_waiting_for_player = false
	var enemy_action: CombatAction = _ai_strategy.choose_action(
		_context.enemy_snapshot,
		_context.player_snapshot,
		_context.enemy_current_hp,
		_context.enemy_current_energy
	)

	var result: CombatRoundResult = _resolver.resolve(
		_context.current_round,
		_player_action,
		enemy_action,
		_context.player_snapshot,
		_context.enemy_snapshot,
		_context.player_current_hp,
		_context.enemy_current_hp
	)

	_context.apply_result(result)
	CombatEvents.round_resolved.emit(result)
	round_result_ready.emit(result)

	if result.combat_ended:
		CombatEvents.combat_ended.emit(result)
	else:
		_start_next_round()
```

**Step 2: Commit**
```bash
git add src/Entities/Systems/Combat/combat_flow_controller.gd
git commit -m "feat(combat): add CombatFlowController"
```

---

## Phase 5 — Enemy AI

### Task 10: CombatAiStrategy base + weighted random implementation

**Files:**
- Create: `src/Entities/Systems/Combat/Ai/combat_ai_strategy.gd`
- Create: `src/Entities/Systems/Combat/Ai/weighted_random_strategy.gd`

**Step 1: Write the base resource**

```gdscript
class_name CombatAiStrategy
extends Resource

## Base class for creature AI strategies.
## Override choose_action() in subclasses.

func choose_action(
	_self_snapshot: CombatantSnapshot,
	_opponent_snapshot: CombatantSnapshot,
	_self_current_hp: int,
	_self_current_energy: int
) -> CombatAction:
	push_error("CombatAiStrategy.choose_action() must be overridden.")
	return CombatAction.make(_self_snapshot.combatant_id, null)
```

**Step 2: Write the weighted random strategy**

```gdscript
class_name WeightedRandomStrategy
extends CombatAiStrategy

## Default AI: picks a random affordable skill, falls back to auto-attack.

func choose_action(
	self_snapshot: CombatantSnapshot,
	_opponent_snapshot: CombatantSnapshot,
	_self_current_hp: int,
	self_current_energy: int
) -> CombatAction:
	var affordable: Array[SkillData] = []
	for skill in self_snapshot.skill_loadout:
		if skill.energy_cost <= self_current_energy:
			affordable.append(skill)

	if affordable.is_empty():
		return CombatAction.make(self_snapshot.combatant_id, null)

	var chosen: SkillData = affordable[randi() % affordable.size()]
	return CombatAction.make(self_snapshot.combatant_id, chosen)
```

**Step 3: Commit**
```bash
git add src/Entities/Systems/Combat/Ai/
git commit -m "feat(combat): add CombatAiStrategy and WeightedRandomStrategy"
```

---

## Phase 6 — Extend CreatureData

### Task 11: Add combat fields to CreatureData

**Files:**
- Modify: `src/Entities/Creatures/creature_data.gd`

**Step 1: Add a new export group at the end of the file** (before the closing `func` block)

```gdscript
@export_group("Turn-Based Combat")
## Skills available in turn-based combat. Populated via .tres in the editor.
@export var skill_loadout: Array[SkillData] = []
## AI strategy used in turn-based encounters. Defaults to weighted random if null.
@export var ai_strategy: CombatAiStrategy = null
```

**Step 2: Add helper method** (after the existing `validate_for_runtime` func)

```gdscript
func get_skill_loadout() -> Array[SkillData]:
	return skill_loadout


func get_ai_strategy() -> CombatAiStrategy:
	if ai_strategy:
		return ai_strategy
	return WeightedRandomStrategy.new()
```

**Step 3: Verify** — open editor, select any creature `.tres`, confirm new "Turn-Based Combat" export group appears in Inspector with no errors.

**Step 4: Commit**
```bash
git add src/Entities/Creatures/creature_data.gd
git commit -m "feat(combat): extend CreatureData with skill_loadout and ai_strategy"
```

---

## Phase 7 — Combat Preview Panel

### Task 12: CombatPreviewPanel overlay

**Files:**
- Create: `src/Ui/Common/CombatPreviewPanel/combat_preview_panel.gd`
- Create: `src/Ui/Common/CombatPreviewPanel/combat_preview_panel.tscn`

**Step 1: Write the script**

```gdscript
class_name CombatPreviewPanel
extends AdaptiveOverlayPanel

## Pre-fight info card shown after tapping a creature.
## Emits fight_confirmed when player taps FIGHT, or dismissed on X.

signal fight_confirmed(enemy_snapshot: CombatantSnapshot)
signal dismissed()

@onready var _portrait: TextureRect = $Layout/EnemyPortrait
@onready var _name_label: Label = $Layout/NameLabel
@onready var _level_label: Label = $Layout/LevelLabel
@onready var _power_label: Label = $Layout/PowerLabel
@onready var _fight_button: Button = $Layout/Buttons/FightButton
@onready var _flee_button: Button = $Layout/Buttons/FleeButton

var _enemy_snapshot: CombatantSnapshot = null


func show_for_creature(creature_data: CreatureData) -> void:
	_enemy_snapshot = CombatantSnapshot.from_creature(creature_data)
	_populate_ui(creature_data)
	show()


func _ready() -> void:
	_fight_button.pressed.connect(_on_fight_pressed)
	_flee_button.pressed.connect(_on_flee_pressed)


func _populate_ui(creature_data: CreatureData) -> void:
	_name_label.text = creature_data.display_name
	_level_label.text = "Lv. %d" % _enemy_snapshot.level
	_portrait.texture = creature_data.sprite_sheet

	## Rough power indicator vs player (placeholder until player stats exist).
	_power_label.text = _get_power_label(creature_data)


func _get_power_label(creature_data: CreatureData) -> String:
	## Simple threshold — replace with real stat comparison once player stats exist.
	if creature_data.max_health >= 200 or creature_data.damage >= 30:
		return "Stronger"
	if creature_data.max_health <= 30 or creature_data.damage <= 5:
		return "Weaker"
	return "Even Match"


func _on_fight_pressed() -> void:
	hide()
	fight_confirmed.emit(_enemy_snapshot)


func _on_flee_pressed() -> void:
	hide()
	dismissed.emit()
```

**Step 2: Build the scene in the editor**

Create `combat_preview_panel.tscn` with this node tree:
```
CombatPreviewPanel (script: combat_preview_panel.gd, extends AdaptiveOverlayPanel)
  └─ Layout (VBoxContainer)
       ├─ EnemyPortrait (TextureRect)  — stretch_mode: KEEP_ASPECT_CENTERED, custom_minimum_size: 256x256
       ├─ NameLabel (Label)            — horizontal_alignment: CENTER
       ├─ LevelLabel (Label)           — horizontal_alignment: CENTER
       ├─ PowerLabel (Label)           — horizontal_alignment: CENTER
       └─ Buttons (HBoxContainer)
            ├─ FleeButton (Button)     — text: "Flee"
            └─ FightButton (Button)    — text: "Fight!"
```

**Step 3: Commit**
```bash
git add src/Ui/Common/CombatPreviewPanel/
git commit -m "feat(combat): add CombatPreviewPanel overlay"
```

---

## Phase 8 — Combat Scene

### Task 13: Combat scene entry point

**Files:**
- Create: `src/World/Combat/combat_scene.tscn`
- Create: `src/World/Combat/combat_scene.gd`

**Step 1: Write combat_scene.gd**

```gdscript
class_name CombatScene
extends Node

## Entry point for the combat game state.
## Receives context from CombatEvents.combat_confirmed and wires the flow.

@onready var _flow_controller: CombatFlowController = $CombatFlowController
@onready var _combat_ui: Node = $CombatUi

var _context: CombatContext = null


func _ready() -> void:
	if not CombatEvents.combat_confirmed.is_connected(_on_combat_confirmed):
		CombatEvents.combat_confirmed.connect(_on_combat_confirmed)
	if not CombatEvents.combat_ended.is_connected(_on_combat_ended):
		CombatEvents.combat_ended.connect(_on_combat_ended)


func _on_combat_confirmed(
	player_snapshot: CombatantSnapshot,
	enemy_snapshot: CombatantSnapshot
) -> void:
	_context = CombatContext.from_snapshots(player_snapshot, enemy_snapshot)
	var strategy: CombatAiStrategy = WeightedRandomStrategy.new()
	_flow_controller.start_combat(_context, strategy)
	if _combat_ui and _combat_ui.has_method("initialize"):
		_combat_ui.call("initialize", _context)


func _on_combat_ended(_result: CombatRoundResult) -> void:
	## Small delay so the UI can show the result before leaving.
	await get_tree().create_timer(1.5).timeout
	GameManager.change_state(GameManager.GameState.OVERWORLD)
```

**Step 2: Build the scene in the editor**

Create `combat_scene.tscn`:
```
CombatScene (script: combat_scene.gd)
  ├─ CombatFlowController (script: combat_flow_controller.gd)
  │    └─ CombatRoundResolver (script: combat_round_resolver.gd)
  └─ CombatUi (Node — placeholder, wired in Task 14)
```

**Step 3: Commit**
```bash
git add src/World/Combat/
git commit -m "feat(combat): add combat scene entry point"
```

---

### Task 14: Mobile combat UI layout

**Files:**
- Create: `src/Ui/Mobile/Combat/mobile_combat_ui.tscn`
- Create: `src/Ui/Mobile/Combat/mobile_combat_ui.gd`

**Step 1: Write mobile_combat_ui.gd**

```gdscript
class_name MobileCombatUi
extends Control

## Mobile portrait combat UI (1080x1920).
## Layout: enemy panel (top 35%) / round log (mid 25%) / player panel + skills (bottom 40%).

@onready var _enemy_name: Label = $EnemyPanel/NameLabel
@onready var _enemy_hp_bar: ProgressBar = $EnemyPanel/HpBar
@onready var _player_hp_bar: ProgressBar = $PlayerPanel/HpBar
@onready var _player_energy_bar: ProgressBar = $PlayerPanel/EnergyBar
@onready var _round_log: RichTextLabel = $RoundLog
@onready var _skill_bar: HBoxContainer = $PlayerPanel/SkillBar
@onready var _timer_label: Label = $PlayerPanel/TimerLabel

var _context: CombatContext = null
var _flow_controller: CombatFlowController = null


func initialize(context: CombatContext) -> void:
	_context = context
	_refresh_hp_bars()
	_enemy_name.text = context.enemy_snapshot.display_name
	_build_skill_bar(context.player_snapshot.skill_loadout)

	## Wire to flow controller signals.
	var flow: CombatFlowController = get_tree().get_first_node_in_group("combat_flow")
	if flow:
		_flow_controller = flow
		flow.round_started.connect(_on_round_started)
		flow.round_result_ready.connect(_on_round_result)
		flow.awaiting_player_action.connect(_on_awaiting_player_action)

	CombatEvents.round_resolved.connect(_on_round_resolved)


func _on_round_started(round_number: int) -> void:
	_round_log.append_text("\n--- Round %d ---" % round_number)
	_timer_label.text = "20s"


func _on_awaiting_player_action() -> void:
	_set_skill_bar_enabled(true)


func _on_round_result(result: CombatRoundResult) -> void:
	_set_skill_bar_enabled(false)
	_refresh_hp_bars()
	_append_round_log(result)


func _on_round_resolved(_result: CombatRoundResult) -> void:
	pass  # reserved for animations


func _refresh_hp_bars() -> void:
	if _context == null:
		return
	_enemy_hp_bar.max_value = _context.enemy_snapshot.base_stats.max_hp
	_enemy_hp_bar.value = _context.enemy_current_hp
	_player_hp_bar.max_value = _context.player_snapshot.base_stats.max_hp
	_player_hp_bar.value = _context.player_current_hp
	_player_energy_bar.max_value = _context.player_snapshot.base_stats.max_energy
	_player_energy_bar.value = _context.player_current_energy


func _build_skill_bar(skills: Array[SkillData]) -> void:
	for child in _skill_bar.get_children():
		child.queue_free()
	for skill in skills:
		var btn := Button.new()
		btn.text = skill.display_name
		btn.tooltip_text = "%s\nCost: %d energy" % [skill.display_name, skill.energy_cost]
		btn.pressed.connect(func(): _on_skill_pressed(skill))
		_skill_bar.add_child(btn)


func _on_skill_pressed(skill: SkillData) -> void:
	if _flow_controller:
		_flow_controller.submit_player_action(skill)


func _set_skill_bar_enabled(enabled: bool) -> void:
	for child in _skill_bar.get_children():
		if child is Button:
			(child as Button).disabled = not enabled


func _append_round_log(result: CombatRoundResult) -> void:
	if result.hp_delta_enemy < 0:
		_round_log.append_text("\nYou dealt %d damage." % abs(result.hp_delta_enemy))
	elif result.hp_delta_enemy > 0:
		_round_log.append_text("\nYou healed enemy for %d." % result.hp_delta_enemy)
	if result.hp_delta_player < 0:
		_round_log.append_text("\nEnemy dealt %d damage to you." % abs(result.hp_delta_player))
	elif result.hp_delta_player > 0:
		_round_log.append_text("\nYou healed %d HP." % result.hp_delta_player)
	if result.combat_ended:
		if result.winner_id == _context.player_snapshot.combatant_id:
			_round_log.append_text("\n[b]Victory![/b]")
		elif result.winner_id == _context.enemy_snapshot.combatant_id:
			_round_log.append_text("\n[b]Defeated![/b]")
		else:
			_round_log.append_text("\n[b]Draw![/b]")
```

**Step 2: Build the scene in the editor**

Create `mobile_combat_ui.tscn`:
```
MobileCombatUi (Control, script: mobile_combat_ui.gd, anchor: full rect)
  ├─ EnemyPanel (VBoxContainer) — top 35% of screen
  │    ├─ NameLabel (Label)
  │    └─ HpBar (ProgressBar)
  ├─ RoundLog (RichTextLabel) — middle 25%, bbcode_enabled: true, scroll follows output
  └─ PlayerPanel (VBoxContainer) — bottom 40%
       ├─ HpBar (ProgressBar)
       ├─ EnergyBar (ProgressBar)
       ├─ SkillBar (HBoxContainer)
       └─ TimerLabel (Label)
```

**Step 3: Add `CombatFlowController` to the `combat_flow` group** in the combat scene inspector (select the node → Groups → add `combat_flow`).

**Step 4: Commit**
```bash
git add src/Ui/Mobile/Combat/
git commit -m "feat(combat): add mobile combat UI layout"
```

---

## Phase 9 — Overworld Wiring

### Task 15: Wire overworld → preview panel → combat

**Files:**
- Modify: `src/World/Overworld/overworld.gd` (or `overworld.tscn`)
- Modify: `src/World/Overworld/overworld_creature_selection_controller.gd`

**Context:** `CreatureEvents.creature_fight_requested` is already emitted when the player taps FIGHT on the creature HUD. Currently nothing listens to it. We intercept it to show the preview panel instead of going directly to combat.

**Step 1: Add CombatPreviewPanel to the overworld scene**

In the Godot editor, open `src/World/Overworld/overworld.tscn`:
- Add `CombatPreviewPanel` node (instance `combat_preview_panel.tscn`) as a child of the root
- Name it `CombatPreviewPanel`

**Step 2: Wire in overworld.gd**

Find where `overworld.gd` wires up its controllers and add:

```gdscript
@onready var _combat_preview_panel: CombatPreviewPanel = $CombatPreviewPanel


func _ready() -> void:
	# ... existing _ready code ...
	_wire_combat_preview()


func _wire_combat_preview() -> void:
	if not CreatureEvents.creature_fight_requested.is_connected(_on_creature_fight_requested):
		CreatureEvents.creature_fight_requested.connect(_on_creature_fight_requested)
	if _combat_preview_panel:
		_combat_preview_panel.fight_confirmed.connect(_on_combat_fight_confirmed)
		_combat_preview_panel.dismissed.connect(_on_combat_preview_dismissed)


func _on_creature_fight_requested(creature_node: Node) -> void:
	var creature: Creature = creature_node as Creature
	if creature == null or not is_instance_valid(creature):
		return
	if _combat_preview_panel:
		_combat_preview_panel.show_for_creature(creature.creature_data)


func _on_combat_fight_confirmed(enemy_snapshot: CombatantSnapshot) -> void:
	## Build player snapshot (placeholder stats until player combat component exists).
	var player_snap := _build_player_snapshot()
	CombatEvents.combat_confirmed.emit(player_snap, enemy_snapshot)
	GameManager.change_state(GameManager.GameState.COMBAT)


func _on_combat_preview_dismissed() -> void:
	pass  # nothing to do, panel already hid itself


func _build_player_snapshot() -> CombatantSnapshot:
	var stats := CombatStats.new()
	stats.max_hp = 100
	stats.max_energy = 100
	stats.attack = 12.0
	stats.defense = 5.0
	var snap := CombatantSnapshot.new()
	snap.combatant_id = &"player"
	snap.display_name = "Player"
	snap.level = 1
	snap.base_stats = stats
	## TODO: replace with real player gear loadout in Task 17.
	snap.skill_loadout = []
	return snap
```

**Step 3: Register combat scene with the scene loader**

The `GameManager` emits `game_state_changed`. Find where the overworld listens to this (likely `overworld_session_controller.gd` or `main.tscn`) and add:

```gdscript
func _on_game_state_changed(old_state: GameManager.GameState, new_state: GameManager.GameState) -> void:
	if new_state == GameManager.GameState.COMBAT:
		get_tree().change_scene_to_file("res://src/World/Combat/combat_scene.tscn")
```

Check `src/World/main.tscn` / `src/World/Overworld/overworld_session_controller.gd` for where scene transitions are already handled and add the COMBAT case there.

**Step 4: Manual smoke test**

1. Run the game (F5)
2. Walk toward any creature on the overworld
3. Tap the creature → creature action HUD appears → tap FIGHT
4. `CombatPreviewPanel` should slide in showing creature info
5. Tap FIGHT → combat scene loads
6. Skill bar appears, round starts, timer counts down

**Step 5: Commit**
```bash
git add src/World/Overworld/overworld.gd src/World/Overworld/overworld.tscn
git commit -m "feat(combat): wire overworld → preview panel → combat scene"
```

---

## Phase 10 — Basic XP and Leveling

### Task 16: Extend PlayerProfileService with XP and level

**Files:**
- Modify: `src/Core/player_profile_service.gd`

**Step 1: Add constants and vars**

```gdscript
const COMBAT_SECTION: String = "combat"
const KEY_PLAYER_LEVEL: String = "player_level"
const KEY_PLAYER_XP: String = "player_xp"
const BASE_XP_PER_LEVEL: int = 100  ## XP needed: level * BASE_XP_PER_LEVEL

var _player_level: int = 1
var _player_xp: int = 0
```

**Step 2: Load/save in existing `_ready`, `_load_locale_preference`, and `_save_locale_preference`**

Add calls to `_load_combat_profile()` in `_ready()` and call `_save_combat_profile()` whenever XP changes.

```gdscript
func _load_combat_profile() -> void:
	var profile_data: ConfigFile = ConfigFile.new()
	if profile_data.load(PROFILE_SAVE_PATH) != OK:
		return
	_player_level = int(profile_data.get_value(COMBAT_SECTION, KEY_PLAYER_LEVEL, 1))
	_player_xp = int(profile_data.get_value(COMBAT_SECTION, KEY_PLAYER_XP, 0))


func _save_combat_profile() -> void:
	var profile_data: ConfigFile = ConfigFile.new()
	profile_data.load(PROFILE_SAVE_PATH)
	profile_data.set_value(COMBAT_SECTION, KEY_PLAYER_LEVEL, _player_level)
	profile_data.set_value(COMBAT_SECTION, KEY_PLAYER_XP, _player_xp)
	profile_data.save(PROFILE_SAVE_PATH)


func get_player_level() -> int:
	return _player_level


func get_player_xp() -> int:
	return _player_xp


func add_xp(amount: int) -> void:
	_player_xp += amount
	var xp_needed: int = _player_level * BASE_XP_PER_LEVEL
	while _player_xp >= xp_needed:
		_player_xp -= xp_needed
		_player_level += 1
		xp_needed = _player_level * BASE_XP_PER_LEVEL
	_save_combat_profile()
```

**Step 3: Listen to `CombatEvents.combat_ended` in overworld to award XP**

In `overworld.gd` (or `overworld_session_controller.gd`), add:

```gdscript
func _wire_combat_preview() -> void:
	# ... existing wiring ...
	if not CombatEvents.combat_ended.is_connected(_on_combat_ended):
		CombatEvents.combat_ended.connect(_on_combat_ended)


func _on_combat_ended(result: CombatRoundResult) -> void:
	if result.winner_id == &"player":
		## Award XP from creature data. Use a fixed amount for now.
		PlayerProfileService.add_xp(50)
```

**Step 4: Commit**
```bash
git add src/Core/player_profile_service.gd src/World/Overworld/overworld.gd
git commit -m "feat(combat): add XP and level tracking to PlayerProfileService"
```

---

## Acceptance Criteria

- [ ] Tap a creature on the overworld → `CombatPreviewPanel` appears with creature name, level, and power comparison
- [ ] Tap FIGHT → combat scene loads, round 1 begins
- [ ] Tap FLEE → panel dismisses, overworld resumes
- [ ] Skill bar shows player skills (empty for now → auto-attack only)
- [ ] Round timer counts down; timeout triggers auto-attack
- [ ] Round log shows damage dealt and received each round
- [ ] HP bars update after each round
- [ ] Combat ends when either HP reaches 0; "Victory!" or "Defeated!" shown
- [ ] After 1.5s delay, game returns to overworld
- [ ] Winning awards 50 XP; `PlayerProfileService.get_player_xp()` returns the updated value
- [ ] All resolver tests pass headlessly: `exit code 0`

---

## Out of Scope (Future Tasks)

- Player gear loadout → real skill bar (requires Equipment system)
- Gear mastery tracking
- Zone-based risk and loot drops
- Group / party combat
- Status effects
- Combat animations and VFX
- Desktop UI variant (`src/Ui/Windows/Combat/`)
- Player combat stats driven by level (currently hardcoded to 100 HP / 12 ATK)
