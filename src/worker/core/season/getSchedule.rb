async def get_schedule(one_day = false)
  schedule = await idb.cache.schedule.get_all

  return schedule if schedule[0].nil?

  if one_day
    partial_schedule = []
    team_ids = Set.new
    schedule.each do |game|
      break if game.day != schedule[0].day # Only keep games from same day
      break if team_ids.include?(game.home_tid) || team_ids.include?(game.away_tid) # Only keep games from unique teams, no 2 games in 1 day

      # For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because add_days_to_schedule should handle it, but just in case...
      break if (game.home_tid < 0 || game.away_tid < 0) && team_ids.size > 0

      partial_schedule.push(game)
      team_ids.add(game.home_tid)
      team_ids.add(game.away_tid)

      # For ASG and trade deadline, make absolutely sure they are alone. This shouldn't be necessary because add_days_to_schedule should handle it, but just in case...
      break if game.home_tid < 0 || game.away_tid < 0
    end
    return partial_schedule
  end

  return schedule
end

export_default get_schedule
