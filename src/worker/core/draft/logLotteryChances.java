// This code is translated from TypeScript to Java.
import logAction from "./logAction";
import logLotteryTxt from "./logLotteryTxt";

import java.util.List;

public class LotteryLogger {

    public static void logLotteryChances(
            double[] chances,
            List<TeamFiltered> teams,
            List<List<DraftPickWithoutKey>> draftPicksIndexed,
            Conditions conditions) {
        
        for (int index = 0; index < chances.length; index++) {
            if (index < teams.size()) {
                int originalTeamId = teams.get(index).getTid();
                DraftPickWithoutKey draftPick = draftPicksIndexed.get(originalTeamId).get(1);

                if (draftPick != null) {
                    int teamId = draftPick.getTid();
                    String text = logLotteryTxt(teamId, "chance", chances[index]);
                    logAction(teamId, text, 0, conditions);
                }
            }
        }
    }
}
