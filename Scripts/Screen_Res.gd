extends Node

var cellSprite = preload("res://Scenes/Cell.tscn")
var viewport: Viewport
var pooledCells: Array = []
var boardSize_min: float
var boardSize_max: float
var cellSize_min: float
var cellSize_max: float
var boardCenter: Vector2
var cellsStartOffset: Vector2
var cellsOffset: Vector2
var BoardStart: Vector2
var scale: Vector2
var BlackColor: Color = Color(0, 0, 0)
var isRedTurn: bool = true
var RedTColor: Color = Color(1, 1, 0.5, 0.5)
var BlueTColor: Color = Color(0.5, 1, 1, 0.5)

# Constants
const BOARD_SIZE = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	viewport = get_viewport()
	viewport.size_changed.connect(viewport_Changed)
	setup(viewport.size)

func viewport_Changed():
	setup(viewport.size)

func setup(size: Vector2):
	boardSize_max = max(size.x, size.y) * 0.9
	boardSize_min = min(size.x, size.y)
	cellSize_max = boardSize_max / BOARD_SIZE
	cellSize_min = boardSize_min / BOARD_SIZE
	boardCenter = size / 2
	cellsStartOffset = Vector2(cellSize_min * BOARD_SIZE / 2, cellSize_max * BOARD_SIZE / 2) if size.x < size.y else Vector2(cellSize_max * BOARD_SIZE / 2, cellSize_min * BOARD_SIZE / 2)
	scale = Vector2(cellSize_min / 100, cellSize_max / 100) if size.x < size.y else Vector2(cellSize_max / 100, cellSize_min / 100)
	BoardStart = boardCenter - cellsStartOffset

	var index 
	var instance

	for i in range(BOARD_SIZE):
		for j in range(BOARD_SIZE):
			
			if pooledCells.size() < BOARD_SIZE * BOARD_SIZE:
				instance = cellSprite.instantiate()
				instance.get_node("Sprite").modulate = BlackColor if (i + j) % 2 != 0 else Color(1, 1, 1, 1)
				pooledCells.append(instance)
			else:
				index = getIndex(j,i)
				instance = pooledCells[index]

			instance.scale = scale
			cellsOffset = Vector2(cellSize_min * i, cellSize_max * j) if size.x < size.y else Vector2(cellSize_max * i, cellSize_min * j)
			instance.position = BoardStart + cellsOffset

			if not instance.is_inside_tree():
				add_child(instance)

	cellsOffset = Vector2(cellSize_min, cellSize_max) if size.x < size.y else Vector2(cellSize_max, cellSize_min)

func getIndex(i: int, j: int) -> int:
	return i + (j * BOARD_SIZE)

func _input(event):
	# Mouse in viewport coordinates.
	if event.is_pressed() and event is InputEventMouseButton:
		var pos = Vector2i(event.position - BoardStart)
		if pos.x < 0 or pos.y < 0:
			return
		var index_i = pos.y / int(cellsOffset.y)
		var index_j = pos.x / int(cellsOffset.x)
		if index_i >= BOARD_SIZE or index_j >= BOARD_SIZE:
			return
		var index = getIndex(index_i, index_j)
		var currentTColor = RedTColor if isRedTurn else BlueTColor
		var NcurrentTColor = BlueTColor if isRedTurn else RedTColor
		var cellSpriteNode = pooledCells[index].get_node("Sprite")

		if cellSpriteNode.modulate == NcurrentTColor:
			return
		elif cellSpriteNode.modulate == currentTColor:
			print("Multi Click at: ", index_i, " ", index_j)
			# TO DO add click for multiple times
		else:
			print("Mouse Click at: ", index_i, " ", index_j)
			cellSpriteNode.modulate = currentTColor

		isRedTurn = !isRedTurn
