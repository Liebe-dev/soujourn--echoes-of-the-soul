class_name WeaponData
extends Node2D

@export_category("Identity")
@export var weapon_id: String = "saber"
@export var display_name: String = "Saber"

@export_category("Combat")
@export var damage: int = 1
@export var stamina_cost: int = 0
@export var combo_length: int = 4

@export_category("Animation")
@export var animation_prefix: String = "saber"
@export_category("Hitbox")
@export var hitbox_offset: Vector2 = Vector2.ZERO
@export var hitbox_size: Vector2 = Vector2.ZERO
@export_category("Attack Timing")
@export var attack_active_start: Array[float] = [0.10, 0.10, 0.10, 0.15]
@export var attack_active_end: Array[float] = [0.20, 0.20, 0.20, 0.30]
