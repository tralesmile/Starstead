class_name CityServices
extends RefCounted
## Pure rules for the Port Halden interiors: bank (deposit / withdraw / daily interest), hospital, police fines, cafe.

const INTEREST_PCT := 2          # per day, on the stored balance
const INTEREST_CAP := 200        # max interest per day (keeps it a safe place, not an exploit)
const HEAL_PER_ENERGY := 0.6     # $ per missing energy point
const COFFEE_PRICE := 8
const COFFEE_ENERGY := 25

static func deposit(cash: int, bal: int, amount: int = -1) -> Dictionary:
	## amount < 0 = everything. Returns {cash, bal, moved}.
	var a := cash if amount < 0 else clampi(amount, 0, cash)
	return {"cash": cash - a, "bal": bal + a, "moved": a}

static func withdraw(cash: int, bal: int, amount: int = -1) -> Dictionary:
	var a := bal if amount < 0 else clampi(amount, 0, bal)
	return {"cash": cash + a, "bal": bal - a, "moved": a}

static func daily_interest(bal: int) -> int:
	return mini(bal * INTEREST_PCT / 100, INTEREST_CAP)

static func heal_cost(energy: float, max_energy: float = 100.0) -> int:
	return int(ceil(maxf(max_energy - energy, 0.0) * HEAL_PER_ENERGY))

static func clinic(cash: int, energy: float, max_energy: float = 100.0) -> Dictionary:
	## Pays what you can: full price heals fully, otherwise heals in proportion. {cash, energy, paid}.
	var cost := heal_cost(energy, max_energy)
	if cost <= 0:
		return {"cash": cash, "energy": energy, "paid": 0}
	var paid := mini(cost, cash)
	var healed := float(paid) / HEAL_PER_ENERGY
	return {"cash": cash - paid, "energy": minf(max_energy, energy + healed), "paid": paid}

static func pay_fine(cash: int, stars: int, honest: int = 0) -> Dictionary:
	## Settling at the desk costs the arrest fine (WantedMath.fine). {cash, paid, cleared}.
	if stars <= 0:
		return {"cash": cash, "paid": 0, "cleared": false}
	var fine := ReputationModel.apply_fine(WantedMath.fine(stars), honest)
	if cash < fine:
		return {"cash": cash, "paid": 0, "cleared": false}
	return {"cash": cash - fine, "paid": fine, "cleared": true}

static func coffee(cash: int, energy: float, max_energy: float = 100.0) -> Dictionary:
	if cash < COFFEE_PRICE or energy >= max_energy:
		return {"cash": cash, "energy": energy, "ok": false}
	return {"cash": cash - COFFEE_PRICE, "energy": minf(max_energy, energy + COFFEE_ENERGY), "ok": true}
