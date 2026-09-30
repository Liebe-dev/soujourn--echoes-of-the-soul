extends CharacterBody2D
@onready var dodge_cooldown = $DodgeCooldown
@onready var spine_rig = $SpinePivot/SpineRig
@onready var spine_anim = $SpinePivot/SpineRig/AnimationPlayer
@onready var spine_pivot = $SpinePivot
@onready var weapon: WeaponData = $WeaponHolder/Saber
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var attack_hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D

const ENEMY_COLLISION_LAYER := 3
const ANIM_JUMP_START := " jump_start"
const ANIM_JUMP_AIR := "jump_air (fall)"
const ANIM_JUMP_LAND := "jump_land"
const DEBUG_DAMAGE_AMOUNT := 10
const KNOCKBACK_FORCE := 500
const ENEMY_CONTACT_DAMAGE := 1

signal player_attacked

var locomotion: LocomotionComponent
var combat: CombatComponent
var damage: DamageComponent
var dash: DashComponent

var can_move: bool = true
var is_locked: bool = false
var is_resting: bool = false
var is_guarding: bool = false
var holding_duration: float = 0.0
var _position_before_rest: Vector2 = Vector2.ZERO
var facing_direction: int = 1
var is_doing_action: bool = false
var _playing_land_anim := false
var is_skidding: bool = false 

#hàm hệ thống
func _ready() -> void:
	randomize()

	locomotion = LocomotionComponent.new(self)
	locomotion.jumped.connect(_on_locomotion_jumped)
	locomotion.landed.connect(_on_locomotion_landed)

	combat = CombatComponent.new(
		self,
		locomotion,
		weapon,
		$AttackHitbox
	)
	configure_attack_hitbox(combat.equipped_weapon)

	damage = DamageComponent.new(self)
	damage.staggered.connect(_on_damage_staggered)
	damage.stagger_recovered.connect(_on_damage_stagger_recovered)

	dash = DashComponent.new(locomotion, dodge_cooldown)

	spine_anim.animation_finished.connect(_on_spine_anim_finished)
	spine_anim.play("idle")
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_take_damage"):
		take_damage(DEBUG_DAMAGE_AMOUNT, global_position + Vector2(80.0, 0.0))
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("attack"):
		if combat.should_cancel_jump_attack_land():
			_cancel_jump_attack_land()

		match combat.handle_attack_input(is_doing_action):
			CombatComponent.AttackAction.START_JUMP_ATTACK:
				_play_jump_attack()

			CombatComponent.AttackAction.START_COMBO:
				_play_combo_step()

			_:
				pass

func _physics_process(delta: float) -> void:
	if damage.is_stunned or damage.is_touched_enemy:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		locomotion.apply_vertical_physics(delta)
		move_and_slide()

		if damage.is_touched_enemy and is_on_floor():
			can_move = true
			damage.is_touched_enemy = false
			damage.is_invulnerable = false
		return
	if is_resting:
		velocity = Vector2.ZERO
		return
	if combat.is_jump_attack_landing:
		combat.jump_attack_land_timer += delta
		if combat.jump_attack_land_timer >= 0.3 and Input.get_axis("move_left", "move_right") != 0.0:
			_cancel_jump_attack_land()

	if is_locked or not can_move:
		if not combat.apply_combat_air_physics(delta):
			locomotion.apply_vertical_physics(delta)
			
		velocity.x = move_toward(velocity.x, 0.0, locomotion.GROUND_FRICTION * delta)
		move_and_slide()
		
		if is_on_floor() and combat.is_jump_attacking:
			_play_jump_attack_land()
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

	locomotion.update_run_state(delta)

	var direction := Input.get_axis("move_left", "move_right")

	if dash.is_dodging:
		velocity.y = 0
	else:
		if dash.can_dash(direction, is_on_floor()):
			_perform_dash(direction)

		if can_move and not dash.is_dodging:
			locomotion.apply_horizontal_movement(direction, delta)
			_update_facing(direction)
			_update_ground_animation(direction)
	if not dash.is_dodging:
		locomotion.handle_jump()
		locomotion.apply_vertical_physics(delta)

	move_and_slide()
	_update_air_animation()
	locomotion.update_ground_state()

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("Enemy"):
			if dash.is_dodging or damage.is_invulnerable or damage.is_touched_enemy:
				continue
			take_damage(ENEMY_CONTACT_DAMAGE, collider.global_position)
			break

#hàm công khai
func take_damage(dmg: int, hit_from_global: Vector2 = Vector2.INF) -> void:
	if not damage.can_take_damage():
		return

	var hud := _find_hud()
	if hud == null or not hud.has_method("apply_damage"):
		return

	var hit: Dictionary = hud.apply_damage(dmg, hit_from_global)
	if hit.get("staggered", false) and not hit.get("skip_player_stagger", false):
		damage.apply_stagger(damage.compute_knockback_dir(hit_from_global, facing_direction))
	elif hit.get("damage_taken", 0) > 0:
		damage.start_invulnerability(DamageComponent.HIT_INVULN_SEC)

