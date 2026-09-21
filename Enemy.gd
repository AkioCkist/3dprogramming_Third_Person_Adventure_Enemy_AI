extends CharacterBody3D

var target
# TRAPS SCALE THESE DOWN THROUGH apply_slow()
const BASE_CHASE_SPEED = 10.0
const BASE_PATROL_SPEED = 1.0
var chase_speed = BASE_CHASE_SPEED
var patrol_speed = BASE_PATROL_SPEED
var slow_factor = 1.0
var slow_time_left = 0.0
var move_state = 0
var patrol_range = 20
var direction = Vector3()
var anim = ANIM_IDLE
var patrolling = false
var chasing = false
var dead = false
# ALERTED - SET WHEN CRYSTAL COLLECTED, BYPASSES VISION CHECK
var alerted = false
# ALERT FORGET TIMER - HOW LONG TO KEEP CHASING AFTER LOSING SIGHT
var alert_forget_time = 0.0
const ALERT_FORGET_DURATION = 5.0  # Seconds to forget after losing sight

@onready var player = get_tree().get_nodes_in_group("Player")[0]
@onready var camera = get_tree().get_nodes_in_group("Camera")[0]
@onready var animation = $EnemyMesh/AnimationTree
@onready var navigationagent = $NavigationAgent3D
@onready var game_mode_manager = get_node("/root/GameModeManager")
@onready var game_manager = get_tree().get_first_node_in_group("CrystalManager")

# VISION - ENEMY ONLY SPOTS THE PLAYER INSIDE THIS CONE AND WITH A CLEAR LINE OF SIGHT
@export var vision_range = 25.0
# FULL CONE ANGLE IN DEGREES (PLAYER MUST BE WITHIN HALF OF IT EITHER SIDE OF FORWARD)
@export var vision_fov = 150.0
@export var vision_collision_mask = 1
@export var vision_requires_line_of_sight = true
@export var eye_height = 1.6
@export var vision_color_idle = Color(0.25, 1.0, 0.35, 0.18)
@export var vision_color_chase = Color(1.0, 0.25, 0.2, 0.28)
# VISION CONE MESH RAISED SLIGHTLY OFF THE GROUND SO IT READS AS A WEDGE
@export var vision_cone_height = 1.0

var vision_cone : MeshInstance3D
var vision_material : StandardMaterial3D


const ANIM_IDLE = 0
const ANIM_PATROL = 1
const ANIM_CHASE = 2
const ANIM_DEAD = 3
const IDLE_BLEND_AMOUNT = 0.01

# STATES
var state
enum {IDLE, PATROL, CHASE, DEAD}

func _ready():
	
	#INITIAL STATE
	change_state(IDLE)
	
	# PATROL TIMER START
	$Timer.start()
	
	# RANDOMIZE PATROL POINTS
	randomize()

	# BUILD THE VISION CONE VISUAL
	build_vision_cone()

func _physics_process(delta):
	
	# RUNS ENEMY ANIMATION
	animate()

	# VISION BASED DETECTION - REPLACES THE OLD PROXIMITY AREA
	update_vision()

	# TRAP SLOW TIMER
	update_slow(delta)

	# HANDLES CHASING
	if target and not dead:
		if chasing:
			chasing_player(delta)
			var next_path_position = navigationagent.get_next_path_position()
			var direction = global_position
			var new_velocity = (next_path_position - direction).normalized() * chase_speed
			navigationagent.set_velocity(new_velocity)
			rotation.x = 0
			rotation.y = lerp_angle(rotation.y, atan2(new_velocity.x,new_velocity.z), delta * 5.0)
			
	# HANDLES PATROLLING
	else:
		if navigationagent.is_target_reachable() and target == null and not state == IDLE:
			var next_path_position = navigationagent.get_next_path_position()
			var direction = global_position
			var new_velocity = (next_path_position - direction).normalized() * patrol_speed
			navigationagent.set_velocity(new_velocity)

			if patrolling:
				target = null
				rotation.x = 0
				rotation.y = lerp_angle(rotation.y, atan2(new_velocity.x,new_velocity.z), delta * 1.5)
				
				
# FUNCTION FOR CHASING
func chasing_player(delta):
	navigationagent.set_target_position(player.global_position)

