# This code is part of a web application using TypeScript and CoffeeScript.
import { idb } from "../db"

# Define a type for update events
type UpdateEvents = Array<string>

updateDashboard = (inputs, updateEvents) ->
	if updateEvents.includes("firstRun") or updateEvents.includes("leagues")
		leagues = await idb.meta.getAll("leagues")

		for league in leagues
			if league.teamRegion is undefined
				league.teamRegion = "???"

			if league.teamName is undefined
				league.teamName = "???"

		return
			leagues: leagues

export default updateDashboard
