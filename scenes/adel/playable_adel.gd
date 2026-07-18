extends CharacterBody2D

@onready var weapon_pivot = $WeaponPivot
@onready var dodge_cooldown = $DodgeCooldown
@onready var spine_rig = $SpinePivot/SpineRig
@onready var spine_anim = $SpinePivot/SpineRig/AnimationPlayer
@onready var spine_pivot = $SpinePivot

const WALK_SPEED := 140.0
const RUN_SPEED := 450.0
const RUN_BOOST_SPEED := 520.0
const RUN_BOOST_TIME := 0.22
const GROUND_ACCEL := 1400.0
const GROUND_FRICTION := 1600.0
const TURN_ACCEL := 3200.0
const AIR_ACCEL_STAND := 320.0
const AIR_ACCEL_RUN := 980.0
const AIR_SPEED_CAP_STAND := 95.0
const AIR_SPEED_CAP_RUN := RUN_SPEED
const WALK_JUMP_VELOCITY := -480.0
const RUN_JUMP_VELOCITY := -720.0
const DOUBLE_JUMP_VELOCITY := -700.0
const ENEMY_COLLISION_LAYER := 3
const JUMP_RISE_GRAVITY_MULT := 1.6
const JUMP_CUT_GRAVITY_MULT := 3.2
const FALL_GRAVITY_MULT := 2
const MAX_FALL_SPEED := 920.0
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
var _run_boost_timer := 0.0
var _was_running := false
var _air_accel := AIR_ACCEL_STAND
var _air_speed_cap := AIR_SPEED_CAP_STAND
var has_air_dashed: bool = false
var is_skidding: bool = false 


func _ready() -> void:
	randomize()
	spine_anim.animation_finished.connect(_on_spine_anim_finished)
	spine_anim.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_take_damage"):
		take_damage(DEBUG_DAMAGE_AMOUNT, global_position + Vector2(80.0, 0.0))
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("attack") and not is_doing_action:
		player_attacked.emit()
		is_doing_action = true
	if event.is_action_pressed("interact"):
		play_pickup_animation()

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
	spine_anim.play("idle", 0.1)
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
	spine_anim.play("idle")
func play_rest_animation() -> void:
	spine_anim.play("RESET", 0.0, 1.0, true)
	spine_anim.advance(0) 
	spine_anim.play("rest", 0.0)

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


func _get_ground_target_speed() -> float:
	if is_running:
		if _run_boost_timer > 0.0:
			return RUN_BOOST_SPEED
		return RUN_SPEED
	return WALK_SPEED


func _uses_run_jump() -> bool:
	return is_running or absf(velocity.x) >= WALK_SPEED * 0.7


func _get_ground_jump_velocity() -> float:
	if _uses_run_jump():
		return RUN_JUMP_VELOCITY
	return WALK_JUMP_VELOCITY


func _set_enemy_collision_enabled(enabled: bool) -> void:
	set_collision_mask_value(ENEMY_COLLISION_LAYER, enabled)


func _begin_air_movement() -> void:
	if _uses_run_jump():
		_air_accel = AIR_ACCEL_RUN
		_air_speed_cap = AIR_SPEED_CAP_RUN
	else:
		_air_accel = AIR_ACCEL_STAND
		_air_speed_cap = AIR_SPEED_CAP_STAND


func _apply_vertical_physics(delta: float) -> void:
	if is_on_floor():
		return

	var gravity := get_gravity() * delta
	
	if velocity.y < 0.0:
		gravity *= JUMP_RISE_GRAVITY_MULT
	elif velocity.y > 0.0:
		gravity *= FALL_GRAVITY_MULT

	velocity += gravity
	velocity.y = minf(velocity.y, MAX_FALL_SPEED)
