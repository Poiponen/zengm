from typing import List, Tuple, Union
import math

Seed = Tuple[int, Union[int, None]]  # Return the seeds (0 indexed) for the matchups, in order (None is a bye)

def gen_playoff_seeds(num_playoff_teams: int, num_playoff_byes: int) -> List[Seed]:
    num_rounds = math.log2(num_playoff_teams + num_playoff_byes)

    if not num_rounds.is_integer():
        raise ValueError(f'Invalid genSeeds input: {num_playoff_teams} teams and {num_playoff_byes} byes')

    # Handle byes - replace lowest seeds with None
    bye_seeds: List[int] = []

    for i in range(num_playoff_byes):
        bye_seeds.append(num_playoff_teams + i)

    def add_matchup(current_round: List[Seed], team1: Union[int, None], max_team_in_round: int):
        if not isinstance(team1, int):
            raise TypeError("Invalid type")

        other_team = max_team_in_round - team1
        current_round.append((team1, other_team if other_team not in bye_seeds else None))

    # Grow from the final matchup
    last_round: List[Seed] = [(0, 1)]

    for i in range(int(num_rounds) - 1):
        # Add two matchups to currentRound, for the two teams in lastRound. The sum of the seeds in a matchup is constant for an entire round!
        num_teams_in_round = len(last_round) * 4
        max_team_in_round = num_teams_in_round - 1
        current_round: List[Seed] = []

        for matchup in last_round:
            # swapOrder stuff is just cosmetic, matchups would be the same without it, just displayed slightly differently
            swap_order = (len(current_round) // 2) % 2 == 1 and matchup[1] is not None
            add_matchup(current_round, matchup[1] if swap_order else matchup[0], max_team_in_round)
            add_matchup(current_round, matchup[0] if swap_order else matchup[1], max_team_in_round)

        last_round = current_round

    return last_round
