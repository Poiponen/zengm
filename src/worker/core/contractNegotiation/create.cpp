#include <string>
#include <stdexcept>
#include <optional>
#include <future>
#include <map>

// Assuming the existence of these classes and functions based on the TypeScript code
namespace g {
    std::map<std::string, int> settings;
    int get(const std::string &key) {
        return settings[key];
    }
}

namespace lock {
    std::map<std::string, bool> locks;
    bool get(const std::string &key) {
        return locks[key];
    }
}

namespace idb {
    namespace cache {
        namespace players {
            std::optional<Player> get(int pid);
        }
        namespace negotiations {
            void clear();
            void add(const Negotiation &negotiation);
        }
    }
}

namespace helpers {
    std::string leagueUrl(const std::vector<std::string> &path) {
        // Implementation for creating league URL
    }
}

struct Player {
    int pid;
    int tid;
    std::string firstName;
    std::string lastName;
};

struct Negotiation {
    int pid;
    int tid;
    bool resigning;
};

namespace player {
    struct MoodInfo {
        bool willing;
    };
    
    std::future<MoodInfo> moodInfo(const Player &p, int tid);
}

/**
 * Start a new contract negotiation with a player.
 *
 * @param pid An integer that must correspond with the player ID of a free agent.
 * @param resigning Set to true if this is a negotiation for a contract extension, which will allow multiple simultaneous negotiations. Set to false otherwise.
 * @param tid Team ID the contract negotiation is with. This only matters for Multi Team Mode. If undefined, defaults to g.get("userTid").
 * @return If an error occurs, return a string error message.
 */
std::future<std::optional<std::string>> create(int pid, bool resigning, int tid = g::get("userTid")) {
    if (g::get("phase") > PHASE::AFTER_TRADE_DEADLINE && g::get("phase") <= PHASE::RESIGN_PLAYERS && !resigning) {
        return std::make_ready_future(std::make_optional<std::string>("You're not allowed to sign free agents now."));
    }

    if (lock::get("gameSim")) {
        return std::make_ready_future(std::make_optional<std::string>("You cannot initiate a new negotiation while game simulation is in progress."));
    }

    if (g::get("phase") < 0) {
        return std::make_ready_future(std::make_optional<std::string>("You're not allowed to sign free agents now."));
    }

    auto p = idb::cache::players::get(pid);
    if (!p.has_value()) {
        throw std::runtime_error("Invalid pid");
    }

    if (p->tid != PLAYER::FREE_AGENT) {
        return std::make_ready_future(std::make_optional<std::string>(p->firstName + " " + p->lastName + " is not a free agent."));
    }

    if (!resigning) {
        auto moodInfo = player::moodInfo(*p, tid).get();
        if (!moodInfo.willing) {
            return std::make_ready_future(std::make_optional<std::string>(
                "<a href=\"" + helpers::leagueUrl({ "player", std::to_string(p->pid) }) + "\">" +
                p->firstName + " " + p->lastName + "</a> refuses to sign with you, no matter what you offer."
            ));
        }
    }

    Negotiation negotiation = { pid, tid, resigning };

    // Except in re-signing phase, only one negotiation at a time
    if (!resigning) {
        idb::cache::negotiations::clear();
    }

    idb::cache::negotiations::add(negotiation); // This will be handled by phase change when re-signing

    if (!resigning) {
        // Assuming these functions exist
        await updateStatus("Contract negotiation");
        await updatePlayMenu();
    }

    return std::nullopt; // No error
}
