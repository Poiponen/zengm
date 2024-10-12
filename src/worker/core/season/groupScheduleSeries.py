from random import shuffle

def group_schedule_series(team_ids):
    def matchup_to_key(matchup):
        return f"{matchup[0]}-{matchup[1]}"

    matchups_by_key = {}

    # Group all games between same teams with same home/away
    matchups_grouped_by_teams = {}
    for matchup in team_ids:
        key = matchup_to_key(matchup)
        matchups_by_key[key] = matchup
        if key not in matchups_grouped_by_teams:
            matchups_grouped_by_teams[key] = 0
        matchups_grouped_by_teams[key] += 1

    # Divide into groups of 3 or 4
    series_grouped_by_teams = {}
    for key in matchups_grouped_by_teams.keys():
        num_games_left = matchups_grouped_by_teams[key]
        series_grouped_by_teams[key] = []

        # Take series of 3 or 4 as long as possible
        while num_games_left > 0:
            if num_games_left == 1:
                target_length = 1
            elif num_games_left == 2:
                target_length = 2
            elif num_games_left in [3, 6, 9]:
                target_length = 3
            else:
                target_length = 4

            num_games_left -= target_length
            series_grouped_by_teams[key].append(target_length)

    for series in series_grouped_by_teams.values():
        # Randomize, or all the short series will be at the end
        shuffle(series)
