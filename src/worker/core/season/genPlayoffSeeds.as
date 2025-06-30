// Define a type alias for Seed as an array with a number and an optional number
type Seed = Array; // ActionScript does not support tuple types

// Function to generate playoff seeds
function genPlayoffSeeds(numPlayoffTeams:int, numPlayoffByes:int):Array {
    var numRounds:Number = Math.log(numPlayoffTeams + numPlayoffByes) / Math.log(2);

    if (numRounds % 1 !== 0) {
        throw new Error("Invalid genSeeds input: " + numPlayoffTeams + " teams and " + numPlayoffByes + " byes");
    }

    // Handle byes - replace lowest seeds with undefined
    var byeSeeds:Array = [];

    for (var i:int = 0; i < numPlayoffByes; i++) {
        byeSeeds.push(numPlayoffTeams + i);
    }

    // Function to add a matchup to the current round
    function addMatchup(currentRound:Array, team1:int, maxTeamInRound:int):void {
        if (isNaN(team1)) {
            throw new Error("Invalid type");
        }

        var otherTeam:int = maxTeamInRound - team1;
        currentRound.push([team1, byeSeeds.indexOf(otherTeam) >= 0 ? undefined : otherTeam]);
    }

    // Grow from the final matchup
    var lastRound:Array = [[0, 1]];

    for (i = 0; i < numRounds - 1; i++) {
        // Add two matchups to currentRound, for the two teams in lastRound
        var numTeamsInRound:int = lastRound.length * 4;
        var maxTeamInRound:int = numTeamsInRound - 1;
        var currentRound:Array = [];

        for each (var matchup:Array in lastRound) {
            // swapOrder stuff is just cosmetic
            var swapOrder:Boolean = (currentRound.length / 2) % 2 === 1 && matchup[1] !== undefined;
            addMatchup(currentRound, matchup[swapOrder ? 1 : 0], maxTeamInRound);
            addMatchup(currentRound, matchup[swapOrder ? 0 : 1], maxTeamInRound);
        }

        lastRound = currentRound;
    }

    return lastRound;
}

// Export the function
export default genPlayoffSeeds;
