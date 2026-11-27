class_name SwingHit
extends RefCounted
## Pure: a tool's effect waits for the strike frame of its swing instead of firing on the button press.
## One blow at a time; while it is on the way a new press is ignored (the swing is already committed).

var left := -1.0
var _act := Callable()

func busy() -> bool:
	return left >= 0.0

## Land `act` after `delay` seconds (at once when there is no delay). False when a blow is already on the way.
func queue(delay: float, act: Callable) -> bool:
	if busy():
		return false
	if delay <= 0.0:
		act.call()
		return true
	left = delay
	_act = act
	return true

## Returns true on the tick the blow lands.
func tick(delta: float) -> bool:
	if not busy():
		return false
	left -= delta
	if left > 0.0:
		return false
	var act := _act
	cancel()
	act.call()
	return true

func cancel() -> void:
	left = -1.0
	_act = Callable()
