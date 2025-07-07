import db.idb;
import util.g;

public class FinalsChecker {
    public static async Task<Boolean> isFinals() {
        int[] numGamesPlayoffSeries = g.get("numGamesPlayoffSeries", "current");
        PlayoffSeries playoffSeries = await idb.cache.playoffSeries.get(g.get("season"));

        return playoffSeries != null && playoffSeries.currentRound == numGamesPlayoffSeries.length - 1;
    }
}
