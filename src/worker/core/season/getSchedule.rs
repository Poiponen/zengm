const get_schedule = async fn(one_day: bool) -> Result<Vec<ScheduleGame>, Error> {
    let schedule = idb.cache.schedule.get_all().await?;

    if schedule.is_empty() {
        return Ok(schedule);
    }

    if one_day {
        let mut partial_schedule = Vec::new();
        let mut team_ids = std::collections::HashSet::new();
        for game in schedule.iter() {
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

            partial_schedule.push(game.clone());
            team_ids.insert(game.home_tid);
            team_ids.insert(game.away_tid);

            // For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because add_days_to_schedule should handle it, but just in case...
            if game.home_tid < 0 || game.away_tid < 0 {
                break;
            }
        }
        return Ok(partial_schedule);
    }

    Ok(schedule)
};

pub use get_schedule;
