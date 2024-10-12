# CoffeeScript source code translation from TypeScript
import type { Game, ScheduleGameWithoutKey } from "../../../common/types"
import { g } from "../../util"

addDaysToSchedule = (games, existingGames = []) ->
  dayTids = new Set()
  prevDayAllStarGame = false
  prevDayTradeDeadline = false

  day = 1

  # If there are other games in already played this season, start after that day
  if existingGames?
    season = g.get "season"
    for game in existingGames
      if game.season is season and typeof game.day is 'number' and game.day >= day
        day = game.day + 1

  return games.map (game) ->
    { awayTid, homeTid } = game

    allStarGame = awayTid is -2 and homeTid is -1
    tradeDeadline = awayTid is -3 and homeTid is -3
    if dayTids.has(homeTid) or dayTids.has(awayTid) or allStarGame or prevDayAllStarGame or tradeDeadline or prevDayTradeDeadline
      day += 1
      dayTids.clear()

    dayTids.add homeTid
    dayTids.add awayTid

    prevDayAllStarGame = allStarGame
    prevDayTradeDeadline = tradeDeadline

    return {
      ...game
      day: day
    }

export default addDaysToSchedule
