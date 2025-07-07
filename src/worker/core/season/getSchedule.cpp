#include <vector>
#include <set>
#include <optional>
#include "db/index.h" // Assuming a corresponding C++ DB header file
#include "common/types.h" // Assuming a corresponding C++ types header file

/**
 * Get an array of games from the schedule.
 *
 * @param {bool} oneDay Return just one day (true) or all days (false). Default false.
 * @return {std::vector<ScheduleGame>} Resolves to the requested schedule array.
 */
std::vector<ScheduleGame> getSchedule(bool oneDay = false) {
    std::vector<ScheduleGame> schedule = idb::cache::schedule::getAll();

    if (schedule.empty()) {
        return schedule;
    }

    if (oneDay) {
        std::vector<ScheduleGame> partialSchedule;
        std::set<int> teamIds;

        for (const auto& game : schedule) {
            if (game.day != schedule[0].day) {
                // Only keep games from same day
                break;
            }
            if (teamIds.count(game.homeTid) || teamIds.count(game.awayTid)) {
                // Only keep games from unique teams, no 2 games in 1 day
                break;
            }

            // For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because addDaysToSchedule should handle it, but just in case...
            if ((game.homeTid < 0 || game.awayTid < 0) && !teamIds.empty()) {
                break;
            }

            partialSchedule.push_back(game);
            teamIds.insert(game.homeTid);
            teamIds.insert(game.awayTid);

            // For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because addDaysToSchedule should handle it, but just in case...
            if (game.homeTid < 0 || game.awayTid < 0) {
                break;
            }
        }
        return partialSchedule;
    }

    return schedule;
}