# FUNCTION FOR PATROLLING
func patrolling_to(target_pos):
	target = null
	navigationagent.set_target_position(target_pos) 

# PATROLLING AREA RANGE
func get_random_pos_in_sphere (radius : float) -> Vector3:
	var x1 = randf_range (-1, 1)
	var x2 = randf_range (-1, 1)

	while x1*x1 + x2*x2 >= 1:
		x1 = randf_range (-1, 1)
		x2 = randf_range (-1, 1)

	var random_pos_on_unit_sphere = Vector3 (
	2 * x1 * sqrt (1 - x1*x1 - x2*x2),
	2 * x2 * sqrt (1 - x1*x1 - x2*x2),
	1 - 2 * (x1*x1 + x2*x2))

	return random_pos_on_unit_sphere * randf_range (0, radius)
	
# HANDLES STATE
func change_state(new_state):
	state = new_state
	match state:
		IDLE:
			anim = ANIM_IDLE
		PATROL:
			anim = ANIM_PATROL
		CHASE:
			anim = ANIM_CHASE
		DEAD:
			anim = ANIM_DEAD

# HANDLES ANIMATION
func animate():
	
	# PATROLLING STATE
	if patrolling:
		change_state(PATROL)
	
	# CHASING STATE
	if chasing:
		change_state(CHASE)
		move_state -= IDLE_BLEND_AMOUNT
	
	# IDLE STATE
	if !chasing and !patrolling:
		change_state(IDLE)
		move_state -= IDLE_BLEND_AMOUNT
		
	# DEAD STATE
	if dead:
		change_state(DEAD)
	
	# CLAMP BLEND FOR IDLE - WALK
	move_state = clamp(move_state, 0, 1)
	
	# ANIMATIONTREE BLEND
	animation["parameters/Blend2/blend_amount"]=move_state
	animation["parameters/Blend3/blend_amount"]=move_state
	
	# ANIMATIONTREE TRANSITION
	if animation.get("parameters/state/current_index") != anim:
		animation["parameters/state/transition_request"]="state " + str(anim)

# START OF PATROLLING
func _on_timer_timeout():
	patrolling = true
	chasing = false
	
	if target == null:
		var random_position = Vector3(get_random_pos_in_sphere(patrol_range).x,0,get_random_pos_in_sphere(patrol_range).z) + get_position()
		patrolling_to(random_position)

# MAKE THE ENEMY MOVE
func _on_navigation_agent_3d_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()

# VISION DETECTION - RUNS EVERY PHYSICS FRAME
func update_vision():
	if vision_cone:
		vision_cone.visible = not dead

	if dead:
		return

	# ALERTED ENEMIES USE FORGET TIMER INSTEAD OF IMMEDIATE VISION CHECK
	if alerted:
		if can_see_player():
			# RESET FORGET TIMER WHEN PLAYER IS IN SIGHT
			alert_forget_time = ALERT_FORGET_DURATION
		else:
			# COUNTDOWN FORGET TIMER WHEN PLAYER NOT IN SIGHT
			if alert_forget_time > 0:
				alert_forget_time -= get_physics_process_delta_time()
			else:
				# FORGET AND RETURN TO PATROL
				alerted = false
				alert_forget_time = 0.0
				on_player_lost()
		
		if vision_material:
			vision_material.albedo_color = vision_color_chase
		return

	if can_see_player():
		if not chasing:
			on_player_spotted()
	else:
		if chasing:
			on_player_lost()

	if vision_material:
		vision_material.albedo_color = vision_color_chase if chasing else vision_color_idle


# TRUE WHEN THE PLAYER IS INSIDE RANGE, INSIDE THE CONE AND NOT HIDDEN BY GEOMETRY
func can_see_player() -> bool:
	if player == null:
		return false

	var offset = player.global_position - global_position
	offset.y = 0.0

	var distance = offset.length()
	if distance > vision_range:
		return false

	if distance > 0.001:
		# THE ENEMY MODEL FACES +Z, AND rotation.y IS SET FROM atan2(x, z) TO MATCH
		var forward = global_transform.basis.z
		forward.y = 0.0
		var angle = rad_to_deg(forward.normalized().angle_to(offset.normalized()))
		if angle > vision_fov * 0.5:
			return false

	return has_line_of_sight()


