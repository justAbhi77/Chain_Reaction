extends Node2D

var cell_contents:int = 0 :set = setFunc , get = getFunc

func setFunc(newVal:int):
	if newVal == cell_contents:
		return
	cell_contents = newVal
	$Label.text = "{{0}}".format([str(newVal)])

func getFunc():
	return cell_contents
