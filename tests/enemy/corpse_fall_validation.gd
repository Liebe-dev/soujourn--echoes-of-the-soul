extends Node
class FallReference extends CharacterBody2D:
	var locomotion: LocomotionComponent
	func _ready() -> void:
		locomotion = LocomotionComponent.new(self)
	func _physics_process(delta: float) -> void:
		locomotion.apply_vertical_physics(delta)
		move_and_slide()

var checks := 0
var failures := 0
var enemy
var scene: Node2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("CORPSE FALL ", "PASS " if ok else "FAIL ", label)

func frames(count: int = 1) -> void:
	for i in count:
		await get_tree().physics_frame
		await get_tree().process_frame

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func spawn(pos: Vector2):
	var instance = load("res://scenes/enemy/spine_enemy.tscn").instantiate()
	instance.position = pos
	scene.add_child(instance)
	return instance

func run() -> void:
	if not OS.get_user_data_dir().contains("CodexCorpseFall20261016"):
		get_tree().quit(2)
		return
	Engine.max_fps = 144
	scene = Node2D.new()
	scene.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(500, 640)
	var floor_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(2000, 80)
	floor_shape.shape = rectangle
	floor_body.add_child(floor_shape)
	scene.add_child(floor_body)
	enemy = spawn(Vector2(400, 549))
	await frames(5)
	var target := Node2D.new()
	target.position = enemy.position + Vector2(160, 0)
	scene.add_child(target)
	enemy.target = target
	enemy._launch()
	await frames(5)
	check(enemy.state == enemy.State.LEAP and not enemy.is_on_floor() and enemy.velocity.y < 0, "fixture uses actual airborne opening leap")
	var x: float = enemy.position.x
	var initial_y: float = enemy.position.y
	enemy.take_damage(10000)
	check(enemy.is_dead and enemy.animation_player.assigned_animation == &"death", "lethal aerial hit starts authored death immediately")
	await frames(8)
	check(enemy.position.y > initial_y + 3.0, "airborne corpse falls instead of freezing at lethal-hit position")
	check(is_zero_approx(enemy.position.x - x), "death cancels horizontal lunge and upward momentum")
	check(enemy.animation_player.is_playing() and enemy.animation_player.current_animation_position > 0.0, "death animation keeps advancing during fall")
	check(enemy.get_node("CollisionShape2D").disabled and enemy.hitbox_shape.disabled and enemy.leap_hitbox_shape.disabled, "original hurtbox and offensive shapes remain disabled")
	check(enemy.collision_layer == 0 and not enemy.hitbox.monitoring and not enemy.leap_hitbox.monitoring, "corpse is invisible to combat collision layers and attack monitoring")
	# Use the real Player vertical-physics module, with matching shape and initial velocity.
	var reference := FallReference.new()
	reference.collision_layer = 0
	reference.collision_mask = 1
	reference.position = enemy.position
	reference.velocity = enemy.velocity
	var reference_shape := CollisionShape2D.new()
	reference_shape.shape = enemy.get_node("CollisionShape2D").shape.duplicate()
	reference_shape.transform = enemy.get_node("CollisionShape2D").transform
	reference.add_child(reference_shape)
	scene.add_child(reference)
	await frames(5)
	check(absf(enemy.velocity.y - reference.velocity.y) < 0.1 and absf(enemy.position.y - reference.position.y) < 0.2, "corpse acceleration and movement match Player fall physics")
	await frames(40)
	check(enemy.is_on_floor() and absf(enemy.position.y - 549.0) < 0.2, "corpse lands on terrain at the body's original floor contact")
	var landed_y: float = enemy.position.y
	await frames(8)
	check(absf(enemy.position.y - landed_y) < 0.1 and enemy.velocity == Vector2.ZERO, "corpse remains settled without sinking or sliding")
	check(enemy.state == enemy.State.DEAD and enemy.animation_player.assigned_animation == &"death" and enemy.animation_player.current_animation_position > 0.5, "landing never replaces or restarts the death clip")
	check(not enemy.take_damage(20) and enemy.get_lock_on_point() == Vector2.INF, "settled corpse stays immune to hits and excluded from lock-on")
	reference.queue_free()
	# High fall tests the Player terminal velocity and world obstacles.
	var high = spawn(Vector2(1000, -2500))
	high.take_damage(10000)
	await frames(60)
	check(high.velocity.y <= LocomotionComponent.MAX_FALL_SPEED + 0.1 and high.velocity.y > 800.0, "corpse fall is capped at Player terminal speed")
	get_tree().paused = true
	var paused_y: float = high.position.y
	var paused_anim: float = high.animation_player.current_animation_position
	await wait(0.12)
	check(high.position.y == paused_y and high.animation_player.current_animation_position == paused_anim, "pause freezes both fall and death animation")
	get_tree().paused = false
	await frames(2)
	check(high.position.y > paused_y and high.animation_player.current_animation_position > paused_anim, "resume continues fall and death together")
	var prior_y: float = high.position.y
	CombatTime.request(self, &"corpse_fall_test", 0.5, 0.4)
	await wait(0.2)
	var distance: float = high.position.y - prior_y
	check(distance > 50 and distance < 140, "global slow motion also slows corpse fall")
	CombatTime.remove(self)
	# Death still ends on the authored animation signal, including while airborne.
	high.animation_player.advance(10.0)
	await frames(2)
	check(not is_instance_valid(high), "death clip completion still removes an airborne corpse")
	var grounded = spawn(Vector2(700, 549))
	await frames(4)
	grounded.take_damage(10000)
	await frames(5)
	check(grounded.is_on_floor() and absf(grounded.position.y - 549) < 0.2 and grounded.animation_player.assigned_animation == &"death", "grounded death stays on floor without a visible drop")
	# Player/legacy bodies sharing world layer must not be platforms for corpses.
	var blocker := CharacterBody2D.new()
	blocker.add_to_group("Player")
	blocker.collision_layer = 3
	blocker.position = Vector2(200, 400)
	var blocker_shape := CollisionShape2D.new()
	var blocker_rectangle := RectangleShape2D.new()
	blocker_rectangle.size = Vector2(200, 30)
	blocker_shape.shape = blocker_rectangle
	blocker.add_child(blocker_shape)
	scene.add_child(blocker)
	var pass_through = spawn(Vector2(200, 150))
	pass_through.take_damage(10000)
	await frames(65)
	check(pass_through.is_on_floor() and absf(pass_through.position.y - 549) < 0.2, "corpse passes through character bodies and lands on terrain")
	print("CORPSE FALL RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
