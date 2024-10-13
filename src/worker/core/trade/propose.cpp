// This code is related to a trading system in a sports management simulation.

#include <string>
#include <array>
#include <optional>
#include <tuple>
#include <vector>
#include <iostream>
#include "common.h" // Assuming these headers are defined somewhere in the project
#include "util.h"
#include "clear.h"
#include "processTrade.h"
#include "summary.h"
#include "get.h"
#include "db.h"

using namespace std;

/**
 * Proposes the current trade in the database.
 *
 * Before proposing the trade, the trade is validated to ensure that all player IDs match up with team IDs.
 *
 * @param forceTrade When true (like in God Mode), this trade is accepted regardless of the AI
 * @return A tuple containing a boolean for whether the trade was accepted or not and a string containing a message to be displayed to the user.
 */
tuple<bool, optional<string>> propose(bool forceTrade = false) {
    if (g.get("phase") >= PHASE::AFTER_TRADE_DEADLINE && g.get("phase") <= PHASE::PLAYOFFS) {
        return {false, "Error! You're not allowed to make trades " +
                        (g.get("phase") == PHASE::AFTER_TRADE_DEADLINE ? "after the trade deadline" : "now")};
    }

    auto [teams] = get();
    array<int, 2> tids = {teams[0].tid, teams[1].tid};
    array<vector<int>, 2> pids = {teams[0].pids, teams[1].pids};
    array<vector<int>, 2> dpids = {teams[0].dpids, teams[1].dpids};

    // The summary will return a warning if there is a problem. In that case,
    // that warning will already be pushed to the user so there is no need to
    // return a redundant message here.
    auto s = summary(teams);

    if (s.warning && !forceTrade) {
        return {false, nullopt};
    }

    string outcome = "rejected"; // Default

    int dv = team.valueChange(
        teams[1].tid,
        teams[0].pids,
        teams[1].pids,
        teams[0].dpids,
        teams[1].dpids,
        nullopt,
        g.get("userTid")
    );

    if (dv > 0 || forceTrade) {
        // Trade players
        outcome = "accepted";
        processTrade(tids, pids, dpids);
    }

    if (outcome == "accepted") {
        clear(); // Auto-sort team rosters

        for (const auto& tid : tids) {
            auto t = idb.cache.teams.get(tid);
            bool onlyNewPlayers = 
                g.get("userTids").includes(tid) && t && !t.keepRosterSorted;

            team.rosterAutoSort(tid, onlyNewPlayers);
        }

        return {true, "Trade accepted! \"Nice doing business with you!\""};
    }

    // Return a different rejection message based on how close we are to a deal. When dv < 0, the closer to 0, the better the trade for the AI.
    string message;

    if (dv > -2) {
        message = "Close, but not quite good enough.";
    } else if (dv > -5) {
        message = "That's not a good deal for me.";
    } else {
        message = "What, are you crazy?!";
    }

    return {false, "Trade rejected! \"" + message + "\""};
}
