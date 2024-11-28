local db = require("../../db")
local orderBy = require("lodash-es/orderBy")
local util = require("../../util")
local common = require("../../../common")

local function autoProtect(teamId)
    local expansionDraft = util.get("expansionDraft")
    if util.get("phase") ~= common.PHASE.EXPANSION_DRAFT or expansionDraft.phase ~= "protection" then
        error("Invalid expansion draft phase")
    end

    local players = db.cache.players.indexGetAll("playersByTid", teamId)
    local maxNumCanProtect = math.min(expansionDraft.numProtectedPlayers, #players - expansionDraft.numPerTeam)
    local playerIds = orderBy(players, "valueFuzz", "desc")
        :sub(1, maxNumCanProtect)
        :map(function(player) return player.pid end)
    
    return playerIds
end

return autoProtect
