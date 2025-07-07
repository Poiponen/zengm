#include <iostream>
#include <string>
#include <optional>
#include <vector>

// Assuming necessary includes and using directives for idb and g

bool isFinals() {
    int numGamesPlayoffSeries = g.get("numGamesPlayoffSeries", "current");
    std::optional<PlayoffSeries> playoffSeries = idb.cache.playoffSeries.get(g.get("season"));

    return playoffSeries.has_value() && playoffSeries->currentRound == numGamesPlayoffSeries - 1;
}
