extends Node

# Signals
signal SubcellExplosionCalculated
signal CellExplosionCalculated

# Constants
const BOARD_SIZE: int = 10
const MULTI_CLICK_CORNERS: int = 2
const MULTI_CLICK_BORDERS: int = 3
const MULTI_CLICK_ALL: int = 4

# Variables
var cellSprite = preload("res://Scenes/Cell.tscn")
var viewport: Viewport
var pooledCells: Array = []

# Board properties
var boardSizeMin: float
var boardSizeMax: float
var cellSizeMin: float
var cellSizeMax: float
var boardCenter: Vector2
var cellsStartOffset: Vector2
var cellsOffset: Vector2
var boardStart: Vector2
var scale: Vector2

# Colors
var whiteColor: Color = Color(1, 1, 1)
var blackColor: Color = Color(0, 0, 0)
var redTeamColor: Color = Color(1, 1, 0.5, 0.5)
var blueTeamColor: Color = Color(0.5, 1, 1, 0.5)

# Player state variables
var isRedTurn: bool = true
var redHasPlayed: bool = false
var blueHasPlayed: bool = false
var roundWon: bool

# Explosion variables
var calculatingExplosion: bool = false
var timerWaitTime

# Called when the node enters the scene tree for the first time.
func _ready():
	viewport = get_viewport()
	viewport.size_changed.connect(viewport_changed)
	setup(viewport.size)
	timerWaitTime = $Timer.wait_time
	CellExplosionCalculated.connect(check_win)

# Adjust viewport size
func viewport_changed():
	setup(viewport.size)

# Setup board size and cell properties
func setup(size: Vector2):
	boardSizeMax = max(size.x, size.y) * 0.9
	boardSizeMin = min(size.x, size.y)
	cellSizeMax = boardSizeMax / BOARD_SIZE
	cellSizeMin = boardSizeMin / BOARD_SIZE
	boardCenter = size / 2
	cellsStartOffset = Vector2(cellSizeMin * BOARD_SIZE / 2, cellSizeMax * BOARD_SIZE / 2) if size.x < size.y else Vector2(cellSizeMax * BOARD_SIZE / 2, cellSizeMin * BOARD_SIZE / 2)
	scale = Vector2(cellSizeMin / 100, cellSizeMax / 100) if size.x < size.y else Vector2(cellSizeMax / 100, cellSizeMin / 100)
	boardStart = boardCenter - cellsStartOffset

	# Create or reuse cell instances
	for i in range(BOARD_SIZE):
		for j in range(BOARD_SIZE):
			var instance = get_or_create_cell_instance(i, j)
			instance.scale = scale
			cellsOffset = Vector2(cellSizeMin * i, cellSizeMax * j) if size.x < size.y else Vector2(cellSizeMax * i, cellSizeMin * j)
			instance.position = boardStart + cellsOffset

			if not instance.is_inside_tree():
				add_child(instance)
	
	cellsOffset = Vector2(cellSizeMin, cellSizeMax) if size.x < size.y else Vector2(cellSizeMax, cellSizeMin)

# Get or create a cell instance
func get_or_create_cell_instance(i: int, j: int) -> Node:
	var index: int = i + (j * BOARD_SIZE)
	var instance: Node

	if pooledCells.size() < BOARD_SIZE * BOARD_SIZE:
		instance = cellSprite.instantiate()
		if (i + j) % 2 != 0:
			instance.get_node("Sprite").modulate = blackColor
			instance.get_node("Label").modulate = whiteColor
		pooledCells.append(instance)
	else:
		instance = pooledCells[index]

	return instance

# Handle mouse input
func _input(event):
	if roundWon or calculatingExplosion:
		return

	if event.is_pressed() and event is InputEventMouseButton:
		handle_mouse_input(event)

# Process mouse input
func handle_mouse_input(event: InputEventMouseButton):
	var pos: Vector2i = Vector2i(event.position - boardStart)
	if pos.x < 0 or pos.y < 0:
		return

	var index_i: int = pos.y / int(cellsOffset.y)
	var index_j: int = pos.x / int(cellsOffset.x)

	if index_i >= BOARD_SIZE or index_j >= BOARD_SIZE:
		return

	var index: int = getIndex(index_i, index_j)
	var currentTColor: Color = redTeamColor if isRedTurn else blueTeamColor
	var NcurrentTColor: Color = blueTeamColor if isRedTurn else redTeamColor
	var cellSpriteNode: Node = pooledCells[index].get_node("Sprite")

	if cellSpriteNode.modulate == NcurrentTColor:
		return
	elif cellSpriteNode.modulate == currentTColor:
		handle_multi_click(index_i, index_j, index)
	else:
		handle_single_click(index_i, index_j, index, currentTColor)

	isRedTurn = !isRedTurn

# Handle multi-click logic
func handle_multi_click(index_i: int, index_j: int,index: int):
	pooledCells[index].cell_contents += 1
	print("Multi Click at: ", index_i, " ", index_j, " With Cell Content number ", pooledCells[index].cell_contents, " for ", "Red" if isRedTurn else "Blue", " Team")

	var checkMultiClickType: bool = check_multi_click_type(index_i, index_j, index)

	if checkMultiClickType:
		reset_multi_click_cell(index_i, index_j, index)
		calculate_explosion(index_i, index_j, isRedTurn, true)

