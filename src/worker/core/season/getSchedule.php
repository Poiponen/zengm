<?php

require_once '../../db/index.php';
use Common\Types\ScheduleGame;

/**
 * Get an array of games from the schedule.
 *
 * @param {(IDBObjectStore|IDBTransaction|null)} $options['ot'] An IndexedDB object store or transaction on schedule; if null is passed, then a new transaction will be used.
 * @param {boolean} $options['oneDay'] Return just one day (true) or all days (false). Default false.
 * @return {Promise} Resolves to the requested schedule array.
 */
function getSchedule(bool $oneDay = false): array {
    $schedule = idb_cache_schedule_getAll();

    if (empty($schedule[0])) {
        return $schedule;
    }

    if ($oneDay) {
        $partialSchedule = [];
        $teamIds = new SplObjectStorage();
        foreach ($schedule as $game) {
            if ($game->day !== $schedule[0]->day) {
                // Only keep games from same day
                break;
            }
            if ($teamIds->contains($game->homeTid) || $teamIds->contains($game->awayTid)) {
                // Only keep games from unique teams, no 2 games in 1 day
                break;
            }

            // For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because addDaysToSchedule should handle it, but just in case...
            if (($game->homeTid < 0 || $game->awayTid < 0) && count($teamIds) > 0) {
                break;
            }

            $partialSchedule[] = $game;
            $teamIds->attach($game->homeTid);
            $teamIds->attach($game->awayTid);

            // For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because addDaysToSchedule should handle it, but just in case...
            if ($game->homeTid < 0 || $game->awayTid < 0) {
                break;
            }
        }
        return $partialSchedule;
    }

    return $schedule;
}

export default getSchedule;

```
