import { idb } from "../../db/index.ts"
import type { ScheduleGame } from "../../../common/types.ts"

/**
 * Get an array of games from the schedule.
 *
 * @param {(IDBObjectStore|IDBTransaction|null)} options.ot An IndexedDB object store or transaction on schedule; if null is passed, then a new transaction will be used.
 * @param {boolean} options.oneDay Return just one day (true) or all days (false). Default false.
 * @return {Promise} Resolves to the requested schedule array.
 */
getSchedule = (oneDay = false) ->
  schedule = await idb.cache.schedule.getAll()

  if not schedule[0]
    return schedule

  if oneDay
    partialSchedule = []
    teamIds = new Set()
    for game in schedule
      if game.day isnt schedule[0].day
        # Only keep games from same day
        break
      
      if teamIds.has(game.homeTid) or teamIds.has(game.awayTid)
        # Only keep games from unique teams, no 2 games in 1 day
        break

      # For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because addDaysToSchedule should handle it, but just in case...
      if (game.homeTid < 0 or game.awayTid < 0) and teamIds.size > 0
        break

      partialSchedule.push(game)
      teamIds.add(game.homeTid)
      teamIds.add(game.awayTid)

      # For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because addDaysToSchedule should handle it, but just in case...
      if game.homeTid < 0 or game.awayTid < 0
        break

    return partialSchedule

  return schedule

export default getSchedule
