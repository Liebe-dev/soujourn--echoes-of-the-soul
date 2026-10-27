extends SceneTree
## A modification stack stores its owning Skeleton2D. Sharing it between scene
## instances makes editor gizmos draw on a different node's draw notification.

var checks := 0
var failures := 0

func _initialize() -> void:
	await process_frame
	if not OS.get_user_data_dir().contains("CodexSaberVFX"):
		push_error("Run skeleton instance validation in an isolated CodexSaberVFX user directory.")
		quit(2)
		return
	for path: String in ["res://asset/Character/Adel/adel spine action use.tscn", "res://scenes/enemy/enemy_spine.tscn"]:
		var packed := load(path) as PackedScene
		var first := packed.instantiate()
		var second := packed.instantiate()
		root.add_child(first)
		root.add_child(second)
		var first_skeleton := first.get_node("Skeleton2D") as Skeleton2D
		var second_skeleton := second.get_node("Skeleton2D") as Skeleton2D
		var first_stack := first_skeleton.get_modification_stack()
		var second_stack := second_skeleton.get_modification_stack()
		check(first_stack != null and second_stack != null, path + " retains its authored stack")
		if first_stack != null and second_stack != null:
			check(first_stack != second_stack, path + " instances have independent stacks")
			check(first_stack.get_skeleton() == first_skeleton, path + " first stack draws on its own skeleton")
			check(second_stack.get_skeleton() == second_skeleton, path + " second stack draws on its own skeleton")
			check(first_stack.enabled == second_stack.enabled, path + " preserves enabled state")
			check(first_stack.get_modification_count() == second_stack.get_modification_count(), path + " preserves modifier count")
			for index in first_stack.get_modification_count():
				var first_modifier := first_stack.get_modification(index)
				var second_modifier := second_stack.get_modification(index)
				check(first_modifier != second_modifier, path + " IK modifier %d is independent" % index)
		first.queue_free()
		second.queue_free()
		await process_frame
		await process_frame
	print("SKELETON INSTANCE RESULTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("SKELETON INSTANCE ", "PASS " if ok else "FAIL ", message)