# RAY FROM THE ENEMY EYES TO THE PLAYER CHEST - ANYTHING ELSE BLOCKS THE VIEW
func has_line_of_sight() -> bool:
	if not vision_requires_line_of_sight:
		return true

	var space_state = get_world_3d().direct_space_state
	var from = global_position + Vector3.UP * eye_height
	var to = player.global_position + Vector3.UP * 1.0

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	query.collision_mask = vision_collision_mask

	var hit = space_state.intersect_ray(query)

	# EMPTY MEANS NOTHING IN THE WAY
	if hit.is_empty():
		return true

	return hit.collider == player or (hit.collider and hit.collider.is_in_group("Player"))


# BUILT IN CODE SO EVERY ENEMY INSTANCE GETS IT WITHOUT SCENE WIRING
func build_vision_cone():
	vision_material = StandardMaterial3D.new()
	vision_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vision_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vision_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	vision_material.albedo_color = vision_color_idle

	vision_cone = MeshInstance3D.new()
	vision_cone.name = "VisionCone"
	vision_cone.material_override = vision_material
	add_child(vision_cone)

	update_vision_cone_mesh()


# UNIT CONE: APEX AT THE ENEMY, BASE AT vision_range FORWARD ALONG +Z
func update_vision_cone_mesh():
	if vision_cone == null:
		return

	var cone = CylinderMesh.new()
	cone.height = vision_range
	cone.top_radius = 0.0
	cone.bottom_radius = tan(deg_to_rad(vision_fov * 0.5)) * vision_range
	cone.radial_segments = 24
	cone.rings = 1
	cone.cap_top = false
	cone.cap_bottom = true
	vision_cone.mesh = cone

	# CYLINDER RUNS ALONG Y - LAY IT DOWN SO THE TIP SITS ON THE ENEMY
	vision_cone.rotation = Vector3(deg_to_rad(-90), 0, 0)
	vision_cone.position = Vector3(0, vision_cone_height, vision_range * 0.5)


# TRAP / DEBUFF ENTRY POINT - SAME RULES AS THE PLAYER
func apply_slow(factor, duration):
	if dead:
		return

	slow_factor = min(slow_factor, factor)
	slow_time_left = max(slow_time_left, duration)
	chase_speed = BASE_CHASE_SPEED * slow_factor
	patrol_speed = BASE_PATROL_SPEED * slow_factor


func update_slow(delta):
	if slow_time_left <= 0.0:
		return

	slow_time_left = max(slow_time_left - delta, 0.0)

	if slow_time_left <= 0.0:
		# A STOMPED ENEMY STAYS FROZEN - knockback() ZEROED ITS SPEEDS
		if dead:
			return
		slow_factor = 1.0
		chase_speed = BASE_CHASE_SPEED
		patrol_speed = BASE_PATROL_SPEED


func on_player_spotted():
	target = player
	patrolling = false
	chasing = true
	$Timer.stop()
	Sound.play("enemy_spotted")
	
	# Register alert in GameModeManager for Hardcore Mode
	if game_mode_manager:
		game_mode_manager.register_enemy_alert()
		
	# Re-fetch game_manager because it might not have been ready when this enemy spawned
	if not game_manager:
		game_manager = get_tree().get_first_node_in_group("CrystalManager")
		
	# Fail game if Hardcore Mode
	if game_manager and game_mode_manager and game_mode_manager.is_hardcore():
		game_manager._fail_game("Enemy Spotted!", "In Hardcore Mode, you cannot be spotted by enemies. The game is over.")


func on_player_lost():
	target = null
	chasing = false
	patrolling = false
	$Timer.start()


# CALLED BY GameManager WHEN PLAYER COLLECTS A CRYSTAL - ALERTS THIS ENEMY TO CHASE
func alert_to_chase(player_node):
	if dead or chasing:
		return
	
	target = player_node
	patrolling = false
	chasing = true
	alerted = true
	alert_forget_time = ALERT_FORGET_DURATION
	$Timer.stop()
	Sound.play("enemy_spotted")
