import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class ScheduleUtil {
    public static List<ScheduleGameWithoutKey> addDaysToSchedule(
            List<GameDetails> games,
            List<Game> existingGames) {
        Set<Integer> dayTeamIds = new HashSet<>();
        boolean wasPreviousDayAllStarGame = false;
        boolean wasPreviousDayTradeDeadline = false;

        int currentDay = 1;

        // If there are other games already played this season, start after that day
        if (existingGames != null) {
            int currentSeason = GameUtils.getSeason();
            for (Game game : existingGames) {
                if (game.getSeason() == currentSeason && game.getDay() >= currentDay) {
                    currentDay = game.getDay() + 1;
                }
            }
        }

        return games.stream().map(game -> {
            int awayTeamId = game.getAwayTid();
            int homeTeamId = game.getHomeTid();

            boolean isAllStarGame = awayTeamId == -2 && homeTeamId == -1;
            boolean isTradeDeadline = awayTeamId == -3 && homeTeamId == -3;
            if (dayTeamIds.contains(homeTeamId) || 
                dayTeamIds.contains(awayTeamId) || 
                isAllStarGame || 
                wasPreviousDayAllStarGame || 
                isTradeDeadline || 
                wasPreviousDayTradeDeadline) {
                currentDay += 1;
                dayTeamIds.clear();
            }

            dayTeamIds.add(homeTeamId);
            dayTeamIds.add(awayTeamId);

            wasPreviousDayAllStarGame = isAllStarGame;
            wasPreviousDayTradeDeadline = isTradeDeadline;

            return new ScheduleGameWithoutKey(game, currentDay);
        }).toList();
    }
}
