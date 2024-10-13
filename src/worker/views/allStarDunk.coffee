import { allStar } from "../core"
import type { DunkAttempt, UpdateEvents, ViewInput } from "../../common/types"
import { idb } from "../db"
import { g, getTeamInfoBySeason, helpers } from "../util"
import { isSport, PHASE } from "../../common"
import { orderBy } from "../../common/utils"

getShortTall = (playerIds) ->
	if !playerIds
		return []

	Promise.all(
		playerIds.map (playerId) ->
			p = await idb.getCopy.players({ pid: playerId }, "noCopyCache")
			if p
				return {
					pid: p.pid
					name: "#{p.firstName} #{p.lastName}"
					hgt: p.hgt
				}
		)
	)

updateAllStarDunk = async ({ season }, updateEvents, state) ->
	if !isSport("basketball")
		throw new Error("Not implemented")

	if updateEvents.includes("firstRun") or
			updateEvents.includes("gameAttributes") or
			updateEvents.includes("allStarDunk") or
			updateEvents.includes("watchList") or
			season != state.season

		allStars = await allStar.getOrCreate(season)
		dunk = allStars?.dunk
		if dunk is undefined
			if season == g.get("season") and g.get("phase") <= PHASE.REGULAR_SEASON
				return {
					redirectUrl: helpers.leagueUrl(["all_star", "dunk", season - 1])
				}

			# https://stackoverflow.com/a/59923262/786644
			returnValue =
				errorMessage: "Dunk contest not found"
			return returnValue

		playersRaw = await idb.getCopies.players(
			{
				pids: dunk.players.map (p) -> p.pid
			},
			"noCopyCache"
		)

		players = await idb.getCopies.playersPlus(playersRaw, {
			attrs: [
				"pid"
				"firstName"
				"lastName"
				"age"
				"watch"
				"face"
				"imgURL"
				"hgt"
				"weight"
				"awards"
			]
			ratings: ["ovr", "pot", "dnk", "jmp", "pos"]
			stats: ["gp", "pts", "trb", "ast", "jerseyNumber"]
			season
			fuzz: true
			mergeStats: "totOnly"
			showNoStats: true
		})

		for p in dunk.players
			p2 = players.find (p2) -> p2.pid == p.pid

			# p2 could be undefined if player was deleted before contest
			if p2
				ts = await getTeamInfoBySeason(p.tid, season)

				if ts
					p2.colors = ts.colors
					p2.jersey = ts.jersey
					p2.abbrev = ts.abbrev

    resultsByRound = dunk.rounds.map (round) ->
    orderBy(allStar.dunkContest.getRoundResults(round), "index", "asc")

log = []
for round in dunk.rounds
    if round is dunk.rounds[0]
        log.push
            type: "round"
            num: 1
    else if round.tiebreaker
        log.push
            type: "tiebreaker"
    else
        log.push
            type: "round"
            num: 2

    seenDunkers = new Set()
    for { attempts, index, made, score } in round.dunks
        num = undefined
        if not round.tiebreaker
            num = if seenDunkers.has(index) then 2 else 1
            seenDunkers.add(index)

        for i in [0...attempts.length]
            attempt = attempts[i]
            log.push
                type: "attempt"
                player: index
                num: num
                try: i + 1
                dunk: attempt
                made: attempt is attempts.at(-1) and made

        if score? 
            log.push
                type: "score"
                player: index
                made: made
                score: score

godMode = g.get("godMode")

started = log.length > 1

allPossibleContestants = []
if godMode and not started
    allPossibleContestants = orderBy(
        await idb.cache.players.indexGetAll("playersByTid", [0, Infinity]),
        ["lastName", "firstName"]
    ).map (p) ->
        {
            pid: p.pid
            tid: p.tid
            name: "#{p.firstName} #{p.lastName}"
            abbrev: helpers.getAbbrev(p.tid)
        }

awaitingUserDunkIndex = allStar.dunkContest.getAwaitingUserDunkIndex(dunk)

dunkAugmented = 
    dunk: dunk
    playersShort: await getShortTall(dunk.pidsShort)
    playersTall: await getShortTall(dunk.pidsTall)

{
    allPossibleContestants: allPossibleContestants
    awaitingUserDunkIndex: awaitingUserDunkIndex
    challengeNoRatings: g.get("challengeNoRatings")
    dunk: dunkAugmented
    godMode: godMode
    log: log
    players: players
    resultsByRound: resultsByRound
    season: season
    started: started
    userTid: g.get("userTid")
}

export default updateAllStarDunk
