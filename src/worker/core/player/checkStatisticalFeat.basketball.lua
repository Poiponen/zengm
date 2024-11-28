local util = require("../../../worker/util")
local commonTypes = require("../../../common/types")
local common = require("../../../common")

local function checkStatisticalFeat(player)
	local minFactor = util.helpers.quarterLengthFactor()

	local TEN = minFactor * 10
	local FIVE = minFactor * 5
	local TWENTY = minFactor * 20
	local TWENTY_FIVE = minFactor * 25
	local FIFTY = minFactor * 50
	local doubles = 0

	for _, stat in ipairs({"pts", "ast", "stl", "blk"}) do
		if player.stat[stat] >= TEN then
			doubles = doubles + 1
		end
	end

	if player.stat.orb + player.stat.drb >= TEN then
		doubles = doubles + 1
	end

	local statArr = {}

	if player.stat.pts >= FIVE and player.stat.ast >= FIVE and player.stat.stl >= FIVE and player.stat.blk >= FIVE and player.stat.orb + player.stat.drb >= FIVE then
		statArr.points = player.stat.pts
		statArr.rebounds = player.stat.orb + player.stat.drb
		statArr.assists = player.stat.ast
		statArr.steals = player.stat.stl
		statArr.blocks = player.stat.blk
	end

	if doubles >= 3 then
		if player.stat.pts >= TEN then
			statArr.points = player.stat.pts
		end

		if player.stat.orb + player.stat.drb >= TEN then
			statArr.rebounds = player.stat.orb + player.stat.drb
		end

		if player.stat.ast >= TEN then
			statArr.assists = player.stat.ast
		end

		if player.stat.stl >= TEN then
			statArr.steals = player.stat.stl
		end

		if player.stat.blk >= TEN then
			statArr.blocks = player.stat.blk
		end
	end

	if player.stat.pts >= FIFTY then
		statArr.points = player.stat.pts
	end

	if player.stat.orb + player.stat.drb >= TWENTY_FIVE then
		statArr.rebounds = player.stat.orb + player.stat.drb
	end

	if player.stat.ast >= TWENTY then
		statArr.assists = player.stat.ast
	end

	if player.stat.stl >= TEN then
		statArr.steals = player.stat.stl
	end

	if player.stat.blk >= TEN then
		statArr.blocks = player.stat.blk
	end

	if player.stat.tp >= TEN then
		statArr["three pointers"] = player.stat.tp
	end

	if next(statArr) ~= nil then
		local gameScore = util.helpers.gameScore(player.stat)
		local score = math.round(gameScore / 2 + (util.g:get("phase") == common.PHASE.PLAYOFFS and 10 or 0))
		return {
			feats = statArr,
			score = score,
		}
	end

	return {
		score = 0,
	}
end

return checkStatisticalFeat