func _apply_horizontal_movement(direction: float, delta: float) -> void:
	if not is_on_floor():
		if direction != 0.0:
			var target_x := direction * _air_speed_cap
			velocity.x = move_toward(velocity.x, target_x, _air_accel * delta)
			velocity.x = clampf(velocity.x, -_air_speed_cap, _air_speed_cap)
		return

	var target_speed := _get_ground_target_speed()
	if direction != 0.0:
		var target_x := direction * target_speed
		var accel := GROUND_ACCEL
		if signf(velocity.x) != 0.0 and signf(direction) != signf(velocity.x):
			accel = TURN_ACCEL
		velocity.x = move_toward(velocity.x, target_x, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, GROUND_FRICTION * delta)


func _update_facing(direction: float) -> void:
	if direction == 0.0:
		return
	facing_direction = -1 if direction < 0 else 1
	var current_scale := absf(spine_pivot.scale.x)
	spine_pivot.scale.x = -current_scale if direction < 0 else current_scale


func _play_jump_start() -> void:
	_playing_land_anim = false
	spine_rig.visible = true
	spine_anim.play(ANIM_JUMP_START, 0.05)


func _play_jump_land() -> void:
	_playing_land_anim = true
	spine_rig.visible = true
	spine_anim.play(ANIM_JUMP_LAND, 0.1)


func _update_ground_animation(direction: float) -> void:
	if not is_on_floor() or _playing_land_anim:
		return
	spine_rig.visible = true

	var current_speed := absf(velocity.x)

	if direction != 0.0:
		if is_skidding:
			is_skidding = false
			spine_anim.play("skid")
			spine_anim.seek(spine_anim.current_animation_length, true)

		if is_running and current_speed > WALK_SPEED:
			if spine_anim.current_animation != "run":
				spine_anim.play("run")
		else:
			if spine_anim.current_animation != "walk":
				spine_anim.play("walk")
				
	else:
		if _playing_land_anim:
			return

		if current_speed > WALK_SPEED * 0.8:
			if not is_skidding:
				is_skidding = true
				spine_anim.play("skid")
		elif current_speed < 10.0 and not is_skidding:
			if spine_anim.current_animation != "idle":
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
	elif anim_name == "skid":
		is_skidding = false
		_update_ground_animation(Input.get_axis("move_left", "move_right"))
	elif anim_name == "loot":
		can_move = true
		is_doing_action = false
		# Ép nhân vật quay lại dáng đứng im (idle) hoặc chạy tiếp nếu người chơi đang giữ nút di chuyển
		_update_ground_animation(Input.get_axis("move_left", "move_right"))

func _handle_jump_input() -> void:
	if not Input.is_action_just_pressed("jump"):
		return
	if is_on_floor():
		_begin_air_movement()
		velocity.y = _get_ground_jump_velocity()
		_jumps_remaining = MAX_JUMPS - 1
		has_air_dashed = false
		_play_jump_start()
	elif _jumps_remaining > 0:
		velocity.y = DOUBLE_JUMP_VELOCITY
		_jumps_remaining -= 1
		has_air_dashed = false
		_play_jump_start()


