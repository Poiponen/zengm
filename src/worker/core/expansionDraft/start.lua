local idb = require("../../db")
local g = require("../../util").g
local helpers = require("../../util").helpers
local localUtil = require("../../util").local
local updatePlayMenu = require("../../util").updatePlayMenu
local autoProtect = require("./autoProtect")
local league = require("..").league
local draft = require("..").draft
local PHASE = require("../../../common").PHASE

local function start()
    local expansionDraft = helpers.deepCopy(g.get("expansionDraft"))

    if g.get("phase") ~= PHASE.EXPANSION_DRAFT or expansionDraft.phase ~= "protection" then
        error("Invalid expansion draft phase")
    end

    localUtil.fantasyDraftResults = {}

    local userTeamIds = g.get("userTids")

    local protectedPlayerIds = {}
    for tidString, playerIds in pairs(expansionDraft.protectedPids) do
        local teamId = tonumber(tidString)
        if table.contains(userTeamIds, teamId) and not localUtil.autoPlayUntil and not g.get("spectator") then
            for _, playerId in ipairs(playerIds) do
                table.insert(protectedPlayerIds, playerId)
            end
        else
            local autoPlayerIds = autoProtect(teamId)
            for _, playerId in ipairs(autoPlayerIds) do
                table.insert(protectedPlayerIds, playerId)
            end
        end
    end

    local availablePlayerIds = {}
    local allPlayers = idb.cache.players.indexGetAll("playersByTid", {0, math.huge})
    for _, player in ipairs(allPlayers) do
        if not table.contains(protectedPlayerIds, player.pid) then
            table.insert(availablePlayerIds, player.pid)
        end
    end

    -- Move draft picks around, like fantasy draft
    draft.genOrderFantasy(expansionDraft.expansionTids, "expansion")

    league.setGameAttributes({
        expansionDraft = {
            phase = "draft",
            numPerTeam = expansionDraft.numPerTeam,
            numPerTeamDrafted = {},
            expansionTids = expansionDraft.expansionTids,
            availablePids = availablePlayerIds,
        },
    })

    updatePlayMenu()
end

return start