func change_weapon(new_weapon: WeaponData) -> void:
	combat.change_weapon(new_weapon)

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

func enter_rest(face_left: bool) -> void:
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

func play_pickup_animation() -> void:
	if not is_on_floor() or dash.is_dodging or damage.is_stunned or is_doing_action:
		return 
	can_move = false
	is_doing_action = true
	velocity.x = 0 
	spine_anim.play("loot")

#hàm nội bộ nhóm combat
func _play_combo_step() -> void:
	can_move = false
	is_doing_action = true
	velocity.x = 0
	_playing_land_anim = false 
	is_skidding = false
	velocity.x = facing_direction * 150.0
	if not is_on_floor():
		velocity.y = 0.0

	spine_anim.play(combat.get_attack_anim_name())
	combat.start_attack_hitbox_window()
func _reset_combo() -> void:
	combat.reset_combo_if_idle(is_doing_action)

func _play_jump_attack() -> void:
	can_move = false
	is_doing_action = true
	combat.start_jump_attack()
	velocity.x = 0 # Triệt tiêu đà ngang để cắm thẳng xuống
	velocity.y = 0.0
	spine_anim.play("jump_attack(air)")
	# Lưu ý: Chỉ cần tắt nút Loop (Vòng lặp) trong bảng AnimationPlayer cho 
	# animation "jump_attack(air)", nó sẽ tự động đóng băng ở frame cuối cùng khi đang rơi.

func _play_jump_attack_land() -> void:
	combat.begin_jump_attack_land()
	_playing_land_anim = false
	spine_anim.play("jump_attack(land)")

func _cancel_jump_attack_land() -> void:
	combat.cancel_jump_attack_land()
	can_move = true
	is_doing_action = false

func _find_hud() -> Node:
	var root := get_tree().current_scene
	if root == null:
		return null
	return root.find_child("hud", true, false)

#hàm nội bộ nhóm vật lý
func _get_move_speed_multiplier() -> float:
	var hud := _find_hud()
	if hud and hud.has_method("get_move_speed_multiplier"):
		return hud.get_move_speed_multiplier()
	return 1.0

func _perform_dash(dash_direction: float) -> void:
		var dash_info: Dictionary = dash.start_dash(dash_direction, is_on_floor(), facing_direction)
		damage.is_invulnerable = true
		_set_enemy_collision_enabled(false)
		var is_air_dodging: bool = dash_info["is_air"]
		var dash_dir: float = dash_info["direction"]
		if is_air_dodging:
			spine_anim.play("dash_air")
		else:
			spine_anim.play("dash")
		_ghost_trail_loop(0.25)
		var dodge_tween = create_tween()
		dodge_tween.set_trans(Tween.TRANS_QUAD)
		dodge_tween.set_ease(Tween.EASE_OUT)
		velocity.x = dash_info["initial_speed"] * dash_dir
		dodge_tween.tween_property(self, "velocity:x", dash_dir * dash_info["target_speed"], DashComponent.DASH_TWEEN_DURATION)
		await dodge_tween.finished
		if not is_instance_valid(self):
			return
		_set_enemy_collision_enabled(true)
		damage.is_invulnerable = false
		if not is_air_dodging:
			velocity.x = 0
			spine_anim.play("dash skid")
			await get_tree().create_timer(DashComponent.DASH_SKID_DURATION).timeout
			if not is_instance_valid(self):
				return
		else:
			velocity.x = 0
		dash.end_dash()

func _capsule_half_height(col: CollisionShape2D) -> float:
	var capsule := col.shape as CapsuleShape2D
	if capsule == null:
		return 32.0
	var scale_y := col.global_transform.get_scale().y
	return capsule.height * 0.5 * scale_y

func _set_enemy_collision_enabled(enabled: bool) -> void:
	set_collision_mask_value(ENEMY_COLLISION_LAYER, enabled)

#hàm nội bộ nhóm đồ họa
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

func _on_locomotion_jumped() -> void:
	dash.reset_air_dash()
	_play_jump_start()

func _on_locomotion_landed() -> void:
	dash.reset_air_dash()
	combat.has_air_comboed = false
	_play_jump_land()

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

		if locomotion.is_running and current_speed > locomotion.WALK_SPEED:
			if spine_anim.current_animation != "run":
				spine_anim.play("run")
		else:
			if spine_anim.current_animation != "walk":
				spine_anim.play("walk")
				
	else:
		if _playing_land_anim:
			return

		if current_speed > locomotion.WALK_SPEED * 0.8:
			if not is_skidding:
				is_skidding = true
				spine_anim.play("skid")
		elif current_speed < 10.0 and not is_skidding:
			if spine_anim.current_animation != "idle":
				spine_anim.play("idle")

