import { idb } from "../../db/index.coffee"
import { g } from "../../util/index.coffee"

export isFinals = ->
  numGamesPlayoffSeries = g.get("numGamesPlayoffSeries", "current")
  playoffSeries = await idb.cache.playoffSeries.get(g.get("season"))

  return playoffSeries?.currentRound is numGamesPlayoffSeries.length - 1
