#include <unordered_map>
#include <string>
#include <vector>
#include <cmath>

struct GamePlayer {
    struct Stats {
        int pts;
        int ast;
        int stl;
        int blk;
        int orb;
        int drb;
        int tp;
    } stat;
};

namespace helpers {
    int quarterLengthFactor() {
        // Implementation for quarterLengthFactor
        return 1; // Placeholder
    }

    int gameScore(const GamePlayer::Stats& stats) {
        // Implementation for gameScore
        return stats.pts + stats.ast + stats.stl + stats.blk + stats.orb + stats.drb + stats.tp; // Placeholder
    }
}

namespace g {
    std::string get(const std::string& key) {
        // Implementation for getting game state
        return "PLAYOFFS"; // Placeholder
    }
}

const std::string PHASE_PLAYOFFS = "PLAYOFFS";

std::unordered_map<std::string, int> checkStatisticalFeat(const GamePlayer& player) {
    const int minFactor = helpers::quarterLengthFactor();

    const int TEN = minFactor * 10;
    const int FIVE = minFactor * 5;
    const int TWENTY = minFactor * 20;
    const int TWENTY_FIVE = minFactor * 25;
    const int FIFTY = minFactor * 50;

    int doubleCount = 0;
    std::vector<std::string> stats = {"pts", "ast", "stl", "blk"};
    for (const auto& stat : stats) {
        if (stat == "pts" && player.stat.pts >= TEN) {
            doubleCount++;
        } else if (stat == "ast" && player.stat.ast >= TEN) {
            doubleCount++;
        } else if (stat == "stl" && player.stat.stl >= TEN) {
            doubleCount++;
        } else if (stat == "blk" && player.stat.blk >= TEN) {
            doubleCount++;
        }
    }

    if (player.stat.orb + player.stat.drb >= TEN) {
        doubleCount++;
    }

    std::unordered_map<std::string, int> statMap;

    if (player.stat.pts >= FIVE && player.stat.ast >= FIVE && player.stat.stl >= FIVE &&
        player.stat.blk >= FIVE && player.stat.orb + player.stat.drb >= FIVE) {
        statMap["points"] = player.stat.pts;
        statMap["rebounds"] = player.stat.orb + player.stat.drb;
        statMap["assists"] = player.stat.ast;
        statMap["steals"] = player.stat.stl;
        statMap["blocks"] = player.stat.blk;
    }

    if (doubleCount >= 3) {
        if (player.stat.pts >= TEN) {
            statMap["points"] = player.stat.pts;
        }
        if (player.stat.orb + player.stat.drb >= TEN) {
            statMap["rebounds"] = player.stat.orb + player.stat.drb;
        }
        if (player.stat.ast >= TEN) {
            statMap["assists"] = player.stat.ast;
        }
        if (player.stat.stl >= TEN) {
            statMap["steals"] = player.stat.stl;
        }
        if (player.stat.blk >= TEN) {
            statMap["blocks"] = player.stat.blk;
        }
    }

    if (player.stat.pts >= FIFTY) {
        statMap["points"] = player.stat.pts;
    }

    if (player.stat.orb + player.stat.drb >= TWENTY_FIVE) {
        statMap["rebounds"] = player.stat.orb + player.stat.drb;
    }

    if (player.stat.ast >= TWENTY) {
        statMap["assists"] = player.stat.ast;
    }

    if (player.stat.stl >= TEN) {
        statMap["steals"] = player.stat.stl;
    }

    if (player.stat.blk >= TEN) {
        statMap["blocks"] = player.stat.blk;
    }

    if (player.stat.tp >= TEN) {
        statMap["three pointers"] = player.stat.tp;
    }

    if (!statMap.empty()) {
        int gmsc = helpers::gameScore(player.stat);
        int score = std::round(gmsc / 2.0 + (g::get("phase") == PHASE_PLAYOFFS ? 10 : 0));
        return {{"feats", statMap}, {"score", score}};
    }

    return {{"score", 0}};
}
