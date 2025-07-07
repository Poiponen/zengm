type Seed = (i32, Option<i32>); // Return the seeds (0 indexed) for the matchups, in order (None is a bye)

fn gen_playoff_seeds(num_playoff_teams: i32, num_playoff_byes: i32) -> Vec<Seed> {
    let num_rounds = (num_playoff_teams + num_playoff_byes) as f64).log2();

    if num_rounds.fract() != 0.0 {
        panic!(
            "Invalid genSeeds input: {} teams and {} byes",
            num_playoff_teams, num_playoff_byes
        );
    }

    // Handle byes - replace lowest seeds with None
    let mut bye_seeds: Vec<i32> = Vec::new();

    for i in 0..num_playoff_byes {
        bye_seeds.push(num_playoff_teams + i);
    }

    fn add_matchup(current_round: &mut Vec<Seed>, team1: Option<i32>, max_team_in_round: i32) {
        let team1_value = team1.expect("Invalid type");

        let other_team = max_team_in_round - team1_value;
        current_round.push((
            team1_value,
            if bye_seeds.contains(&other_team) { None } else { Some(other_team) },
        ));
    }

    // Grow from the final matchup
    let mut last_round: Vec<Seed> = vec![(0, Some(1))];

    for _ in 0..(num_rounds as i32 - 1) {
        // Add two matchups to currentRound, for the two teams in lastRound. The sum of the seeds in a matchup is constant for an entire round!
        let num_teams_in_round = last_round.len() as i32 * 4;
        let max_team_in_round = num_teams_in_round - 1;
        let mut current_round: Vec<Seed> = Vec::new();

        for matchup in &last_round {
            // swap_order stuff is just cosmetic, matchups would be the same without it, just displayed slightly differently
            let swap_order = (current_round.len() / 2) % 2 == 1 && matchup.1.is_some();
            add_matchup(&mut current_round, if swap_order { matchup.1 } else { matchup.0 }, max_team_in_round);
            add_matchup(&mut current_round, if swap_order { matchup.0 } else { matchup.1 }, max_team_in_round);
        }

        last_round = current_round;
    }

    last_round
}
