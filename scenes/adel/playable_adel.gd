extends CharacterBody2D

@onready var weapon_pivot = $WeaponPivot
@onready var dodge_cooldown = $DodgeCooldown
@onready var spine_rig = $SpinePivot/SpineRig
@onready var spine_anim = $SpinePivot/SpineRig/AnimationPlayer
@onready var spine_pivot = $SpinePivot

const SPEED = 140.0
const JUMP_VELOCITY = -600.0
const DOUBLE_JUMP_VELOCITY = -500.0
const MAX_JUMPS := 2
const ANIM_JUMP_START := " jump_start"
const ANIM_JUMP_AIR := "jump_air (fall)"
const ANIM_JUMP_LAND := "jump_land"
const STAGGER_STUN_SEC := 0.45
const STAGGER_INVULN_SEC := 1.0
const STAGGER_KNOCKBACK := 300.0
const HIT_INVULN_SEC := 0.2
const DEBUG_DAMAGE_AMOUNT := 10
const KNOCKBACK_FORCE := 500

signal player_attacked

var can_move: bool = true
var is_locked: bool = false
var is_resting: bool = false
var is_guarding: bool = false
var holding_duration: float = 0.0
var _position_before_rest: Vector2 = Vector2.ZERO
var facing_direction: int = 1
var is_stunned: bool = false
var is_invulnerable: bool = false
var is_doing_action: bool = false
var is_dodging: bool = false
var able_to_dodge: bool = true
var is_touched_enemy: bool = false
var is_running: bool = false
var _jumps_remaining := MAX_JUMPS
var _was_on_floor := true
var _playing_land_anim := false


func _ready() -> void:
	randomize()
	spine_anim.animation_finished.connect(_on_spine_anim_finished)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_take_damage"):
		take_damage(DEBUG_DAMAGE_AMOUNT, global_position + Vector2(80.0, 0.0))
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("attack") and not is_doing_action:
		player_attacked.emit()
		is_doing_action = true


func take_damage(dmg: int, hit_from_global: Vector2 = Vector2.INF) -> void:
	if is_invulnerable or is_stunned:
		return

	var hud := _find_hud()
	if hud == null or not hud.has_method("apply_damage"):
		return

	var hit: Dictionary = hud.apply_damage(dmg, hit_from_global)
	if hit.get("staggered", false) and not hit.get("skip_player_stagger", false):
		_apply_stagger(_knockback_dir(hit_from_global))
	elif hit.get("damage_taken", 0) > 0:
		_start_invulnerability(HIT_INVULN_SEC)


func get_damage_dealt_multiplier() -> float:
	var hud := _find_hud()
	if hud and hud.has_method("get_damage_dealt_multiplier"):
		return hud.get_damage_dealt_multiplier()
	return 1.0


func get_attack_speed_multiplier() -> float:
	var hud := _find_hud()
	if hud and hud.has_method("get_attack_speed_multiplier"):
		return hud.get_attack_speed_multiplier()
	return 1.0


func _get_move_speed_multiplier() -> float:
	var hud := _find_hud()
	if hud and hud.has_method("get_move_speed_multiplier"):
		return hud.get_move_speed_multiplier()
	return 1.0


func _knockback_dir(hit_from_global: Vector2) -> Vector2:
	if hit_from_global != Vector2.INF:
		var dir := global_position - hit_from_global
		if dir.length_squared() > 0.01:
			var dir_normal = dir.normalized()
			if abs(dir_normal.x) < 0.1:
				dir_normal.x = -facing_direction
			dir_normal.y = randf_range(-0.2, -0.7)
			return dir_normal
	return Vector2(1.0 if facing_direction < 0 else -1.0, -0.2).normalized()


func _apply_stagger(knockback_dir: Vector2) -> void:
	is_stunned = true
	is_invulnerable = true
	can_move = false
	velocity = knockback_dir * STAGGER_KNOCKBACK
	_playing_land_anim = false
	spine_anim.play("idle")
	get_tree().create_timer(STAGGER_STUN_SEC).timeout.connect(_on_stagger_stun_end, CONNECT_ONE_SHOT)


func _on_stagger_stun_end() -> void:
	is_stunned = false
	can_move = true
	var remaining := maxf(STAGGER_INVULN_SEC - STAGGER_STUN_SEC, 0.0)
	if remaining > 0.0:
		get_tree().create_timer(remaining).timeout.connect(_end_invulnerability, CONNECT_ONE_SHOT)
	else:
		_end_invulnerability()


func knockback_when_touch_enemy(enemy_position: Vector2) -> void:
	is_invulnerable = true
	can_move = false
	is_touched_enemy = true
	velocity = _knockback_dir(enemy_position) * KNOCKBACK_FORCE


func _start_invulnerability(duration: float) -> void:
	is_invulnerable = true
	get_tree().create_timer(duration).timeout.connect(_end_invulnerability, CONNECT_ONE_SHOT)


func _end_invulnerability() -> void:
	is_invulnerable = false


func _find_hud() -> Node:
	var root := get_tree().current_scene
	if root == null:
		return null
	return root.find_child("hud", true, false)


func enter_rest(_world_position: Vector2, face_left: bool) -> void:
	_position_before_rest = global_position
	is_resting = true
	is_locked = true
	can_move = false
	velocity = Vector2.ZERO
	_playing_land_anim = false
	var current_scale = abs(spine_pivot.scale.x)
	spine_pivot.scale.x = -current_scale if face_left else current_scale
	facing_direction = -1 if face_left else 1
	spine_anim.play("rest")


