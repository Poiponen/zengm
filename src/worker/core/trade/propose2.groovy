import static common.PHASE
import team
import util.g
import clear
import processTrade
import summary
import get
import db.idb

/**
 * Proposes the current trade in the database.
 *
 * Before proposing the trade, the trade is validated to ensure that all player IDs match up with team IDs.
 *
 * @memberOf core.trade
 * @param {boolean} forceTrade When true (like in God Mode), this trade is accepted regardless of the AI
 * @return {Promise.<boolean, string>} Resolves to an array. The first argument is a boolean for whether the trade was accepted or not. The second argument is a string containing a message to be displayed to the user.
 */
def propose(boolean forceTrade = false) {
    if (g.get("phase") >= PHASE.AFTER_TRADE_DEADLINE && g.get("phase") <= PHASE.PLAYOFFS) {
        return [false, "Error! You're not allowed to make trades " + (g.get("phase") == PHASE.AFTER_TRADE_DEADLINE ? "after the trade deadline" : "now") + "."]
    }

    def result = get().await()
    def teams = result.teams
    def teamIds = [teams[0].tid, teams[1].tid]
    def playerIds = [teams[0].pids, teams[1].pids]
    def disabledPlayerIds = [teams[0].dpids, teams[1].dpids]

    // The summary will return a warning if there is a problem. In that case,
    // that warning will already be pushed to the user so there is no need to
    // return a redundant message here.
    def summaryResult = summary(teams).await()

    if (summaryResult.warning && !forceTrade) {
        return [false, null]
    }

    def tradeOutcome = "rejected" // Default

    def deltaValue = team.valueChange(
        teams[1].tid,
        teams[0].pids,
        teams[1].pids,
        teams[0].dpids,
        teams[1].dpids,
        null,
        g.get("userTid")
    ).await()

    if (deltaValue > 0 || forceTrade) {
        // Trade players
        tradeOutcome = "accepted"
        processTrade(teamIds, playerIds, disabledPlayerIds).await()
    }

    if (tradeOutcome == "accepted") {
        clear().await() // Auto-sort team rosters

        for (def teamId : teamIds) {
            def teamInfo = idb.cache.teams.get(teamId).await()
            def onlyNewPlayers = g.get("userTids").contains(teamId) && teamInfo && !teamInfo.keepRosterSorted

            team.rosterAutoSort(teamId, onlyNewPlayers).await()
        }

        return [true, 'Trade accepted! "Nice doing business with you!"']
    }

    // Return a different rejection message based on how close we are to a deal. When deltaValue < 0, the closer to 0, the better the trade for the AI.
    def rejectionMessage

    if (deltaValue > -2) {
        rejectionMessage = "Close, but not quite good enough."
    } else if (deltaValue > -5) {
        rejectionMessage = "That's not a good deal for me."
    } else {
        rejectionMessage = "What, are you crazy?!"
    }

    return [false, "Trade rejected! \"" + rejectionMessage + "\""]
}

return propose
