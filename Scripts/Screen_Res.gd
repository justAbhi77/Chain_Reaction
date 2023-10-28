extends Node

var cellSprite = preload("res://Scenes/Cell.tscn")
var viewport: Viewport
var pooledCells: Array = []
var boardSize: float
var cellSize: float
var boardCenter: Vector2
var cellsStartOffset: Vector2
var BoardStart: Vector2
var scale: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	viewport = get_viewport()
	viewport.size_changed.connect(viewport_Changed)
	setup(viewport.size)

func viewport_Changed(size: Vector2 = Vector2()):
	setup(viewport.size)

func setup(size: Vector2):
	boardSize = min(size.x, size.y)
	cellSize = boardSize / 10
	boardCenter = size / 2
	cellsStartOffset = Vector2(cellSize * 5, cellSize * 5)
	BoardStart = boardCenter - cellsStartOffset
	scale = Vector2(1, 1) * cellSize / 100

	for i in range(10):
		for j in range(10):
			var index = j * 10 + i
			var instance
			if pooledCells.size() < 100:
				instance = cellSprite.instantiate()
				if (i + j) % 2 != 0:
					instance.get_node("Sprite").modulate = Color(0, 0, 0)
				pooledCells.append(instance)
			else:
				instance = pooledCells[index]
			instance.scale = scale
			instance.position = BoardStart + Vector2(cellSize * i, cellSize * j)
			if not instance.is_inside_tree():
				add_child(instance)
