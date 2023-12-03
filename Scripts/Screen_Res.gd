extends Node

signal SubcellExplosionCalculated
signal cellExplosionCalculated

var cellSprite = preload("res://Scenes/Cell.tscn")
var WinScreen = preload("res://Scenes/WinScreen.tscn")

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
var WhiteColor: Color = Color(1, 1, 1)
var BlackColor: Color = Color(0, 0, 0)
var isRedTurn: bool = true
var RedTColor: Color = Color(1, 1, 0.5, 0.5)
var BlueTColor: Color = Color(0.5, 1, 1, 0.5)
var CheckMultiClickType:bool= false
var RedHasPlayed:bool = false
var BlueHasPlayed:bool = false
var RoundWon:bool

# Constants
const BOARD_SIZE:int = 4
const MULTI_CLICK_CORNERS:int = 2
const MULTI_CLICK_BORDERS:int = 3
const MULTI_CLICK_ALL:int = 4

var CalculatingExplosion:bool = false
var timerWaitTime

# Called when the node enters the scene tree for the first time.
func _ready():
	timerWaitTime = $Timer.wait_time
	viewport = get_viewport()
	viewport.size_changed.connect(viewport_Changed)
	cellExplosionCalculated.connect(checkWin)
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
				if (i + j) % 2 != 0:
					instance.get_node("Sprite").modulate = BlackColor
					instance.get_node("Label").modulate = WhiteColor
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
	if RoundWon or CalculatingExplosion:
		return
	
	# Mouse in viewport coordinates.
	if (event is InputEventMouseButton and event.is_pressed()) or (event is InputEventScreenTouch and event.is_pressed()):
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
			pooledCells[index].cell_contents = pooledCells[index].cell_contents+1
			print("Multi Click at: ", index_i, " ", index_j," With Cell Content number ",pooledCells[index].cell_contents," for ","Red" if isRedTurn else "Blue"," Team")
			CheckMultiClickType = false
			if (index_i == 0 and index_j == 0) or (index_i == 0 and index_j == BOARD_SIZE-1) or (index_i == BOARD_SIZE-1 and index_j == 0) or (index_i == BOARD_SIZE-1 and index_j == BOARD_SIZE-1):
				if pooledCells[index].cell_contents == MULTI_CLICK_CORNERS:
					CheckMultiClickType = true
			elif index_i == 0 or index_i == BOARD_SIZE-1 or index_j ==0 or index_j == BOARD_SIZE-1:
				if pooledCells[index].cell_contents == MULTI_CLICK_BORDERS:
					CheckMultiClickType = true
			elif pooledCells[index].cell_contents == MULTI_CLICK_ALL:
				CheckMultiClickType = true
				
			if CheckMultiClickType:
				pooledCells[index].cell_contents = 0
				if (index_i+index_j)%2 != 0:
					pooledCells[index].get_node("Sprite").modulate = BlackColor
				else:
					pooledCells[index].get_node("Sprite").modulate = WhiteColor
				calculateExplosion(index_i,index_j,isRedTurn,true)
		else:
			pooledCells[index].cell_contents = pooledCells[index].cell_contents+1
			print("Mouse Click at: ", index_i, " ", index_j," for ","Red" if isRedTurn else "Blue"," Team")
			cellSpriteNode.modulate = currentTColor
		
		if isRedTurn:
			RedHasPlayed = true
		else:
			BlueHasPlayed = true
		
		isRedTurn = !isRedTurn

func calculateExplosion(i,j,Turn,isFirstCall):
	CalculatingExplosion = true
	
	$Timer.wait_time = timerWaitTime
	$Timer.start()
	await $Timer.timeout
	
	var ExplodedNeighbour=[]
	var index = getIndex(i,j)
	
	pooledCells[index].cell_contents = 0
	if (i+j)%2 != 0:
		pooledCells[index].get_node("Sprite").modulate = BlackColor
	else:
		pooledCells[index].get_node("Sprite").modulate = WhiteColor
	
	for fori in range(-1,2):
		for forj in range(-1,2):
			if (fori ==0 and forj ==0) or (abs(fori)+abs(forj)) == 2:
				continue
			
			var neighbouri = i+fori
			var neighbourj = j+forj
			
			if neighbouri<0 or neighbourj<0 or neighbouri>=BOARD_SIZE or neighbourj>= BOARD_SIZE:
				continue
			
			else:
				index = getIndex(neighbouri,neighbourj)
				pooledCells[index].cell_contents = pooledCells[index].cell_contents+1
				pooledCells[index].get_node("Sprite").modulate = RedTColor if Turn else BlueTColor
				CheckMultiClickType = false
			if (neighbouri == 0 and neighbourj == 0) or (neighbouri == 0 and neighbourj == BOARD_SIZE-1) or (neighbouri == BOARD_SIZE-1 and neighbourj == 0) or (neighbouri == BOARD_SIZE-1 and neighbourj == BOARD_SIZE-1):
				if pooledCells[index].cell_contents == MULTI_CLICK_CORNERS:
					CheckMultiClickType = true
			elif neighbouri == 0 or neighbouri == BOARD_SIZE-1 or neighbourj ==0 or neighbourj == BOARD_SIZE-1:
				if pooledCells[index].cell_contents == MULTI_CLICK_BORDERS:
					CheckMultiClickType = true
			elif pooledCells[index].cell_contents == MULTI_CLICK_ALL:
				CheckMultiClickType = true
				
			if CheckMultiClickType:
				ExplodedNeighbour.append([neighbouri,neighbourj])
			
			$Timer.wait_time = timerWaitTime*0.5
			$Timer.start()
			await $Timer.timeout
	
	if len(ExplodedNeighbour) != 0:
		for neighbourIndex in ExplodedNeighbour:
			calculateExplosion(neighbourIndex[0],neighbourIndex[1],Turn,false)
			await SubcellExplosionCalculated
	
	if isFirstCall:
		CalculatingExplosion = false
		cellExplosionCalculated.emit()
	else:
		SubcellExplosionCalculated.emit()

func checkWin():
	if not RedHasPlayed or not BlueHasPlayed:
		return
	
	var redCells:int = 0
	var blueCells:int = 0
	var index
	var cellSpriteNode
	var breakLoop:bool = false
	for i in range(BOARD_SIZE):
		for j in range(BOARD_SIZE):
			index = getIndex(j,i)
			cellSpriteNode = pooledCells[index].get_node("Sprite")
			if cellSpriteNode.modulate == RedTColor:
				redCells += 1
			elif cellSpriteNode.modulate == BlueTColor:
				blueCells += 1
			if redCells >0 and blueCells >0:
				breakLoop = true
				break
		if breakLoop:
			break
	if redCells >0 and blueCells >0:
		RoundWon = false
		return
	RoundWon = true
	var Wininstance = $WinScreen
	Wininstance.visible = true
	if redCells >0:
		print("Red Wins")
		Wininstance.get_node("Panel/Label").text = "Red Wins!"
	else:
		print("Blue Wins")
		Wininstance.get_node("Panel/Label").text = "Blue Wins!"
	
	if not Wininstance.is_inside_tree():
		add_child(Wininstance)