# Check the type of multi-click
func check_multi_click_type(index_i: int, index_j: int,index: int) -> bool:
	if (index_i == 0 and index_j == 0) or (index_i == 0 and index_j == BOARD_SIZE - 1) or (index_i == BOARD_SIZE - 1 and index_j == 0) or (index_i == BOARD_SIZE - 1 and index_j == BOARD_SIZE - 1):
		return pooledCells[index].cell_contents == MULTI_CLICK_CORNERS
	elif index_i == 0 or index_i == BOARD_SIZE - 1 or index_j == 0 or index_j == BOARD_SIZE - 1:
		return pooledCells[index].cell_contents == MULTI_CLICK_BORDERS
	elif pooledCells[index].cell_contents == MULTI_CLICK_ALL:
		return true
	return false

# Reset multi-click cell properties
func reset_multi_click_cell(index_i: int, index_j: int,index: int):
	pooledCells[index].cell_contents = 0
	pooledCells[index].get_node("Sprite").modulate = blackColor if (index_i + index_j) % 2 != 0 else whiteColor

# Handle single click logic
func handle_single_click(index_i: int, index_j: int,index: int, currentTColor: Color):
	pooledCells[index].cell_contents += 1
	print("Mouse Click at: ", index_i, " ", index_j, " for ", "Red" if isRedTurn else "Blue", " Team")
	pooledCells[index].get_node("Sprite").modulate = currentTColor

	if isRedTurn:
			redHasPlayed = true
	else:
			blueHasPlayed = true

# Calculate explosion logic
func calculate_explosion(i: int, j: int, turn: bool, isFirstCall: bool):
	calculatingExplosion = true
	$Timer.wait_time = timerWaitTime
	$Timer.start()
	await $Timer.timeout

	var explodedNeighbour: Array = []
	var index: int = getIndex(i, j)

	if pooledCells[index].cell_contents == MULTI_CLICK_ALL:
		reset_multi_click_cell(i, j, index)

	for fori in range(-1, 2):
		for forj in range(-1, 2):
			$Timer.wait_time = timerWaitTime * 0.5
			$Timer.start()
			await $Timer.timeout

			if (fori == 0 and forj == 0) or (abs(fori) + abs(forj)) == 2:
				continue

			var neighbourI: int = i + fori
			var neighbourJ: int = j + forj

			if is_valid_neighbour(neighbourI, neighbourJ):
				var neighbourIndex: int = getIndex(neighbourI, neighbourJ)
				handle_explosion_neighbour(neighbourIndex, turn, explodedNeighbour)

	handle_exploded_neighbours(explodedNeighbour)

	if isFirstCall:
		calculatingExplosion = false
		CellExplosionCalculated.emit()
	else:
		SubcellExplosionCalculated.emit()

# Check if neighbour is within the board
func is_valid_neighbour(neighbourI: int, neighbourJ: int) -> bool:
	return neighbourI >= 0 and neighbourJ >= 0 and neighbourI < BOARD_SIZE and neighbourJ < BOARD_SIZE

# Handle explosion for a single neighbour
func handle_explosion_neighbour(index: int, turn: bool, explodedNeighbour: Array):
	pooledCells[index].cell_contents += 1
	pooledCells[index].get_node("Sprite").modulate = redTeamColor if turn else blueTeamColor

	if pooledCells[index].cell_contents == MULTI_CLICK_ALL:
		explodedNeighbour.append([index % BOARD_SIZE, index / BOARD_SIZE])

# Recursively handle exploded neighbours
func handle_exploded_neighbours(explodedNeighbour: Array):
	if explodedNeighbour.size() != 0:
		for neighbourIndex in explodedNeighbour:
			calculate_explosion(neighbourIndex[0], neighbourIndex[1], isRedTurn, false)
			await SubcellExplosionCalculated

# Check for a winner
func check_win():
	if not redHasPlayed or not blueHasPlayed:
		return

	var redCells: int = 0
	var blueCells: int = 0
	var index: int
	var cellSpriteNode: Node
	var breakLoop: bool = false

	for i in range(BOARD_SIZE):
		for j in range(BOARD_SIZE):
			index = getIndex(i,j)
			cellSpriteNode = pooledCells[index].get_node("Sprite")

			if cellSpriteNode.modulate == redTeamColor:
				redCells += 1
			elif cellSpriteNode.modulate == blueTeamColor:
				blueCells += 1

			if redCells > 0 and blueCells > 0:
				breakLoop = true
				break

		if breakLoop:
			break

	if redCells > 0 and blueCells > 0:
		roundWon = false
	elif redCells > 0:
		print("Red Wins")
		roundWon = true
	else:
		print("Blue Wins")
		roundWon = true

# Helper function to get the index of a cell in the pooledCells array
func getIndex(i: int, j: int) -> int:
	return j + (i * BOARD_SIZE)
