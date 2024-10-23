#include <vector>
#include <string>
#include <unordered_map>
#include <set>
#include <optional>
#include <iostream>

struct ViewInput {
    int pid;
    int season;
};

struct UpdateEvents {
    std::vector<std::string> events;
};

struct PlayerStats {
    int gp;
    int season;
};

struct Game {
    struct Team {
        struct Player {
            int pid;
            // Other player attributes can be added here
        };
        std::vector<Player> players;
        int pts;
    };
    std::vector<Team> teams;
    int overtimes;
    int numPeriods;
};

std::optional<std::string> getCommon(int pid, int season) {
    // Simulated function to get common player data
    return std::nullopt; // Replace with actual implementation
}

std::vector<Game> getGames(int season) {
    // Simulated function to get games for a season
    return std::vector<Game>(); // Replace with actual implementation
}

std::string getTeamInfoBySeason(int tid, int season) {
    // Simulated function to get team abbreviation
    return "TEAM"; // Replace with actual implementation
}

std::string getAbbrev(int tid, std::unordered_map<int, std::string>& abbrevsByTid, int season) {
    if (tid == -1 || tid == -2) {
        return "ASG";
    }

    auto it = abbrevsByTid.find(tid);
    if (it == abbrevsByTid.end()) {
        std::string abbrev = getTeamInfoBySeason(tid, season);
        abbrevsByTid[tid] = abbrev.empty() ? "???" : abbrev;
    }
    return abbrevsByTid[tid];
}

std::string overtimeText(int overtimes, int numPeriods) {
    // Simulated function to get overtime text
    return ""; // Replace with actual implementation
}

PlayerStats processPlayerStats(PlayerStats row, const std::set<std::string>& allStats) {
    // Simulated function to process player stats
    return row; // Replace with actual implementation
}

bool filterPlayerStats(const PlayerStats& player, const std::vector<std::string>& stats, const std::string& type) {
    // Simulated function to filter player stats
    return true; // Replace with actual implementation
}

std::unordered_map<std::string, std::vector<std::string>> PLAYER_GAME_STATS;

std::unordered_map<std::string, std::vector<std::string>> updatePlayerGameLog(
    ViewInput viewInput,
    UpdateEvents updateEvents,
    std::unordered_map<std::string, PlayerStats>& state) {

    std::unordered_map<std::string, std::vector<std::string>> returnValue;

    if (std::find(updateEvents.events.begin(), updateEvents.events.end(), "firstRun") != updateEvents.events.end() ||
        state["pid"].pid != viewInput.pid ||
        state["season"].season != viewInput.season ||
        state["season"].season == getSeason()) {
        
        auto topStuff = getCommon(viewInput.pid, viewInput.season);

        if (!topStuff.has_value()) {
            returnValue["errorMessage"] = {"Error fetching player data"};
            return returnValue;
        }

        std::set<int> seasonsWithStatsSet;
        for (const auto& row : topStuff->player.stats) {
            if (row.gp > 0) {
                seasonsWithStatsSet.insert(row.season);
            }
        }
        std::vector<int> seasonsWithStats(seasonsWithStatsSet.rbegin(), seasonsWithStatsSet.rend());

        std::vector<std::string> superCols = {""};
        std::vector<std::string> stats;

        std::set<std::string> allStatsSet;
        for (const auto& entry : PLAYER_GAME_STATS) {
            for (const auto& stat : entry.second) {
                allStatsSet.insert(stat);
            }
        }

        std::vector<Game> games = getGames(viewInput.season);

        std::unordered_map<int, std::string> abbrevsByTid;

        std::vector<std::unordered_map<std::string, std::string>> gameLog;
        for (const auto& game : games) {
            PlayerStats row;
            int t0 = 0;

            auto it = std::find_if(game.teams[0].players.begin(), game.teams[0].players.end(),
                [&](const Player& player) { return player.pid == viewInput.pid; });
            if (it == game.teams[0].players.end()) {
                it = std::find_if(game.teams[1].players.begin(), game.teams[1].players.end(),
                    [&](const Player& player) { return player.pid == viewInput.pid; });
                t0 = 1;
            }
            if (it == game.teams[1].players.end()) {
                continue;
            }

            int t1 = t0 == 0 ? 1 : 0;
            std::string result;
            if (game.teams[t0].pts > game.teams[t1].pts) {
                result = "W";
            } else if (game.teams[t0].pts < game.teams[t1].pts) {
                result = "L";
            } else {
                result = "T";
            }

            std::string overtimeTextStr = overtimeText(game.overtimes, game.numPeriods);
            std::string overtimes = overtimeTextStr.empty() ? "" : " (" + overtimeTextStr + ")";

            PlayerStats processed = processPlayerStats(row, allStatsSet);
            row = processed;

            std::vector<std::string> types;
            for (const auto& entry : PLAYER_GAME_STATS) {
                const std::string& type = entry.first;
                const std::vector<std::string>& stats = entry.second;
                if (filterPlayerStats(row, stats, type)) {
                    types.push_back(type);
                }
            }
        }
    }
    return returnValue;
}

