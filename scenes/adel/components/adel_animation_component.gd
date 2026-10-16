class_name AdelAnimationComponent
extends RefCounted
## Owns presentation and a private ready variant; source rig resources stay intact.

var _body: CharacterBody2D
var playing_land := false
var skidding := false
var _rig: Node2D
var _player: AnimationPlayer
var _library: AnimationLibrary
var _ready_original: Animation
var _ready_final: Animation

func _init(body: CharacterBody2D, rig: Node2D, player: AnimationPlayer) -> void:
	_body = body
	_rig = rig
	_player = player
	_library = player.get_animation_library(&"").duplicate() as AnimationLibrary
	player.remove_animation_library(&"")
	player.add_animation_library(&"", _library)
	_ready_original = _library.get_animation(&"saber_ready")
	_ready_final = _ready_original.duplicate() as Animation
	_ready_final.length = 1.0
	_ready_final.loop_mode = Animation.LOOP_NONE
	for track in _ready_final.get_track_count():
		if String(_ready_final.track_get_path(track)) == "TestAttackSprite:frame":
			_ready_final.remove_track(track)
			break
	# Apply texture/hframes before frame=2, including recovery from 1-frame poses.
	var frame_track := _ready_final.add_track(Animation.TYPE_VALUE)
	_ready_final.track_set_path(frame_track, NodePath("TestAttackSprite:frame"))
	_ready_final.value_track_set_update_mode(frame_track, Animation.UPDATE_DISCRETE)
	_ready_final.track_insert_key(frame_track, 0.0, 2)

func sprite_frame_time(clip: StringName, frame_index: int) -> float:
	if not _player.has_animation(clip): return -1.0
	var animation := _player.get_animation(clip)
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_VALUE or not animation.track_is_enabled(track): continue
		if String(animation.track_get_path(track)) != "TestAttackSprite:frame": continue
		for key in animation.track_get_key_count(track):
			if int(animation.track_get_key_value(track, key)) == frame_index:
				return animation.track_get_key_time(track, key)
	return -1.0

func play(clip: StringName, blend: float = -1.0) -> void:
	_rig.visible = true
	_player.play(clip, blend)

func ready_pose(final_frame_only: bool = false) -> void:
	_library.remove_animation(&"saber_ready")
	_library.add_animation(&"saber_ready", _ready_final if final_frame_only else _ready_original)
	play(&"saber_ready")
	_player.advance(0.0)

func hold(clip: StringName) -> void:
	play(clip)
	_player.advance(0.0)
	_player.pause()

func stagger(frame_index: int) -> void:
	if not _player.has_animation(&"saber_stagger"):
		return
	hold(&"saber_stagger")
	var pose := _rig.get_node_or_null("TestAttackSprite") as Sprite2D
	if pose != null:
		pose.frame = clampi(frame_index, 0, pose.hframes * pose.vframes - 1)


func face(direction: int) -> void:
	_body.facing_direction = direction
	var spine_scale := absf(_body.spine_pivot.scale.x)
	var weapon_scale := absf(_body.weapon_pivot.scale.x)
	_body.spine_pivot.scale.x = -spine_scale if direction < 0 else spine_scale
	_body.weapon_pivot.scale.x = -weapon_scale if direction < 0 else weapon_scale


func jump_start() -> void:
	if _body.combat.is_jump_attack_landing:
		_body._cancel_jump_attack_land()
	playing_land = false
	_rig.visible = true
	_player.play(_body.ANIM_JUMP_START, 0.05)


func jump_land() -> void:
	playing_land = true
	_rig.visible = true
	_player.play(_body.ANIM_JUMP_LAND, 0.1)


func ground(direction: float) -> void:
	if _body.combat.is_jump_attack_landing:
		if direction == 0.0:
			return
		_body._cancel_jump_attack_land()
	if _body.state_machine.current == AdelStateMachine.State.READY and direction == 0.0:
		return
	if not _body.is_on_floor() or playing_land:
		return
	_rig.visible = true

	var current_speed := absf(_body.velocity.x)

	if direction != 0.0:
		if skidding:
			skidding = false
			_player.play("skid")
			_player.seek(_player.current_animation_length, true)

		if _body.locomotion.is_running and current_speed > _body.locomotion.WALK_SPEED:
			if _player.current_animation != "run":
				_player.play("run")
		else:
			if _player.current_animation != "walk":
				_player.play("walk")
				
	else:
		if playing_land:
			return

		if current_speed > _body.locomotion.WALK_SPEED * 0.8:
			if not skidding:
				skidding = true
				_player.play("skid")
		elif current_speed < 10.0 and not skidding:
			if _player.current_animation != "idle":
				_player.play("idle")


func air() -> void:
	if _body.is_on_floor() or playing_land or _body.dash.is_dodging:
		return
	var current_anim: StringName = _player.current_animation
	if current_anim == _body.ANIM_JUMP_START or current_anim == _body.ANIM_JUMP_AIR:
		return
	_rig.visible = true
	_player.play(_body.ANIM_JUMP_AIR)
