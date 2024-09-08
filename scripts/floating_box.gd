extends RigidBody3D

@export var buoyancy_power : float = 0

@onready var water_manager : WaterManager = %WaterManager

# an incredibly simple showcase of the buoyancy
func _physics_process(delta: float) -> void:
	var _water_height = water_manager.calc_water_height(global_position)
	
	if global_position.y > _water_height:
		gravity_scale = 1;
	else:
		gravity_scale = -buoyancy_power * (_water_height - global_position.y);
	
