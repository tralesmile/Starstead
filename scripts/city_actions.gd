class_name CityActions
extends RefCounted
## Runs a Port Halden counter action (bank, hospital, police desk, shop, cafe, town hall). `m` is Main.

static func prompt(action: String) -> String:
	match action:
		"shop": return "E: Browse the shop"
		"bank": return "E: Deposit cash ($%d in the bank)   Shift+E: withdraw" % GameState.bank_balance
		"heal": return "E: Treatment ($%d)" % CityServices.heal_cost(GameState.energy.value)
		"fine": return "E: Pay off the police (wanted)"
		"coffee": return "E: Buy a coffee ($%d)" % CityServices.COFFEE_PRICE
		"business": return CityActions.business_prompt()
		"notice": return "E: Read the notice board"
		"debt": return "E: Pay the Vance debt ($%d left; Shift+E pays all you can)" % GameState.story.debt_left(GameState.debt_paid) if GameState.story.debt_left(GameState.debt_paid) > 0 else "The Vance ledger is closed: debt cleared"
		"hoops": return "E: Free throws (10 shots)"
		"ring": return "E: Box a bout ($%d entry)" % SportsModel.BOUT_FEE
		"licence": return "E: Circuit licence is owned" if GameState.licence else "E: Buy the circuit licence ($%d)" % CircuitModel.LICENCE_PRICE
		"pitch": return "E: Penalty shootout (5 kicks)"
		"derby": return "E: Animal derby ($%d entry, your best mount runs)" % DerbyModel.FEE
	return ""

static func business_prompt() -> String:
	var b: BusinessModel = GameState.business
	if b.till > 0:
		return "E: Collect the till ($%d)   Shift+E: %s" % [b.till, "upgrade ($%d)" % b.next_cost() if b.level < BusinessModel.MAX_LEVEL else "fully upgraded"]
	if b.level == 0:
		return "E: Buy the cafe franchise ($%d)" % b.next_cost()
	return "E: %s: till empty%s" % [b.name_for_level(), "   Shift+E: upgrade ($%d)" % b.next_cost() if b.level < BusinessModel.MAX_LEVEL else ""]

static func run(m, action: String) -> void:
	match action:
		"business":
			var b: BusinessModel = GameState.business
			if b.till > 0 and not Input.is_key_pressed(KEY_SHIFT):
				var r := b.collect(GameState.money)
				GameState.money = r["cash"]
				GameState.bump("business_collects")
				m._say("Collected $%d from the %s" % [r["got"], b.name_for_level()])
				return
			var r := b.buy(GameState.money, GameState.rep_honest)
			if r["ok"]:
				GameState.money = r["cash"]
				m._say("%s ready! Takings now up to $%d a night" % [b.name_for_level(), BusinessModel.PROFIT[b.level]])
			else:
				match String(r["why"]):
					"rep": m._say("The bank wants honest reputation %d for a franchise loan" % BusinessModel.MIN_HONEST_REP)
					"cash": m._say("That costs $%d" % b.next_cost())
					_: m._say("The cafe is already a grand cafe")
		"shop":
			m.player.velocity = Vector2.ZERO
			m.player.move_v = Vector2.ZERO
			m.player.set_physics_process(false)
			m.shop.open()
		"bank":
			var r := CityServices.withdraw(GameState.money, GameState.bank_balance) if Input.is_key_pressed(KEY_SHIFT) else CityServices.deposit(GameState.money, GameState.bank_balance)
			GameState.money = r["cash"]
			GameState.bank_balance = r["bal"]
			if int(r["moved"]) == 0:
				m._say("Nothing to move. Balance $%d" % GameState.bank_balance)
			else:
				m._say("%s $%d. Balance $%d (+%d%% a day)" % ["Withdrew" if Input.is_key_pressed(KEY_SHIFT) else "Deposited", r["moved"], GameState.bank_balance, CityServices.INTEREST_PCT])
		"heal":
			var r := CityServices.clinic(GameState.money, GameState.energy.value)
			if int(r["paid"]) == 0:
				m._say("You are fine, or too broke for treatment")
			else:
				GameState.money = r["cash"]
				GameState.energy.value = r["energy"]
				m._say("Treated for $%d. Energy %d" % [r["paid"], int(GameState.energy.value)])
		"fine":
			var st: int = m.police.stars()
			var r := CityServices.pay_fine(GameState.money, st, GameState.rep_honest)
			if st == 0:
				m._say("The desk sergeant has nothing on you")
			elif r["cleared"]:
				GameState.money = r["cash"]
				m.police.heat = 0.0
				m._say("Fine of $%d paid. Record cleared" % r["paid"])
			else:
				m._say("The fine is $%d. You cannot cover it" % WantedMath.fine(st))
		"coffee":
			var r := CityServices.coffee(GameState.money, GameState.energy.value)
			if r["ok"]:
				GameState.money = r["cash"]
				GameState.energy.value = r["energy"]
				m._say("Hot coffee. Energy %d" % int(GameState.energy.value))
			else:
				m._say("Not now (full energy or no change)")
		"hoops", "ring", "pitch":
			m.player.velocity = Vector2.ZERO
			m.player.move_v = Vector2.ZERO
			m.player.set_physics_process(false)
			if not m.sports.open({"hoops": "hoops", "ring": "boxing", "pitch": "penalty"}[action]):
				m.player.set_physics_process(true)
		"derby":
			m.player.velocity = Vector2.ZERO
			m.player.move_v = Vector2.ZERO
			m.player.set_physics_process(false)
			if not m.derby.open():
				m.player.set_physics_process(true)
		"licence":
			var r := CircuitModel.licence_ok(GameState.licence, GameState.money)
			if r["ok"]:
				GameState.money = r["cash"]
				GameState.licence = true
				m._say("Circuit licence bought. Circuit races pay x%d" % CircuitModel.PRIZE_MULT)
			else:
				m._say("You already hold the licence" if r["why"] == "owned" else "The licence costs $%d" % CircuitModel.LICENCE_PRICE)
		"debt":
			m.story_view.event("ledger")
			var left := GameState.story.debt_left(GameState.debt_paid)
			if left == 0:
				m._say("Debt cleared. The clerk tips his hat")
			else:
				var r := GameState.story.pay_debt(GameState.money, GameState.debt_paid, Input.is_key_pressed(KEY_SHIFT))
				GameState.money = r["cash"]
				GameState.debt_paid = r["paid"]
				if int(r["moved"]) == 0:
					m._say("No cash for the ledger. $%d still owed" % left)
				else:
					m._say("Paid $%d to Vance. $%d still owed" % [r["moved"], GameState.story.debt_left(GameState.debt_paid)])
					m.story_view.poll(GameState.farm.crops_planted())
		"notice":
			m.story_view.event("notice")
			m._say("Notice board: Vance Aerospace is hiring. Halden Bank pays %d%% a day." % CityServices.INTEREST_PCT)
