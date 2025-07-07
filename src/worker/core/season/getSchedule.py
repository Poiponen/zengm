async def get_schedule(one_day: bool = False) -> list:
    schedule = await idb.cache.schedule.get_all()

    if not schedule:
        return schedule

    if one_day:
        partial_schedule = []
        team_ids = set()
        for game in schedule:
            if game.day != schedule[0].day:
                # Only keep games from same day
                break
            if game.home_tid in team_ids or game.away_tid in team_ids:
                # Only keep games from unique teams, no 2 games in 1 day
                break

            # For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because add_days_to_schedule should handle it, but just in case...
            if (game.home_tid < 0 or game.away_tid < 0) and len(team_ids) > 0:
                break

            partial_schedule.append(game)
            team_ids.add(game.home_tid)
            team_ids.add(game.away_tid)

            # For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because add_days_to_schedule should handle it, but just in case...
            if game.home_tid < 0 or game.away_tid < 0:
                break
        return partial_schedule

    return schedule