struct Game {
    std::vector<Team> teams;
    bool playoffs;
    int gid;
};

struct Team {
    int tid;
    std::unordered_map<std::string, int> playoffs;
    int pts;
};

std::string getAbbrev(int tid);
std::unordered_map<std::string, int> PLAYER_GAME_STATS;
std::vector<int> stats;
std::vector<SuperCol> superCols;
std::vector<GameLogEntry> gameLog;

struct SuperCol {
    std::string title;
    int colspan;
};

struct GameLogEntry {
    int gid;
    bool away;
    int tid;
    std::string abbrev;
    int oppTid;
    std::string oppAbbrev;
    std::string result;
    int diff;
    bool playoffs;
    std::unordered_map<std::string, int> stats;
    std::optional<int> injury;
    int won;
    int lost;
    int tied;
    int otl;
    std::optional<int> seed;
    std::optional<int> oppSeed;
};

struct Record {
    int won = 0;
    int lost = 0;
    int tied = 0;
    int otl = 0;
    std::optional<int> seed;
    std::optional<int> oppSeed;
};

Record updatePlayerGameLog(Game game, int t0, int t1, const std::string& result, const std::string& overtimes) {
    int tid = game.teams[t0].tid;
    int oppTid = game.teams[t1].tid;

    std::string abbrev = getAbbrev(tid);
    std::string oppAbbrev = getAbbrev(oppTid);
    
    std::unordered_map<std::string, int> gameStats;
    for (const auto& type : types) {
        const auto& info = PLAYER_GAME_STATS[type];

        // Filter gets rid of dupes, like how fmbLost appears for both Passing and Rushing in FBGM
        std::vector<int> newStats;
        for (const auto& stat : info.stats) {
            if (std::find(stats.begin(), stats.end(), stat) == stats.end()) {
                newStats.push_back(stat);
            }
        }

        if (!newStats.empty()) {
            stats.insert(stats.end(), newStats.begin(), newStats.end());
            superCols.push_back({info.name, static_cast<int>(newStats.size())});
        }

        for (const auto& stat : info.stats) {
            gameStats[stat] = p.processed[stat];
        }
    }

    Record record;
    if (game.playoffs) {
        const auto& playoffsInfo = game.teams[t0].playoffs;
        if (playoffsInfo) {
            record.won = playoffsInfo["won"];
            record.lost = playoffsInfo["lost"];
            record.seed = playoffsInfo["seed"];
            record.oppSeed = game.teams[t1].playoffs["seed"];
        }
    } else {
        for (const auto& key : std::array<std::string, 4>{"won", "lost", "tied", "otl"}) {
            const auto value = game.teams[t0][key];
            if (value != std::nullopt) {
                record[key] = value;
            }
        }
    }

    gameLog.push_back({
        game.gid,
        t0 == 1,
        tid,
        abbrev,
        oppTid,
        oppAbbrev,
        result + " " + std::to_string(game.teams[t0].pts) + "-" + std::to_string(game.teams[t1].pts) + overtimes,
        game.teams[t0].pts - game.teams[t1].pts,
        game.playoffs,
        gameStats,
        row.injury,
        record.won,
        record.lost,
        record.tied,
        record.otl,
        record.seed,
        record.oppSeed
    });

    return {
        topStuff,
        gameLog,
        g.get("numGamesPlayoffSeries", season),
        season,
        seasonsWithStats,
        stats,
        superCols.size() > 2 ? superCols : std::nullopt
    };
}