func exit_rest() -> void:
	is_resting = false
	is_locked = false
	can_move = true
	velocity = Vector2.ZERO
	global_position = _position_before_rest
	snap_feet_to_floor()

	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0:
		var current_scale = abs(spine_pivot.scale.x)
		spine_pivot.scale.x = -current_scale if dir < 0 else current_scale
		facing_direction = -1 if dir < 0 else 1


func snap_feet_to_floor(max_drop: float = 96.0) -> void:
	var col := $CollisionShape2D as CollisionShape2D
	if col == null or col.shape == null:
		return
	var half_h := _capsule_half_height(col)
	var feet := Vector2(col.global_position.x, col.global_position.y + half_h)
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		feet + Vector2(0, -4.0),
		feet + Vector2(0, max_drop)
	)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	global_position.y += hit.position.y - feet.y


func _capsule_half_height(col: CollisionShape2D) -> float:
	var capsule := col.shape as CapsuleShape2D
	if capsule == null:
		return 32.0
	var scale_y := col.global_transform.get_scale().y
	return capsule.height * 0.5 * scale_y


func _play_jump_start() -> void:
	_playing_land_anim = false
	spine_rig.visible = true
	spine_anim.play(ANIM_JUMP_START)


func _play_jump_land() -> void:
	_playing_land_anim = true
	spine_rig.visible = true
	spine_anim.play(ANIM_JUMP_LAND)


func _update_ground_animation(direction: float) -> void:
	if not is_on_floor() or _playing_land_anim:
		return
	spine_rig.visible = true
	if direction != 0.0:
		if is_running:
			spine_anim.play("run")
		else:
			spine_anim.play("walk", -1, 1.5)
	else:
		spine_anim.stop()
		spine_anim.play("idle")


func _update_air_animation() -> void:
	if is_on_floor() or _playing_land_anim:
		return
	var current_anim: StringName = spine_anim.current_animation
	if current_anim == ANIM_JUMP_START or current_anim == ANIM_JUMP_AIR:
		return
	spine_rig.visible = true
	spine_anim.play(ANIM_JUMP_AIR)


func _on_spine_anim_finished(anim_name: StringName) -> void:
	if anim_name == ANIM_JUMP_START and not is_on_floor():
		spine_anim.play(ANIM_JUMP_AIR)
	elif anim_name == ANIM_JUMP_LAND:
		_playing_land_anim = false
		_update_ground_animation(Input.get_axis("move_left", "move_right"))


func _handle_jump_input() -> void:
	if not Input.is_action_just_pressed("jump"):
		return
	if is_on_floor():
		velocity.y = JUMP_VELOCITY
		_jumps_remaining = MAX_JUMPS - 1
		_play_jump_start()
	elif _jumps_remaining > 0:
		velocity.y = DOUBLE_JUMP_VELOCITY
		_jumps_remaining -= 1
		_play_jump_start()


func _physics_process(delta: float) -> void:
	if is_stunned or is_touched_enemy:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)

		if not is_on_floor():
			velocity += get_gravity() * delta

		move_and_slide()

		if is_touched_enemy and is_on_floor():
			can_move = true
			is_touched_enemy = false
			is_invulnerable = false
		return
	if is_stunned:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return
	if is_resting:
		velocity = Vector2.ZERO
		return
	if is_locked or not can_move:
		velocity.x = 0
		move_and_slide()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("guard and deflect") and not is_doing_action:
		is_guarding = true
		holding_duration = 0.0
		is_doing_action = true
	if is_guarding:
		holding_duration += delta
	if Input.is_action_just_released("guard and deflect") and is_doing_action and is_guarding:
		is_guarding = false
		is_doing_action = false
	if Input.is_action_just_pressed("run") and is_on_floor():
		is_running = not is_running
	var direction = Input.get_axis("move_left", "move_right")

	if is_dodging:
		if not is_on_floor():
			velocity += get_gravity() * delta
	else:
		if Input.is_action_just_pressed("dodge") and not is_dodging and able_to_dodge and is_on_floor():
			is_dodging = true
			is_invulnerable = true
			if direction:
				velocity.x = SPEED * 10 * direction
				var dodge_tween = create_tween()
				dodge_tween.set_trans(Tween.TRANS_QUAD)
				dodge_tween.set_ease(Tween.EASE_OUT)
				dodge_tween.tween_property(self, "velocity:x", direction * SPEED, 0.15)
				await dodge_tween.finished
			else:
				velocity.x = SPEED * 8 * -facing_direction
				var dodge_tween = create_tween()
				dodge_tween.set_trans(Tween.TRANS_QUAD)
				dodge_tween.set_ease(Tween.EASE_OUT)
				dodge_tween.tween_property(self, "velocity:x", facing_direction * SPEED, 0.15)
				await dodge_tween.finished
			dodge_cooldown.start()
			able_to_dodge = false
			is_invulnerable = false
			is_dodging = false

		if can_move:
			if direction:
				var current_speed = SPEED
				if is_running:
					current_speed = 450
				velocity.x = direction * current_speed
				facing_direction = -1 if direction < 0 else 1
				var current_scale = abs(spine_pivot.scale.x)
				spine_pivot.scale.x = -current_scale if direction < 0 else current_scale
				_update_ground_animation(direction)
			else:
				velocity.x = move_toward(velocity.x, 0, SPEED)
				_update_ground_animation(direction)

	_handle_jump_input()

	move_and_slide()
	_update_air_animation()

	if is_on_floor():
		_jumps_remaining = MAX_JUMPS
		if not _was_on_floor:
			_play_jump_land()
	_was_on_floor = is_on_floor()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("Enemy"):
			if not is_touched_enemy:
				take_damage(1, collider.global_position)
				knockback_when_touch_enemy(collider.global_position)
				break


func _on_dodge_cooldown_timeout() -> void:
	able_to_dodge = true
