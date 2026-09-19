extends CharacterBody3D

# EMITTED WHENEVER HEALTH CHANGES SO HealthHUD CAN MIRROR IT
signal health_changed(health, max_health)
# EMITTED ONCE THE DEATH ANIMATION IS DONE - GameOverUI SHOWS THE SCREEN
signal died()

const MAX_HEALTH = 3
# SECONDS OF INVULNERABILITY AFTER A HIT. WHILE AN ENEMY KEEPS TOUCHING THE
# PLAYER, DAMAGE RE-TICKS ONCE THIS ELAPSES.
const DAMAGE_INTERVAL = 2.0

const JUMP_VELOCITY = 15
const ANIM_IDLERUN = 0
const ANIM_JUMP = 1
const ANIM_DEAD= 2
const KNOCKBACKJUMP = 20
const RUN_BLEND_AMOUNT = 0.2
const IDLE_BLEND_AMOUNT = 0.08
const JUMP_BLEND_AMOUNT = 0.15

var anim = ANIM_IDLERUN
var speed = 12.0
var move_state = 0
var jump_state = 0
var moving = false
var jumping = false
var dead = false
var max_health = MAX_HEALTH
var health = MAX_HEALTH
var damage_cooldown = 0.0
var gravity = 30
var lastPos = Vector3()
var direction = Vector3()

@onready var camera = get_tree().get_nodes_in_group("Camera")[0]
@onready var animation = $Boy/AnimationTree

var state
enum {IDLERUN, JUMP, DEAD, ATTACK}


func _ready():
	# HANDLES MOUSE CURSOR TO BE HIDDEN
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# set_disable_input() lives on the root Viewport, which survives a scene
	# reload - clear it here or the respawned player would be frozen.
	get_tree().get_root().set_disable_input(false)
	health = max_health
	change_state(IDLERUN)


func _physics_process(delta):
	animate()
	knockback()
	damage_tick(delta)

	# HANDLES GRAVITY & PREVENT CHARACTER FROM TILTING WHEN JUMPING
	if not is_on_floor():
		velocity.y -= gravity * delta
		rotation.x = 0
		rotation.z = 0
		jumping = true
	else:
		jumping = false
		
	# HANDLES JUMP
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and !dead:
		velocity.y = JUMP_VELOCITY
	
	# HANDLES INPUT DIRECTION BASE ON THE CAMERA BASIS
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	direction = (camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction and !dead:
		moving = true
		move_state += RUN_BLEND_AMOUNT
		
		# HANDLES THE ROTATION OF THE CHARACTER
		var t = transform
		var speed1 = Vector2(t.origin.x,t.origin.z).distance_to(Vector2(lastPos.x,lastPos.z))
		var rotTransform
		var thisRotation
		
		if (speed1 >= 0.007):
			rotTransform = t.looking_at(lastPos, Vector3.UP)
			thisRotation = Quaternion(t.basis.orthonormalized()).slerp(rotTransform.basis.orthonormalized(), 0.08)
			transform = Transform3D(thisRotation, t.origin)
			lastPos = t.origin
			
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		# PREVENT THE CHARACTER FROM TILTING WHEN ON WALL
		if is_on_wall():
			rotation.x = 0
			rotation.z = 0

		
	else:
		# MAKES THE CHARACTER STOP
		move_state -= IDLE_BLEND_AMOUNT
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		rotation.x = 0
		rotation.z = 0
		moving = false

	move_and_slide()
	check_enemy_contact()


# CONTACT DAMAGE - TICKS EVERY DAMAGE_INTERVAL FOR AS LONG AS AN ENEMY BODY
# KEEPS TOUCHING US. move_and_slide() already resolved the overlaps, so the
# slide collisions are the list of things we are currently pressed against.
func check_enemy_contact():
	if dead or damage_cooldown > 0.0:
		return

	for i in range(get_slide_collision_count()):
		var collider = get_slide_collision(i).get_collider()
		if collider and collider.is_in_group("Enemy") and not collider.dead:
			take_damage(1)
			return


# SINGLE TUNING POINT FOR EVERY DAMAGE SOURCE (BODY CONTACT + ENEMY ATTACK AREA)
func take_damage(amount):
	if dead or damage_cooldown > 0.0:
		return

	health = max(health - amount, 0)
	damage_cooldown = DAMAGE_INTERVAL
	health_changed.emit(health, max_health)

	if health <= 0:
		die()


func die():
	dead = true
	jumping = false
	get_tree().get_root().set_disable_input(true)
	$Boy.visible = true

	# RESET EVERY ENEMY BACK TO IDLE
	for i in get_tree().get_nodes_in_group("Enemy"):
		if i.chasing == true or i.patrolling == true:
			i.patrolling = false
			i.chasing = false
			i.target = null
			i.get_node("Timer").start()

	$DeathTimer.start()


# BLINK WHILE INVULNERABLE SO THE PLAYER CAN SEE THE HIT LANDED
func damage_tick(delta):
	damage_cooldown = max(damage_cooldown - delta, 0.0)

	if dead:
		return

	if damage_cooldown > 0.0:
		$Boy.visible = fmod(damage_cooldown, 0.24) < 0.12
	else:
		$Boy.visible = true


# KNOCKBACK WHEN CHARACTER JUMPS ON ENEMIES
func knockback():
	if ($KnockBack.is_colliding() and $KnockBack.get_collider().is_in_group("Enemy")):
		velocity.y = KNOCKBACKJUMP
		var knockback = $KnockBack.get_collider()
		knockback.dead = true
		knockback.chase_speed = 0
		knockback.patrol_speed = 0
		knockback.get_node("Timer").stop()
		knockback.patrolling = false
		knockback.chasing = false
		knockback.target = null


# HANDLES THE STATE CHANGE
func change_state(new_state):
	state = new_state
	match state:
		IDLERUN:
			anim = ANIM_IDLERUN
		JUMP:
			anim = ANIM_JUMP
		DEAD:
			anim = ANIM_DEAD



# HANDLES THE ANIMATION
func animate():
	

	# ANIMATION FROM IDLE TO RUN & RUN TO IDLE
	if (moving and !jumping) or (!moving and !jumping):
		change_state(IDLERUN)
		
	if dead:
		change_state(DEAD)
		
	# ANIMATION FROM JUMP UP TO LANDING
	if jumping and !is_on_floor():
		change_state(JUMP)
		
		if velocity.y < 0:
			# JUMP UP
			jump_state += JUMP_BLEND_AMOUNT
		else:
			# LANDING
			jump_state -= JUMP_BLEND_AMOUNT
	
	# CLAMP BLEND FOR IDLE > RUN & RUN > IDLE
	move_state = clamp(move_state, 0, 1)
	
	# CLAMP BLEND FOR JUMP UP > LANDING
	jump_state = clamp(jump_state, 0, 1)
	
	# ANIMATIONTREE BLEND
	animation["parameters/Blend2/blend_amount"]=move_state
	animation["parameters/Blend3/blend_amount"]=jump_state
	
	# ANIMATIONTREE TRANSITION
	if animation.get("parameters/state/current_index") != anim:
		animation["parameters/state/transition_request"]= "state " + str(anim)

# DEATH ANIMATION RAN OUT - HAND OFF TO GameOverUI, WHICH PUTS UP THE GAME OVER
# SCREEN AND PAUSES. Playing again reloads main.tscn, which resets health,
# crystals and enemies together.
func _on_death_timer_timeout():
	died.emit()
