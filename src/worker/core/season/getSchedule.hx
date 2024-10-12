// This code is translated from TypeScript to Haxe.
import db.idb;

typedef ScheduleGame = {
    homeTid: Int,
    awayTid: Int,
    day: String,
};

/**
 * Get an array of games from the schedule.
 *
 * @param {Dynamic} options.ot An IndexedDB object store or transaction on schedule; if null is passed, then a new transaction will be used.
 * @param {Bool} options.oneDay Return just one day (true) or all days (false). Default false.
 * @return {Promise<Array<ScheduleGame>>>} Resolves to the requested schedule array.
 */
function getSchedule(oneDay: Bool = false): Promise<Array<ScheduleGame>> {
    return idb.cache.schedule.getAll().then(function(schedule) {
        if (schedule.length == 0) {
            return schedule;
        }

        if (oneDay) {
            var partialSchedule = [];
            var tids = new haxe.ds.Set<Int>();
            for (game in schedule) {
                if (game.day != schedule[0].day) {
                    // Only keep games from same day
                    break;
                }
                if (tids.has(game.homeTid) || tids.has(game.awayTid)) {
                    // Only keep games from unique teams, no 2 games in 1 day
                    break;
                }

                // For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because addDaysToSchedule should handle it, but just in case...
                if ((game.homeTid < 0 || game.awayTid < 0) && tids.size() > 0) {
                    break;
                }

                partialSchedule.push(game);
                tids.add(game.homeTid);
                tids.add(game.awayTid);

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

export default getSchedule;
