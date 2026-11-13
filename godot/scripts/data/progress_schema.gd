extends RefCounted
## Ogni enigma dichiara qui valori iniziali e tipi accettati nei salvataggi.
## Le chiavi stabili appartengono a un ambito, evitando una lista di variabili globali per tutto EP01.
const SCOPES := {
	"cabin": {
		"sink_stage": {"default": 0, "min": 0, "max": 2},
		"door_unlocked": {"default": false}
	}
}

## Crea dizionari indipendenti per ogni partita, senza modificare lo schema condiviso.
static func defaults() -> Dictionary:
	var result := {}
	for scope in SCOPES:
		result[scope] = {}
		for key in SCOPES[scope]:
			result[scope][key] = SCOPES[scope][key].default
	return result

## JSON rappresenta i numeri come float: accettiamo interi matematici nel relativo intervallo.
static func accepts(scope: String, key: String, value: Variant) -> bool:
	if not SCOPES.has(scope) or not SCOPES[scope].has(key):
		return false
	var rule: Dictionary = SCOPES[scope][key]
	if rule.default is bool:
		return value is bool
	return (value is int or value is float) and is_finite(float(value)) \
		and value == floor(value) and value >= rule.min and value <= rule.max

## Valida anche chiavi sconosciute; gli ambiti assenti ricevono invece i valori iniziali.
## Questo consente di aggiungere enigmi senza invalidare i salvataggi della stessa versione.
static func normalize(data: Variant) -> Dictionary:
	if not data is Dictionary:
		return {}
	var result := defaults()
	for scope in data:
		if not scope is String or not SCOPES.has(scope) or not data[scope] is Dictionary:
			return {}
		for key in data[scope]:
			if not key is String or not accepts(scope, key, data[scope][key]):
				return {}
			result[scope][key] = data[scope][key] if data[scope][key] is bool else int(data[scope][key])
	return result
