extends CharacterBody2D

# --- 配置区域 (可以在检查器中调整) ---
# 移动速度
@export var speed: float = 300.0

# 跳跃高度 (像素)
# 你的角色约 128px 高，2/3 也就是大约 85px。
@export var jump_height: float = 85.0

# 死亡动画的偏移量修正 (方案一)
# 可以在编辑器中调整此值以修正死亡动画的位置偏移
@export var death_offset: Vector2 = Vector2(0, 0)

# --- 内部变量 ---
# 获取项目设置中的重力值
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# 标记角色是否死亡
var is_dead: bool = false

# 获取节点引用
@onready var sprite = $Sprite

func _physics_process(delta):

	# 如果死亡，不再进行移动逻辑，只播放动画
	if is_dead:
		_handle_death_animation()
		# 如果你希望死后受重力影响掉落，保留下面这行 if not is_on_floor(): velocity.y += gravity * delta move_and_slide()
		return

	# 1. 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. 跳跃逻辑
	# 公式: v = sqrt(2 * g * h)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -sqrt(2 * gravity * jump_height)

	# 3. 左右移动 (WASD)
	var direction = Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
		# 翻转 Sprite 方向
		if direction < 0:
			sprite.flip_h = true
		elif direction > 0:
			sprite.flip_h = false
	else:
		# 停止时平滑减速
		velocity.x = move_toward(velocity.x, 0, speed)

	# 4. 应用移动
	move_and_slide()

	# 5. 更新动画状态
	_update_animations()

# 动画状态机
func _update_animations():

	# 每次正常播放动画前，必须重置 offset，否则上一帧的死亡偏移会影响正常走路
	sprite.offset = Vector2.ZERO

	if not is_on_floor():
		sprite.play("jump")
	elif velocity.x != 0:
		sprite.play("run")
	else:
		sprite.play("idle")

# 处理死亡动画 (专门处理偏移)
func _handle_death_animation():
	if sprite.animation != "death":
		sprite.play("death")
		# 【关键】应用偏移量，修复位置不对的问题
		sprite.offset = death_offset

# 提供给外部调用的死亡函数
func die():
	is_dead = true
