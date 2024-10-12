# Framework: Ruby on Rails

def add_days_to_schedule(games, existing_games = nil)
  day_tid_set = Set.new
  previous_day_all_star_game = false
  previous_day_trade_deadline = false

  day = 1

  # If there are other games already played this season, start after that day
  if existing_games
    season = g.get("season")
    existing_games.each do |game|
      if game.season == season && game.day.is_a?(Numeric) && game.day >= day
        day = game.day + 1
      end
    end
  end

  games.map do |game|
    away_team_id = game[:awayTid]
    home_team_id = game[:homeTid]

    all_star_game = away_team_id == -2 && home_team_id == -1
    trade_deadline = away_team_id == -3 && home_team_id == -3
    if day_tid_set.include?(home_team_id) ||
       day_tid_set.include?(away_team_id) ||
       all_star_game ||
       previous_day_all_star_game ||
       trade_deadline ||
       previous_day_trade_deadline
      day += 1
      day_tid_set.clear
    end

    day_tid_set.add(home_team_id)
    day_tid_set.add(away_team_id)

    previous_day_all_star_game = all_star_game
    previous_day_trade_deadline = trade_deadline

    game.merge(day: day)
  end
end