func _update_air_animation() -> void:
	if is_on_floor() or _playing_land_anim or dash.is_dodging:
		return
	var current_anim: StringName = spine_anim.current_animation
	if current_anim == ANIM_JUMP_START or current_anim == ANIM_JUMP_AIR:
		return
	spine_rig.visible = true
	spine_anim.play(ANIM_JUMP_AIR)

func _get_all_visible_sprites(node: Node, arr: Array) -> void:
	if node is Sprite2D and node.visible:
		arr.append(node)
	for child in node.get_children():
		_get_all_visible_sprites(child, arr)

const GHOST_TRAIL_INTERVAL := 0.05
const GHOST_TRAIL_MAX := 24
const GHOST_FADE_DURATION := 0.15

var _ghost_pool: Array[Node2D] = []

func _spawn_ghost_trail() -> void:
	var sprites: Array = []
	_get_all_visible_sprites(spine_rig, sprites)
	if sprites.is_empty():
		return

	var ghost_parent := _get_pooled_ghost()
	if ghost_parent == null:
		ghost_parent = Node2D.new()
		ghost_parent.name = "GhostTrail"
		var current_scene = get_tree().current_scene
		if current_scene:
			current_scene.add_child(ghost_parent)

	ghost_parent.visible = true
	ghost_parent.modulate = Color(1, 1, 1, 0.6)

	for i in sprites.size():
		var src: Sprite2D = sprites[i]
		var dst: Sprite2D
		if i < ghost_parent.get_child_count():
			dst = ghost_parent.get_child(i) as Sprite2D
		else:
			dst = Sprite2D.new()
			dst.modulate = Color(0.2, 0.2, 0.2, 1.0)
			ghost_parent.add_child(dst)
		dst.visible = true
		dst.texture = src.texture
		dst.hframes = src.hframes
		dst.vframes = src.vframes
		dst.frame = src.frame
		dst.flip_h = src.flip_h
		dst.flip_v = src.flip_v
		dst.global_transform = src.global_transform

	for i in range(sprites.size(), ghost_parent.get_child_count()):
		var extra := ghost_parent.get_child(i) as Sprite2D
		if extra:
			extra.visible = false

	var tween := get_tree().create_tween()
	tween.tween_property(ghost_parent, "modulate:a", 0.0, GHOST_FADE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_recycle_ghost.bind(ghost_parent))

func _get_pooled_ghost() -> Node2D:
	while not _ghost_pool.is_empty():
		var ghost: Node2D = _ghost_pool.pop_back()
		if is_instance_valid(ghost):
			return ghost
	return null

func _recycle_ghost(ghost_parent: Node2D) -> void:
	if not is_instance_valid(ghost_parent):
		return
	ghost_parent.visible = false
	if _ghost_pool.size() < GHOST_TRAIL_MAX:
		_ghost_pool.append(ghost_parent)
	else:
		ghost_parent.queue_free()

func _ghost_trail_loop(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and is_instance_valid(self):
		_spawn_ghost_trail()
		await get_tree().create_timer(GHOST_TRAIL_INTERVAL).timeout
		elapsed += GHOST_TRAIL_INTERVAL

#hàm tín hiệu
func _on_spine_anim_finished(anim_name: StringName) -> void:
	if anim_name == "jump_attack(land)":
		if combat.is_jump_attack_landing:
			_cancel_jump_attack_land()
			_update_ground_animation(Input.get_axis("move_left", "move_right"))
	elif anim_name == ANIM_JUMP_START and not is_on_floor():
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
		_update_ground_animation(Input.get_axis("move_left", "move_right"))
	elif anim_name.begins_with(combat.equipped_weapon.animation_prefix + "_attack_"):
		match combat.on_attack_anim_finished():
			CombatComponent.AttackAction.START_COMBO:
				_play_combo_step()
			CombatComponent.AttackAction.FINISH_COMBO:
				can_move = true
				is_doing_action = false
				spine_rig.visible = true
				_update_ground_animation(Input.get_axis("move_left", "move_right"))
				get_tree().create_timer(0.4).timeout.connect(_reset_combo, CONNECT_ONE_SHOT)
		
func _on_dodge_cooldown_timeout() -> void:
	dash.on_cooldown_timeout()

func _on_damage_staggered(knockback_velocity: Vector2) -> void:
	is_doing_action = false
	combat.interrupt()
	can_move = false
	velocity = knockback_velocity
	_playing_land_anim = false
	spine_anim.play("idle", 0.1)

func _on_damage_stagger_recovered() -> void:
	can_move = true

func configure_attack_hitbox(weapon: WeaponData) -> void:
	attack_hitbox.position = weapon.hitbox_offset

	var shape := attack_hitbox_shape.shape as RectangleShape2D
	if shape:
		shape.size = weapon.hitbox_size
func enable_attack_hitbox() -> void:
	combat.enable_attack_hitbox()


func disable_attack_hitbox() -> void:
	combat.disable_attack_hitbox()