func _physics_process(delta: float) -> void:
	if is_stunned or is_touched_enemy:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		_apply_vertical_physics(delta)
		move_and_slide()

		if is_touched_enemy and is_on_floor():
			can_move = true
			is_touched_enemy = false
			is_invulnerable = false
		return
	if is_stunned:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		_apply_vertical_physics(delta)
		move_and_slide()
		return
	if is_resting:
		velocity = Vector2.ZERO
		return
	if is_locked or not can_move:
		velocity.x = 0
		move_and_slide()
		return

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
	if is_running and not _was_running and is_on_floor():
		_run_boost_timer = RUN_BOOST_TIME
	_was_running = is_running
	if _run_boost_timer > 0.0:
		_run_boost_timer = maxf(_run_boost_timer - delta, 0.0)

	var direction := Input.get_axis("move_left", "move_right")

	if is_dodging:
		velocity.y = 0
	else:
		var wants_dash = Input.is_action_just_pressed("dodge") and not is_dodging and able_to_dodge
		var can_ground_dash = is_on_floor() and direction != 0.0
		var can_air_dash = not is_on_floor() and not has_air_dashed
		
		if wants_dash and (can_ground_dash or can_air_dash):
			is_dodging = true
			is_invulnerable = true
			_set_enemy_collision_enabled(false)
			spine_anim.play("dash")
			_ghost_trail_loop(0.1)
			
			var is_air_dodging = not is_on_floor()
			if is_air_dodging:
				has_air_dashed = true 
				
			var dash_dir = direction
			if is_air_dodging and dash_dir == 0.0:
				dash_dir = facing_direction
			var dodge_tween = create_tween()
			dodge_tween.set_trans(Tween.TRANS_QUAD)
			dodge_tween.set_ease(Tween.EASE_OUT)
			
			velocity.x = WALK_SPEED * 20 * dash_dir
			dodge_tween.tween_property(self, "velocity:x", dash_dir * WALK_SPEED, 0.3)
			
			await dodge_tween.finished
			
			_set_enemy_collision_enabled(true)
			is_invulnerable = false
			if not is_air_dodging:
				velocity.x = 0
				spine_anim.play("dash skid")
				await get_tree().create_timer(0.2).timeout
				
			dodge_cooldown.start()
			able_to_dodge = false
			is_dodging = false

		if can_move:
			_apply_horizontal_movement(direction, delta)
			_update_facing(direction)
			_update_ground_animation(direction)
			
	_handle_jump_input()
	_apply_vertical_physics(delta)

	move_and_slide()
	_update_air_animation()

	if is_on_floor():
		_jumps_remaining = MAX_JUMPS
		has_air_dashed = false
		if not _was_on_floor:
			_play_jump_land()
	elif _was_on_floor:
		_begin_air_movement()
	_was_on_floor = is_on_floor()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("Enemy"):
			if is_dodging or is_invulnerable or is_touched_enemy:
				continue
			take_damage(1, collider.global_position)
			knockback_when_touch_enemy(collider.global_position)
			break

func play_pickup_animation() -> void:
	if not is_on_floor() or is_dodging or is_stunned or is_doing_action:
		return 
		
	can_move = false
	is_doing_action = true
	velocity.x = 0 
	
	# Bật animation nhặt đồ
	spine_anim.play("loot")
func _on_dodge_cooldown_timeout() -> void:
	able_to_dodge = true
	
func _get_all_visible_sprites(node: Node, arr: Array) -> void:
	if node is Sprite2D and node.visible:
		arr.append(node)
	for child in node.get_children():
		_get_all_visible_sprites(child, arr)
func _spawn_ghost_trail() -> void:
	var ghost_parent = Node2D.new()
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(ghost_parent)
	
	var sprites: Array = []
	_get_all_visible_sprites(spine_rig, sprites)
	
	for s in sprites:
		var ghost_sprite = Sprite2D.new()
		ghost_sprite.texture = s.texture
		ghost_sprite.hframes = s.hframes
		ghost_sprite.vframes = s.vframes
		ghost_sprite.frame = s.frame
		ghost_sprite.flip_h = s.flip_h
		ghost_sprite.flip_v = s.flip_v
		
		ghost_sprite.global_transform = s.global_transform
		
		ghost_sprite.modulate = Color(0.2, 0.2, 0.2, 0.6) 
		
		ghost_parent.add_child(ghost_sprite)
	
	var tween = get_tree().create_tween()
	tween.tween_property(ghost_parent, "modulate:a", 0.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(ghost_parent.queue_free)
	
func _ghost_trail_loop(duration: float) -> void:
	var interval = 0.5
	var elapsed = 0.0
	while elapsed < duration:
		_spawn_ghost_trail()
		await get_tree().create_timer(interval).timeout
		elapsed += interval
