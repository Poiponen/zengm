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

ongoing_series: List[Dict[str, any]] = []

num_games_total = len(tids)
daily_matchups: List[List[Tuple[int, int]]] = []
series_keys = list(series_grouped_by_teams.keys())
num_games_scheduled = 0

while num_games_scheduled < num_games_total:
    # Schedule games from ongoing_series
    tids_today: List[Tuple[int, int]] = []
    daily_matchups.append(tids_today)
    for series in ongoing_series:
        tids_today.append(tuple(series['matchup']))
        series['numGamesLeft'] -= 1
        num_games_scheduled += 1

    # Remove any series that are over
    ongoing_series = [series for series in ongoing_series if series['numGamesLeft'] > 0]

    # Add new series from teams not yet in an ongoing series for tomorrow
    tids_for_tomorrow = set()
    for series in ongoing_series:
        tids_for_tomorrow.add(series['matchup'][0])
        tids_for_tomorrow.add(series['matchup'][1])

    # Shuffle each day so it doesn't keep picking the same team first
    random.shuffle(series_keys)

    # Order by number of series remaining, otherwise it tends to have some bunched series against the same team at the end of the season
    series_keys.sort(key=lambda key: len(series_grouped_by_teams[key]), reverse=True)

    for key in series_keys:
        series_available = series_grouped_by_teams[key]
        if len(series_available) == 0:
            continue

        matchup = matchups_by_key[key]

        if matchup[0] in tids_for_tomorrow or matchup[1] in tids_for_tomorrow:
            continue

        num_games = series_available.pop() if series_available else None
        if num_games is None:
            continue

def group_schedule_series(daily_matchups: List[List[List[Any]]], ongoing_series: List[dict], tids_for_tomorrow: Set[Any]) -> List[Any]:
    ongoing_series.append({
        'matchup': matchup,
        'numGamesLeft': numGames,
    })

    tids_for_tomorrow.add(matchup[0])
    tids_for_tomorrow.add(matchup[1])

    # Start on 2nd to last day, see what we can move to the last day. Keep repeating, going further back each time. This is to make the end of season schedule less "jagged" (fewer teams that end the season early)
    for start_index in range(len(daily_matchups) - 2, -1, -1):
        for i in range(start_index, len(daily_matchups) - 1):
            today = daily_matchups[i]
            tomorrow = daily_matchups[i + 1]

            tids_tomorrow = set(item for sublist in tomorrow for item in sublist)

            to_remove = []
            for k in range(len(today)):
                matchup = today[k]
                if matchup[0] not in tids_tomorrow and matchup[1] not in tids_tomorrow:
                    tomorrow.append(matchup)
                    to_remove.append(k)

            # Remove from end, so indexes don't change
            to_remove.reverse()
            for index in to_remove:
                today.pop(index)

    # Some jaggedness remains, so just reverse it and put it at the beginning of the season. Not ideal, but it's less weird there.
    daily_matchups.reverse()

    return [item for sublist in daily_matchups for item in sublist]
