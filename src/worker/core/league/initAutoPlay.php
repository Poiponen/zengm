<?php
// This code is translated from TypeScript to PHP

require_once "./autoPlay.php";
require_once "../../util.php";

function initAutoPlay(array $conditions): bool {
    global $g;

    if ($g->get("gameOver")) {
        logEvent([
            "type" => "error",
            "text" => "You can't auto play while you're fired!",
            "showNotification" => true,
            "persistent" => true,
            "saveToDb" => false,
        ], $conditions);
        return false;
    }

    $result = toUI("autoPlayDialog", [$g->get("season"), (bool)$g->get("repeatSeason")], $conditions);

    if (!$result) {
        return false;
    }

    $season = (int)$result->season;
    $phase = (int)$result->phase;

    if ($season > $g->get("season") || ($season === $g->get("season") && $phase > $g->get("phase"))) {
        local::$autoPlayUntil = [
            "season" => $season,
            "phase" => $phase,
            "start" => time() * 1000, // Convert seconds to milliseconds
        ];
        autoPlay($conditions);
    } else {
        return false;
    }
}

export default initAutoPlay;
