// This code is a translation from TypeScript to Java with an emphasis on clarity and structure.
import java.util.concurrent.CompletableFuture;

public class PlayoffTeamsCalculator {
    
    // Method to get the number of playoff teams raw
    public static PlayoffTeams getNumPlayoffTeamsRaw(int numRounds, int numPlayoffByes, boolean playIn, boolean byConf) {
        int numPlayoffTeams = (int) Math.pow(2, numRounds) - numPlayoffByes;
        int numPlayInTeams = 0;
        
        if (playIn) {
            if (byConf) {
                numPlayInTeams += 4;
            } else {
                numPlayInTeams += 2;
            }
        }

        return new PlayoffTeams(numPlayoffTeams, numPlayInTeams);
    }

    // Method to get the number of playoff teams
    public static CompletableFuture<PlayoffTeams> getNumPlayoffTeams(int season) {
        int numRounds = GameUtils.getNumGamesPlayoffSeries(season).length;
        int numPlayoffByes = GameUtils.getNumPlayoffByes(season);

        CompletableFuture<Boolean> byConfFuture = PlayoffUtils.getPlayoffsByConf(season);
        
        return byConfFuture.thenCompose(byConf -> {
            CompletableFuture<PlayoffSeries> playoffSeriesFuture = Database.getCopy().playoffSeries(season, "noCopyCache");
            return playoffSeriesFuture.thenApply(playoffSeries -> {
                boolean playIn = (playoffSeries != null) ? playoffSeries.hasPlayIns() : GameUtils.getPlayIn();
                return getNumPlayoffTeamsRaw(numRounds, numPlayoffByes, playIn, byConf);
            });
        });
    }

    // Class to hold playoff teams information
    public static class PlayoffTeams {
        private final int numPlayoffTeams;
        private final int numPlayInTeams;

        public PlayoffTeams(int numPlayoffTeams, int numPlayInTeams) {
            this.numPlayoffTeams = numPlayoffTeams;
            this.numPlayInTeams = numPlayInTeams;
        }

        // Getters for the fields
        public int getNumPlayoffTeams() {
            return numPlayoffTeams;
        }

        public int getNumPlayInTeams() {
            return numPlayInTeams;
        }
    }
}
