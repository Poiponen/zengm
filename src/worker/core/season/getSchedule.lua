local idb = require("../../db/index")
local ScheduleGame = require("../../../common/types")

--- 
--- Get an array of games from the schedule.
---
--- @param options table Contains configuration options.
--- @param options.ot IDBObjectStore or IDBTransaction or nil An IndexedDB object store or transaction on schedule; if nil is passed, then a new transaction will be used.
--- @param options.oneDay boolean Return just one day (true) or all days (false). Default false.
--- @return Promise Resolves to the requested schedule array.
local function getSchedule(oneDay)
    oneDay = oneDay or false
    local schedule = idb.cache.schedule.getAll()

    if not schedule[1] then
        return schedule
    end

    if oneDay then
        local partialSchedule = {}
        local tids = {}
        for _, game in ipairs(schedule) do
            if game.day ~= schedule[1].day then
                -- Only keep games from same day
                break
            end
            if tids[game.homeTid] or tids[game.awayTid] then
                -- Only keep games from unique teams, no 2 games in 1 day
                break
            end

            -- For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because addDaysToSchedule should handle it, but just in case...
            if (game.homeTid < 0 or game.awayTid < 0) and next(tids) then
                break
            end

            table.insert(partialSchedule, game)
            tids[game.homeTid] = true
            tids[game.awayTid] = true

            -- For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because addDaysToSchedule should handle it, but just in case...
            if game.homeTid < 0 or game.awayTid < 0 then
                break
            end
        end
        return partialSchedule
    end

    return schedule
end

return getSchedule
