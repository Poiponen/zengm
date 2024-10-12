// This code is translated from TypeScript to Rust.

use std::collections::HashSet;
use futures::future::Future; // Assuming the use of async features in Rust
use crate::db::idb; // Adjust as per your Rust module structure
use crate::common::types::ScheduleGame; // Adjust as per your Rust module structure

/**
 * Get an array of games from the schedule.
 *
 * @param options.one_day Return just one day (true) or all days (false). Default false.
 * @return A future that resolves to the requested schedule array.
 */
async fn get_schedule(one_day: bool) -> Vec<ScheduleGame> {
    let schedule = idb.cache.schedule.get_all().await;

    if schedule.is_empty() {
        return schedule;
    }

    if one_day {
        let mut partial_schedule = Vec::new();
        let mut team_ids = HashSet::new();
        for game in schedule {
            if game.day != schedule[0].day {
                // Only keep games from same day
                break;
            }
            if team_ids.contains(&game.home_tid) || team_ids.contains(&game.away_tid) {
                // Only keep games from unique teams, no 2 games in 1 day
                break;
            }

            // For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because add_days_to_schedule should handle it, but just in case...
            if (game.home_tid < 0 || game.away_tid < 0) && !team_ids.is_empty() {
                break;
            }

            partial_schedule.push(game);
            team_ids.insert(game.home_tid);
            team_ids.insert(game.away_tid);

            // For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because add_days_to_schedule should handle it, but just in case...
            if game.home_tid < 0 || game.away_tid < 0 {
                break;
            }
        }
        return partial_schedule;
    }

    schedule
}
