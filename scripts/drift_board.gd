class_name DriftBoard
extends RefCounted
## Circuit drift leaderboard: the best SIZE banked drift scores, highest first. Pure; saved as GameState.drift_board.

const SIZE := 5

static func submit(board: Array, points: int) -> Dictionary:
	## {board, rank}: rank is 1-based, or 0 when the score did not make the board. Zero scores never count.
	var b: Array = board.duplicate()
	if points <= 0:
		return {"board": b, "rank": 0}
	var rank := b.size()
	for i in b.size():
		if points > int(b[i]):
			rank = i
			break
	if rank >= SIZE:
		return {"board": b, "rank": 0}
	b.insert(rank, points)
	while b.size() > SIZE:
		b.pop_back()
	return {"board": b, "rank": rank + 1}

static func lines(board: Array) -> String:
	if board.is_empty():
		return "No drifts banked yet. Slide the circuit with the car."
	var out: Array[String] = ["Drift leaderboard"]
	for i in board.size():
		out.append("%d. %d" % [i + 1, int(board[i])])
	return "  ".join(out)

static func clean(raw: Array) -> Array:
	## Loads a saved board: ints only, sorted high to low, capped.
	var b: Array = []
	for v in raw:
		b.append(int(v))
	b.sort()
	b.reverse()
	return b.slice(0, SIZE)
