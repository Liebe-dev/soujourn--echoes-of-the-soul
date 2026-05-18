extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var Shadow: Sprite2D = $Shadow

const SPEED := 72.0
const JUMP_VELOCITY := 0.0
const SLIDE_SPEED := 300.0
const STAGGER_STUN_SEC := 0.45
const STAGGER_INVULN_SEC := 1.0
const STAGGER_KNOCKBACK := 300.0
const HIT_INVULN_SEC := 0.2
const DEBUG_DAMAGE_AMOUNT := 10

var is_sliding := false
var can_move: bool = true
var is_locked: bool = false
var is_stunned: bool = false
var is_invulnerable: bool = false

func _physics_process(delta: float) -> void:
	if is_stunned:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	if is_locked or can_move == false:
		velocity.x = 0
		move_and_slide()
		return

	Shadow.modulate.a = 1.0
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_floor():
		var floor_angle := get_floor_angle()
		if floor_angle > deg_to_rad(20.0):
			is_sliding = true
		else:
			is_sliding = false
	else:
		is_sliding = false

	var move_speed := SPEED * _get_move_speed_multiplier()

	if is_sliding:
		var slope_normal := get_floor_normal()
		velocity.x = slope_normal.x * 2 * SLIDE_SPEED
		anim.play("Slide")
		Shadow.modulate.a = 0
		anim.flip_h = velocity.x < 0
	else:
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		var direction := Input.get_axis("move_left", "move_right")
		if direction:
			if is_on_floor():
				anim.play("walk")
			velocity.x = direction * move_speed
			anim.flip_h = direction < 0
		else:
			if is_on_floor():
				if abs(velocity.x) > 100:
					anim.play("Slide")
				else:
					anim.play("idle")
			velocity.x = move_toward(velocity.x, 0, move_speed)
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_take_damage"):
		take_damage(DEBUG_DAMAGE_AMOUNT, global_position + Vector2(80.0, 0.0))
		get_viewport().set_input_as_handled()

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
			return dir.normalized()
	return Vector2(-1.0 if anim.flip_h else 1.0, -0.2).normalized()

func _apply_stagger(knockback_dir: Vector2) -> void:
	is_stunned = true
	is_invulnerable = true
	can_move = false
	velocity = knockback_dir * STAGGER_KNOCKBACK
	if anim.sprite_frames and anim.sprite_frames.has_animation("idle"):
		anim.play("idle")
	get_tree().create_timer(STAGGER_STUN_SEC).timeout.connect(_on_stagger_stun_end, CONNECT_ONE_SHOT)

func _on_stagger_stun_end() -> void:
	is_stunned = false
	can_move = true
	var remaining := maxf(STAGGER_INVULN_SEC - STAGGER_STUN_SEC, 0.0)
	if remaining > 0.0:
		get_tree().create_timer(remaining).timeout.connect(_end_invulnerability, CONNECT_ONE_SHOT)
	else:
		_end_invulnerability()

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
