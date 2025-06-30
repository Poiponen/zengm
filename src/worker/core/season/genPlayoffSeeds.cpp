#include <vector>
#include <stdexcept>
#include <cmath>

using Seed = std::pair<int, std::optional<int>>; // Return the seeds (0 indexed) for the matchups, in order (std::nullopt is a bye)

std::vector<Seed> genPlayoffSeeds(int numPlayoffTeams, int numPlayoffByes) {
    double numRounds = std::log2(numPlayoffTeams + numPlayoffByes);

    if (numRounds != static_cast<int>(numRounds)) {
        throw std::invalid_argument("Invalid genSeeds input: " + std::to_string(numPlayoffTeams) + " teams and " + std::to_string(numPlayoffByes) + " byes");
    }

    // Handle byes - replace lowest seeds with undefined
    std::vector<int> byeSeeds;

    for (int i = 0; i < numPlayoffByes; i++) {
        byeSeeds.push_back(numPlayoffTeams + i);
    }

    auto addMatchup = [&](std::vector<Seed>& currentRound, std::optional<int> team1, int maxTeamInRound) {
        if (!team1.has_value()) {
            throw std::invalid_argument("Invalid type");
        }

        int otherTeam = maxTeamInRound - team1.value();
        currentRound.emplace_back(team1.value(), std::find(byeSeeds.begin(), byeSeeds.end(), otherTeam) != byeSeeds.end() ? std::nullopt : otherTeam);
    };

    // Grow from the final matchup
    std::vector<Seed> lastRound = { {0, 1} };

    for (int i = 0; i < numRounds - 1; i++) {
        const int numTeamsInRound = static_cast<int>(lastRound.size()) * 4;
        const int maxTeamInRound = numTeamsInRound - 1;
        std::vector<Seed> currentRound;

        for (const auto& matchup : lastRound) {
            // swapOrder stuff is just cosmetic, matchups would be the same without it, just displayed slightly differently
            bool swapOrder = (currentRound.size() / 2) % 2 == 1 && matchup.second.has_value();
            addMatchup(currentRound, swapOrder ? matchup.second : matchup.first, maxTeamInRound);
            addMatchup(currentRound, swapOrder ? matchup.first : matchup.second, maxTeamInRound);
        }

        lastRound = currentRound;
    }

    return lastRound;
}
