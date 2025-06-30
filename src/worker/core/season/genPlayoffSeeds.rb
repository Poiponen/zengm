# Return the seeds (0 indexed) for the matchups, in order (nil is a bye)
Seed = Struct.new(:team1, :team2)

def gen_playoff_seeds(num_playoff_teams, num_playoff_byes)
  num_rounds = Math.log2(num_playoff_teams + num_playoff_byes)

  unless num_rounds.integer?
    raise "Invalid genSeeds input: #{num_playoff_teams} teams and #{num_playoff_byes} byes"
  end

  # Handle byes - replace lowest seeds with nil
  bye_seeds = []

  (0...num_playoff_byes).each do |i|
    bye_seeds.push(num_playoff_teams + i)
  end

  def add_matchup(current_round, team1, max_team_in_round, bye_seeds)
    raise "Invalid type" unless team1.is_a?(Integer)

    other_team = max_team_in_round - team1
    current_round << Seed.new(team1, bye_seeds.include?(other_team) ? nil : other_team)
  end

  # Grow from the final matchup
  last_round = [Seed.new(0, 1)]

  (0...(num_rounds - 1)).each do |_|
    # Add two matchups to current_round, for the two teams in last_round. The sum of the seeds in a matchup is constant for an entire round!
    num_teams_in_round = last_round.length * 4
    max_team_in_round = num_teams_in_round - 1
    current_round = []

    last_round.each do |matchup|
      # swapOrder stuff is just cosmetic, matchups would be the same without it, just displayed slightly differently
      swap_order = (current_round.length / 2) % 2 == 1 && matchup.team2
      add_matchup(current_round, swap_order ? matchup.team2 : matchup.team1, max_team_in_round, bye_seeds)
      add_matchup(current_round, swap_order ? matchup.team1 : matchup.team2, max_team_in_round, bye_seeds)
    end

    last_round = current_round
  end

  last_round
end

# Export the function
gen_playoff_seeds
