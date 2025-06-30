import static common.Index.WEBSITE_ROOT;
import common.Types.Conditions;
import util.Index.G;
import util.Index.Helpers;
import util.Index.LogEvent;
import static newScheduleGood.NewScheduleGood.newScheduleGood;

import java.util.List;

public class NewSchedule {

    public static int[][] createNewSchedule(List<Team> teams, Conditions conditions) {
        int[][] tids;
        String warning;

        // Fetch tids and warning from newScheduleGood function
        int[][] result = newScheduleGood(teams);
        tids = result[0];
        warning = result[1];

        // Add trade deadline
        int tradeDeadline = G.get("tradeDeadline");
        if (tradeDeadline < 1) {
            int index = Math.round(Helpers.bound(tradeDeadline, 0, 1) * tids.length);
            tids = insertAtIndex(tids, new int[]{-3, -3}, index);
        }

        // Add an All-Star Game
        Integer allStarGame = G.get("allStarGame");
        if (allStarGame != null && allStarGame >= 0) {
            int index = Math.round(Helpers.bound(allStarGame, 0, 1) * tids.length);
            tids = insertAtIndex(tids, new int[]{-1, -2}, index);
        }

        if (warning != null) {
            // System.out.println(G.get("season"), warning);
            LogEvent.logEvent(new LogEventData("info", 
                String.format("Your <a href=\"%s\">schedule settings (# Games, # Division Games, and # Conference Games)</a> combined with your teams/divs/confs cannot be handled by the schedule generator, so instead it will generate round robin matchups between all your teams. Message from the schedule generator: \"%s\" <a href=\"https://%s/manual/customization/schedule-settings/\" target=\"_blank\">More details.</a>",
                Helpers.leagueUrl(new String[]{"settings"}), warning, WEBSITE_ROOT),
                false), conditions);
        }

        return tids;
    }

    private static int[][] insertAtIndex(int[][] array, int[] element, int index) {
        int[][] newArray = new int[array.length + 1][];
        System.arraycopy(array, 0, newArray, 0, index);
        newArray[index] = element;
        System.arraycopy(array, index, newArray, index + 1, array.length - index);
        return newArray;
    }

    static class Team {
        SeasonAttributes seasonAttrs;
        int tid;

        static class SeasonAttributes {
            int cid;
            int did;
        }
    }
}
