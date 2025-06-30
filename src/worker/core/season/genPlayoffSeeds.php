<?php

type Seed = array<int, int|null>; // Return the seeds (0 indexed) for the matchups, in order (null is a bye)

function genPlayoffSeeds(int $numPlayoffTeams, int $numPlayoffByes): array {
    $numRounds = log($numPlayoffTeams + $numPlayoffByes, 2);

    if (!is_int($numRounds)) {
        throw new Exception(
            "Invalid genSeeds input: {$numPlayoffTeams} teams and {$numPlayoffByes} byes"
        );
    }

    // Handle byes - replace lowest seeds with null
    $byeSeeds = [];

    for ($i = 0; $i < $numPlayoffByes; $i++) {
        $byeSeeds[] = $numPlayoffTeams + $i;
    }

    $addMatchup = function(array &$currentRound, ?int $team1, int $maxTeamInRound) {
        if (!is_numeric($team1)) {
            throw new Exception("Invalid type");
        }

        $otherTeam = $maxTeamInRound - $team1;
        $currentRound[] = [
            $team1,
            in_array($otherTeam, $byeSeeds) ? null : $otherTeam,
        ];
    };

    // Grow from the final matchup
    $lastRound = [[0, 1]];

    for ($i = 0; $i < $numRounds - 1; $i++) {
        // Add two matchups to currentRound, for the two teams in lastRound. The sum of the seeds in a matchup is constant for an entire round!
        $numTeamsInRound = count($lastRound) * 4;
        $maxTeamInRound = $numTeamsInRound - 1;
        $currentRound = [];

        foreach ($lastRound as $matchup) {
            // swapOrder stuff is just cosmetic, matchups would be the same without it, just displayed slightly differently
            $swapOrder = (count($currentRound) / 2) % 2 === 1 && isset($matchup[1]);
            $addMatchup($currentRound, $matchup[$swapOrder ? 1 : 0], $maxTeamInRound);
            $addMatchup($currentRound, $matchup[$swapOrder ? 0 : 1], $maxTeamInRound);
        }

        $lastRound = $currentRound;
    }

    return $lastRound;
}
