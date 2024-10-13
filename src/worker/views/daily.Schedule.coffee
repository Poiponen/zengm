import { season } from "../core"
import { idb } from "../db"
import { g } from "../util"
import type { UpdateEvents, ViewInput } from "../../common/types"
import { getTopPlayers, getUpcoming } from "./schedule"
import { PHASE } from "../../common"

prevInputsDay = undefined

updateDailySchedule = (inputs, updateEvents, state) ->
    currentSeason = g.get("season")

    if updateEvents.includes("firstRun") or 
       (inputs.season is currentSeason and updateEvents.includes("gameSim")) or 
       updateEvents.includes("newPhase") or 
       inputs.season isnt state.season or 
       inputs.day isnt state.day

        process = (inputsDayOverride = undefined) ->
            games = await idb.getCopies.games(
                {
                    season: inputs.season
                },
                "noCopyCache"
            )

            daysAndPlayoffs = new Map()
            for game in games
                if game.day? 
                    daysAndPlayoffs.set(game.day, game.playoffs)

            isToday = false

            if inputs.today
                day = -1
            else
                # What day is it? Get it from URL by default, but that could be undefined
                day = inputsDayOverride or inputs.day or -1
                if day is -1
                    if updateEvents.includes("firstRun")
                        # If this is a new load of the view, initialize to the current day (current season) or day 1 (past season)
                        day = -1
                    else if prevInputsDay? 
                        # If this is a refresh and we're moving from day in URL to no day in URL, go to current day (current season) or day 1 (past season)
                        day = -1
                    else if state.day? 
                        # If this is a refresh and we already had a day loaded even with no day in the URL, keep that day the same
                        day = state.day

            prevInputsDay = inputs.day

            if inputs.season is currentSeason
                schedule = await season.getSchedule()

                if day is -1
                    if schedule.length > 0 and schedule[0].day?
                        day = schedule[0].day
                
                if day is -1
                    day = 1

                scheduleDay = schedule.filter (game) -> game.day is day
                isToday = scheduleDay.length > 0 and schedule[0].gid is scheduleDay[0].gid

                isPlayoffs = g.get("phase") is PHASE.PLAYOFFS

                for game in schedule
                    if game.day? 
                        daysAndPlayoffs.set(game.day, isPlayoffs)
            else
                if day is -1
                    day = 1
          completedGames = games.filter((game) -> game.day is day)

upcomingGames = []
if inputs.season is currentSeason
	# If it's the current season, get any upcoming games
	upcomingGames = await getUpcoming
		day: day

daysArray = Array.from(daysAndPlayoffs.entries())
	.map(([day, playoffs]) -> { day: day, playoffs: playoffs })
	.sort((a, b) -> a.day - b.day)
	.map(({ day, playoffs }) -> 
		{
			key: day
			value: if playoffs then "#{day} (playoffs)" else "#{day}"
		}
	)

return 
	 completed: completedGames
	 day: day
	 days: daysArray
	 isToday: isToday
	 upcoming: upcomingGames

info = await process()

if info.completed.length is 0 and info.upcoming.length is 0 and info.days.length > 0
	dayAbove = info.days.find(({ key }) -> key > info.day)

	newDay = if dayAbove then dayAbove.key else info.days.at(-1).key

	# No games at requested day, so just use the last day we actually have games for
	info = await process(newDay)

{ completed, day, days, isToday, upcoming } = info

topPlayers = await getTopPlayers(undefined, 1)

return 
	 completed: completed
	 currentSeason: currentSeason
	 day: day
	 days: days
	 elam: g.get("elam")
	 elamASG: g.get("elamASG")
	 isToday: isToday
	 phase: g.get("phase")
	 season: inputs.season
	 ties: season.hasTies("current")
	 topPlayers: topPlayers
	 upcoming: upcoming
	 userTid: g.get("userTid")
