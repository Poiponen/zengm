local common = require("../../../common")
local playerModule = require("..")
local db = require("../../db")
local util = require("../../util")
local g = util.g
local helpers = util.helpers
local lock = util.lock
local updatePlayMenu = util.updatePlayMenu
local updateStatus = util.updateStatus

--- Start a new contract negotiation with a player.
--- @param playerId number An integer that must correspond with the player ID of a free agent.
--- @param isResigning boolean Set to true if this is a negotiation for a contract extension, which will allow multiple simultaneous negotiations. Set to false otherwise.
--- @param teamId number Team ID the contract negotiation is with. This only matters for Multi Team Mode. If undefined, defaults to g.get("userTid").
--- @return string If an error occurs, resolve to a string error message.
local function create(playerId, isResigning, teamId)
	teamId = teamId or g.get("userTid")

	if g.get("phase") > common.PHASE.AFTER_TRADE_DEADLINE and g.get("phase") <= common.PHASE.RESIGN_PLAYERS and not isResigning then
		return "You're not allowed to sign free agents now."
	end

	if lock.get("gameSim") then
		return "You cannot initiate a new negotiation while game simulation is in progress."
	end

	if g.get("phase") < 0 then
		return "You're not allowed to sign free agents now."
	end

	local playerData = db.cache.players.get(playerId)
	if not playerData then
		error("Invalid playerId")
	end

	if playerData.tid ~= common.PLAYER.FREE_AGENT then
		return playerData.firstName .. " " .. playerData.lastName .. " is not a free agent."
	end

	if not isResigning then
		local moodInformation = playerModule.moodInfo(playerData, teamId)
		if not moodInformation.willing then
			return string.format('<a href="%s">%s %s</a> refuses to sign with you, no matter what you offer.', 
				helpers.leagueUrl({"player", playerData.pid}),
				playerData.firstName,
				playerData.lastName)
		end
	end

	local negotiationDetails = {
		pid = playerId,
		tid = teamId,
		resigning = isResigning,
	}

	-- Except in re-signing phase, only one negotiation at a time
	if not isResigning then
		db.cache.negotiations.clear()
	end

	db.cache.negotiations.add(negotiationDetails) -- This will be handled by phase change when re-signing

	if not isResigning then
		updateStatus("Contract negotiation")
		updatePlayMenu()
	end
end

return create
