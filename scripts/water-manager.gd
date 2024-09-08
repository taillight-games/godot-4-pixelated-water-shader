extends Node
class_name WaterManager

@export var enabled : bool = false

@export_node_path("MeshInstance3D") var water_path : NodePath

var water_obj : MeshInstance3D

@export var water_radius : float = -1;

@export var water_pos : Vector3

var v_noise_1 : Texture2D
var v_noise_2 : Texture2D

var amplitude1 : float
var amplitude2 : float
var height_scale : float

var v_noise_tile : float
var wave_speed : float



var v_n_1_i : Image
var v1_wh : Vector2

var v_n_2_i : Image
var v2_wh : Vector2

var initialized : bool = false

var fix_time : float

var sync_time : float = 0.0

var water_mat : Material

# Called when the node enters the scene tree for the first time.
func _ready():
	# usually wait for 1 frame to allow the noise textures to be processed
	if enabled:
		initialize()


func _process(_delta):
	if enabled:
		sync_time += _delta;
		water_mat.set_shader_parameter("sync_time", sync_time)


func initialize():
	
	water_obj = get_node(water_path)
	
	water_mat = water_obj.get_surface_override_material(0)
	
	v_noise_1 = water_mat.get_shader_parameter("vertex_noise_big")
	v_noise_2 = water_mat.get_shader_parameter("vertex_noise_big2")

	amplitude1 = water_mat.get_shader_parameter("amplitude1")
	amplitude2 = water_mat.get_shader_parameter("amplitude2")
	height_scale = water_mat.get_shader_parameter("height_scale")

	v_noise_tile = water_mat.get_shader_parameter("v_noise_tile")
	wave_speed = water_mat.get_shader_parameter("wave_speed")

	await get_tree().process_frame

	v_n_1_i = v_noise_1.get_image()
	v_n_2_i = v_noise_2.get_image()

	v1_wh = Vector2(v_n_1_i.get_width() - 1, v_n_1_i.get_height() - 1)
	v2_wh = Vector2(v_n_2_i.get_width() - 1, v_n_2_i.get_height() - 1)
	sync_time = 0.0
	initialized = true

# samples the position bilinearly and returns the height value
func calc_water_height(_pos : Vector3) -> float:
	if initialized:
		return (wave(_pos) * height_scale) + water_pos.y
	else:
		return _pos.y

# samples the position without bilinear and returns the height value
func fast_water_height(_pos : Vector3) -> float:
	if initialized:
		return (fast_wave(_pos) * height_scale) + water_pos.y
	else:
		return _pos.y
	

# code duplicated from shader
func g_v(v : Vector2, flipped : bool = false) -> Vector2:
	pass
	
	v.x = fmod(v.x, v_noise_tile)
	v.y = fmod(v.y, v_noise_tile)
	
	var _mapped : Vector2 = Vector2(remap(v.x, 0, v_noise_tile, 0, 1), remap(v.y, 0, v_noise_tile, 0, 1));
	
	fix_time = float(Time.get_ticks_msec()) / 1000.0


	if flipped:
		_mapped.y -= sync_time * wave_speed;
	else:
		_mapped.x += sync_time * wave_speed;

	_mapped.x = fmod(_mapped.x, 1)
	_mapped.y = fmod(_mapped.y, 1)
	
	if sign(_mapped.x) == -1:
		_mapped.x += 1
	if sign(_mapped.y) == -1:
		_mapped.y += 1
	
	return _mapped
	
func wave(y : Vector3) -> float:
	
	var _y2 :Vector2 = Vector2(y.x, y.z)
	
	var _v_uv_1 = g_v(_y2, false)
	var _v_uv_2 = g_v(_y2 + Vector2(0.3, 0.476), false)
	
	var v_x = lerp(0.0, v1_wh.x, _v_uv_1.x)
	var v_y = lerp(0.0, v1_wh.y, _v_uv_1.y)
	
	_v_uv_1 = Vector2(v_x, v_y)
	
	v_x = lerp(0.0, v2_wh.x, _v_uv_2.x)
	v_y = lerp(0.0, v2_wh.y, _v_uv_2.y)
	
	_v_uv_2 = Vector2(v_x, v_y)
	
	var s : float = 0.0;
	
	s += get_4_points(_v_uv_1, v_n_1_i) * amplitude1
	s += get_4_points(_v_uv_2, v_n_2_i) * amplitude2
	
	s -= height_scale/2.;
	
	return s;

func get_4_points(point : Vector2, image : Image) -> float:

	var x0 = int(floor(point.x))
	var x1 = int(ceil(point.x))
	var y0 = int(floor(point.y))
	var y1 = int(ceil(point.y))


	var wx1 = point.x - x0
	var wx0 = 1 - wx1
	var wy1 = point.y - y0
	var wy0 = 1 - wy1

	var result_top = (
		(wx0 * image.get_pixel(x0, y0).r) + 
		(wx1 * image.get_pixel(x1, y0).r)
	)
	
	var result_bottom = (
		(wx0 * image.get_pixel(x0, y1).r) + 
		(wx1 * image.get_pixel(x1, y1).r)
	)
			
	var result = (
		(wy0 * result_top) +
		(wy1 * result_bottom)
	)

	return result

# wave that doesnt do the 4 point sample
func fast_wave(y : Vector3) -> float:
	
	var _y2 :Vector2 = Vector2(y.x, y.z)
	
	var _v_uv_1 = g_v(_y2, false)
	var _v_uv_2 = g_v(_y2 + Vector2(0.3, 0.476), false)
	
	var v_x = lerp(0.0, v1_wh.x, _v_uv_1.x)
	var v_y = lerp(0.0, v1_wh.y, _v_uv_1.y)
	
	_v_uv_1 = Vector2(v_x, v_y)
	
	v_x = lerp(0.0, v2_wh.x, _v_uv_2.x)
	v_y = lerp(0.0, v2_wh.y, _v_uv_2.y)
	
	_v_uv_2 = Vector2(v_x, v_y)
	
	var s : float = 0.0;
	
	var _v_uvi_1 = Vector2i(roundi(_v_uv_1.x), roundi(_v_uv_1.y))
	var _v_uvi_2 = Vector2i(roundi(_v_uv_2.x), roundi(_v_uv_2.y))
	
	
	
	s += v_n_1_i.get_pixelv(_v_uvi_1).r * amplitude1
	s += v_n_2_i.get_pixelv(_v_uvi_2).r * amplitude2
	
	s -= height_scale/2.;
	
	return s;

func check_if_in_water_radius(_pos : Vector3) -> bool:
	if water_radius == -1 or !initialized:
		return true
	else:
		var _w_pos : Vector2 = Vector2(water_obj.global_position.x, water_obj.global_position.z)
		var _n_pos : Vector2 = Vector2(_pos.x, _pos.z)
		var _dist = _n_pos.distance_to(_w_pos)
		if _dist <= water_radius:
			return true
		else:
			return false
	
	
	
	
	
	
	
