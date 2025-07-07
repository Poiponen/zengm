from db.index import idb
from util.index import g

async def is_finals():
    num_games_playoff_series = g.get("numGamesPlayoffSeries", "current")
    playoff_series = await idb.cache.playoffSeries.get(g.get("season"))

    return playoff_series.currentRound == len(num_games_playoff_series) - 1
