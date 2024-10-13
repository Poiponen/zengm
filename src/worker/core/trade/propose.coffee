# TypeScript to CoffeeScript conversion
import { PHASE } from "../../../common"
import { team } from ".."
import { g } from "../../util"
import clear from "./clear"
import processTrade from "./processTrade"
import summary from "./summary"
import get from "./get"
import { idb } from "../../db"

/**
 * Proposes the current trade in the database.
 *
 * Before proposing the trade, the trade is validated to ensure that all player IDs match up with team IDs.
 *
 * @memberOf core.trade
 * @param {boolean} forceTrade When true (like in God Mode), this trade is accepted regardless of the AI
 * @return {Promise.<boolean, string>} Resolves to an array. The first argument is a boolean for whether the trade was accepted or not. The second argument is a string containing a message to be displayed to the user.
 */
propose = (forceTrade = false) ->
	if g.get("phase") >= PHASE.AFTER_TRADE_DEADLINE and g.get("phase") <= PHASE.PLAYOFFS
		return [false, "Error! You're not allowed to make trades " + (if g.get("phase") is PHASE.AFTER_TRADE_DEADLINE then "after the trade deadline" else "now") + "."]

	{ teams } = await get()
	tids = [teams[0].tid, teams[1].tid]
	pids = [teams[0].pids, teams[1].pids]
	dpids = [teams[0].dpids, teams[1].dpids]

	# The summary will return a warning if there is a problem. In that case,
	# that warning will already be pushed to the user so there is no need to
	# return a redundant message here.
	s = await summary(teams)

	if s.warning and not forceTrade
		return [false, null]

	outcome = "rejected" # Default

	dv = await team.valueChange(teams[1].tid, teams[0].pids, teams[1].pids, teams[0].dpids, teams[1].dpids, undefined, g.get("userTid"))

	if dv > 0 or forceTrade
		# Trade players
		outcome = "accepted"
		await processTrade(tids, pids, dpids)

	if outcome is "accepted"
		await clear() # Auto-sort team rosters

		for tid in tids
			t = await idb.cache.teams.get(tid)
			onlyNewPlayers = g.get("userTids").includes(tid) and t and not t.keepRosterSorted

			await team.rosterAutoSort(tid, onlyNewPlayers)

		return [true, 'Trade accepted! "Nice doing business with you!"']

	# Return a different rejection message based on how close we are to a deal. When dv < 0, the closer to 0, the better the trade for the AI.
	message = if dv > -2 then "Close, but not quite good enough."
	else if dv > -5 then "That's not a good deal for me."
	else "What, are you crazy?!"

	return [false, "Trade rejected! \"" + message + "\""]

export default propose
