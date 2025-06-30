import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CompletableFuture;

/**
 * Get an array of games from the schedule.
 *
 * @param options.ot An IndexedDB object store or transaction on schedule; if null is passed, then a new transaction will be used.
 * @param options.oneDay Return just one day (true) or all days (false). Default false.
 * @return Resolves to the requested schedule array.
 */
public class ScheduleService {
    
    public CompletableFuture<List<ScheduleGame>> getSchedule(boolean oneDay) {
        return idb.cache.schedule.getAll().thenApply(schedule -> {
            if (schedule.isEmpty()) {
                return schedule;
            }

            if (oneDay) {
                List<ScheduleGame> partialSchedule = new ArrayList<>();
                Set<Integer> teamIds = new HashSet<>();
                
                for (ScheduleGame game : schedule) {
                    if (game.day != schedule.get(0).day) {
                        // Only keep games from same day
                        break;
                    }
                    if (teamIds.contains(game.homeTid) || teamIds.contains(game.awayTid)) {
                        // Only keep games from unique teams, no 2 games in 1 day
                        break;
                    }

                    // For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because addDaysToSchedule should handle it, but just in case...
                    if ((game.homeTid < 0 || game.awayTid < 0) && !teamIds.isEmpty()) {
                        break;
                    }

                    partialSchedule.add(game);
                    teamIds.add(game.homeTid);
                    teamIds.add(game.awayTid);

                    // For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because addDaysToSchedule should handle it, but just in case...
                    if (game.homeTid < 0 || game.awayTid < 0) {
                        break;
                    }
                }
                return partialSchedule;
            }

            return schedule;
        });
    }
}
