extends Actor
class_name Player


onready var platform_detector: RayCast2D = $PlatformDetector
onready var sprite: Sprite = $Sprite
onready var animation_player: AnimationPlayer = $AnimationPlayer
onready var shoot_timer: Timer = $ShootAnimation
onready var gun: Gun = $Sprite/Gun


# Physics process is a built-in loop in Godot.
# If you define _physics_process on a node, Godot will call it every frame.

# # We use separate functions to calculate the direction and velocity to make this one easier to read.
# At a glance, you can see that the physics process loop:
	# 1. Calculates the move direction.
	# 2. Calculates the move velocity.
	# 3. Moves the character.
	# 4. Updates the sprite direction.
	# 5. Shoots bullets.
	# 6. Updates the animation.

# # Splitting the physics process logic into functions not only makes it easier to read, it help to 
# change or improve the code later on:
	# - If you need to change a calculation, you can use Go To -> Function (Ctrl Alt F) to quickly 
	  # jump to the corresponding function.
	# - If you split the character into a state machine or more advanced pattern, you can easily move 
	  # individual functions.
func _physics_process(delta: float) -> void:
	var direction: = get_direction()
	
	var is_jump_interrupted: = Input.is_action_just_released("jump") and _velocity.y < 0.0
	_velocity = calculate_move_velocity(_velocity, direction, speed, is_jump_interrupted)

	var is_snapping: = Vector2.DOWN * 60.0 if direction.y == 0.0 else Vector2.ZERO
	var is_on_platform: = platform_detector.is_colliding()
	_velocity = move_and_slide_with_snap(
		_velocity, is_snapping, FLOOR_NORMAL, not is_on_platform, 4,  0.9, false
	)

	# When the character’s direction changes, we want to to scale the Sprite accordingly to flip it.
	# This will make Robi face left or right depending on the direction you move.
	if direction.x != 0:
		sprite.scale.x = direction.x

	# We use the sprite's scale to store Robi’s look direction which allows us to shoot 
	# bullets forward.
	# There are many situations like these where you can reuse existing properties instead of 
	# creating new variables.
	var is_shooting: = false
	if Input.is_action_just_pressed("shoot"):
		is_shooting = gun.shoot(sprite.scale.x)
	
	var animation: = get_new_animation(is_shooting)
	if animation != animation_player.current_animation and shoot_timer.is_stopped():
		if is_shooting:
			shoot_timer.start()
		animation_player.play(animation)


func get_direction() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		-Input.get_action_strength("jump") if is_on_floor() and Input.is_action_just_pressed("jump") else 0.0
	)


# This function calculates a new velocity whenever you need it.
# It allows you to interrupt jumps.
func calculate_move_velocity(
		linear_velocity: Vector2,
		direction: Vector2,
		speed: Vector2,
		is_jump_interrupted: bool
	) -> Vector2:
	var velocity: = linear_velocity
	velocity.x = speed.x * direction.x
	if direction.y != 0.0:
		velocity.y = speed.y * direction.y
	if is_jump_interrupted:
		velocity.y = 0.0
	return velocity


func get_new_animation(is_shooting: bool = false) -> String:
	var animation_new: = ""
	if is_on_floor():
		animation_new = "run" if abs(_velocity.x) > 0.1 else "idle"
	else:
		animation_new = "falling" if _velocity.y > 0 else "jumping"
	if is_shooting:
		animation_new += "_weapon"
	return animation_new
