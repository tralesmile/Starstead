class_name HarbourActions
extends RefCounted
## Runs E on the harbour contest board, the night crate and the fence barrel. `m` is Main.

static func hour_now() -> float:
	return fposmod(6.0 + GameState.clock.minutes / 60.0, 24.0)

static func crate_visible(m) -> bool:
	return GameState.harbour.can_take_crate(GameState.clock.day, hour_now())

static func run(m, kind: String) -> void:
	var day: int = GameState.clock.day
	var hour := hour_now()
	match kind:
		"board":
			var h: HarbourState = GameState.harbour
			var res := h.finish(day, hour)
			if res["done"]:
				GameState.money += int(res["prize"])
				m._say("Contest over: place %d with %d cm. Prize $%d" % [res["rank"], res["score"], res["prize"]])
				m.toast_t = 4.0
			elif h.entered(day):
				m._say("Your total: %d cm in %d fish (rivals around %d). Ends 18:00" % [h.score, h.catches, int(HarbourModel.rival_scores(day)[0]["score"])])
			elif HarbourModel.is_contest_day(day):
				var r := h.enter(day, hour, GameState.money)
				GameState.money = int(r["money"])
				m._say(String(r["msg"]) if r["ok"] or hour >= HarbourModel.CONTEST_START else "Registration opens at 8:00")
			else:
				m._say("Fishing contest every 7th day. Next: day %d" % (day + (6 - day % 7 + 7) % 7))
		"crate":
			if GameState.harbour.take_crate(day, hour):
				GameState.bag.add("smuggle_crate", 1)
				m.police.add_heat(WantedMath.crime_heat("smuggling"))
				m._say("You take the sealed crate. Deliver it to the buyer in Port Halden")
				m.toast_t = 4.0
			else:
				m._say("Nothing here")
		"fence":
			if not GameState.bag.count("smuggle_crate") > 0:
				m._say("The buyer shrugs. Bring me something sealed, after dark")
			elif HarbourModel.too_hot(m.police.stars()):
				m._say("Too hot. Lose the cops first")
			else:
				GameState.bag.remove("smuggle_crate", 1)
				var pay := HarbourModel.crate_pay(day)
				GameState.money += pay
				GameState.rep_street += 2
				var a: Dictionary = GameState.story.active()
				if not a.is_empty() and str(a["step"]["id"]) == "rocket_seat":
					m._say("No questions asked: $%d. And this fell off a Vance truck: a launch-pad keycard." % pay)
					m.story_view.event("keycard")
				else:
					m._say("No questions asked: $%d" % pay)
