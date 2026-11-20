class_name NpcLook
extends RefCounted
## Which villager outfit (assets/sprites/npcs.png, tools/gen_npcs.py) a person wears, and the sheet frame to show.
## Sheet: 8 columns (idle, 6 walk, tool pose) x 4 rows per outfit (down, left, up, right), outfits stacked.

const SHEET := "res://assets/sprites/npcs.png"
const OUTFITS := ["farmer", "shopkeeper", "fisher", "mechanic", "police", "citizen_a", "citizen_b", "citizen_c", "vance"]
const CITIZENS := [5, 6, 7, 1, 2, 3]   # outfits pedestrians draw from (not the police uniform, not Odalys' bun)
const POLICE := 4

static func outfit_of(id: String) -> int:
	## Named NPCs wear their own outfit; anyone else gets a stable citizen outfit from the id hash.
	var i := OUTFITS.find(id)
	if i >= 0:
		return i
	return int(CITIZENS[absi(hash(id)) % CITIZENS.size()])

static func frame(outfit: int, facing: int, col: int) -> int:
	return (clampi(outfit, 0, OUTFITS.size() - 1) * 4 + clampi(facing, 0, 3)) * 8 + clampi(col, 0, 7)

static func make_sprite(outfit: int) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = load(SHEET)
	s.hframes = 8
	s.vframes = 4 * OUTFITS.size()
	s.offset = Vector2(0, -22)
	s.frame = frame(outfit, 0, 0)
	return s
