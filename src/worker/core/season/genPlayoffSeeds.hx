type Seed = Dynamic; // Return the seeds (0 indexed) for the matchups, in order (null is a bye)

function genPlayoffSeeds(numPlayoffTeams: Int, numPlayoffByes: Int): Array<Seed> {
    var numRounds: Float = Math.log(numPlayoffTeams + numPlayoffByes) / Math.log(2);

    if (Math.floor(numRounds) != numRounds) {
        throw "Invalid genSeeds input: " + numPlayoffTeams + " teams and " + numPlayoffByes + " byes";
    }

    // Handle byes - replace lowest seeds with null
    var byeSeeds: Array<Int> = [];

    for (i in 0...numPlayoffByes) {
        byeSeeds.push(numPlayoffTeams + i);
    }

    function addMatchup(currentRound: Array<Seed>, team1: Int, maxTeamInRound: Int): Void {
        if (team1 == null) {
            throw "Invalid type";
        }

        var otherTeam: Int = maxTeamInRound - team1;
        currentRound.push([team1, byeSeeds.indexOf(otherTeam) >= 0 ? null : otherTeam]);
    }

    // Grow from the final matchup
    var lastRound: Array<Seed> = [[0, 1]];

    for (i in 0...numRounds - 1) {
        // Add two matchups to currentRound, for the two teams in lastRound. The sum of the seeds in a matchup is constant for an entire round!
        var numTeamsInRound: Int = lastRound.length * 4;
        var maxTeamInRound: Int = numTeamsInRound - 1;
        var currentRound: Array<Seed> = [];

        for (matchup in lastRound) {
            // swapOrder stuff is just cosmetic, matchups would be the same without it, just displayed slightly differently
            var swapOrder: Bool = (currentRound.length / 2) % 2 == 1 && matchup[1] != null;
            addMatchup(currentRound, matchup[swapOrder ? 1 : 0], maxTeamInRound);
            addMatchup(currentRound, matchup[swapOrder ? 0 : 1], maxTeamInRound);
        }

        lastRound = currentRound;
    }

    return lastRound;
}

export genPlayoffSeeds;
