import db.idb;
import lodash.orderBy;
import util.g;
import common.PHASE;

function autoProtect(teamId: Int): Future<Array<Int>> {
    var expansionDraft = g.get("expansionDraft");
    if (g.get("phase") != PHASE.EXPANSION_DRAFT || expansionDraft.phase != "protection") {
        throw new Error("Invalid expansion draft phase");
    }

    var players = await idb.cache.players.indexGetAll("playersByTid", teamId);
    var maxNumCanProtect = Math.min(expansionDraft.numProtectedPlayers, players.length - expansionDraft.numPerTeam);
    var playerIds = orderBy(players, "valueFuzz", "desc")
        .slice(0, maxNumCanProtect)
        .map(function(player) return player.pid);
    return playerIds;
}

export autoProtect;
