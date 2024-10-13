# Framework: CoffeeScript

import orderBy from "lodash-es/orderBy"
import { isSport, PLAYER } from "../../../common"
import { player, team } from ".."
import getBest from "./getBest"
import { idb } from "../../db"
import { g, local, random } from "../../util"

/**
 * AI teams sign free agents.
 *
 * Each team (in random order) will sign free agents up to their salary cap or roster size limit. This should eventually be made smarter
 *
 * @memberOf core.freeAgents
 * @return {Promise}
 */
autoSign = ->
  players = await idb.cache.players.indexGetAll "playersByTid", PLAYER.FREE_AGENT

  return if players.length is 0

  # List of free agents, sorted by value
  playersSorted = orderBy(players, "value", "desc")

  # Randomly order teams
  teams = await idb.cache.teams.getAll()
  random.shuffle(teams)

  for team in teams
    # Skip the user's team
    if g.get("userTids").includes(team.tid) and not local.autoPlayUntil and not g.get("spectator")
      continue

    if team.disabled
      continue

    probSkip = if isSport("basketball") then if team.strategy is "rebuilding" then 0.9 else 0.75 else 0.5

    # Skip teams sometimes
    if Math.random() < probSkip
      continue

    playersOnRoster = await idb.cache.players.indexGetAll "playersByTid", team.tid

    # Ignore roster size, will drop bad player if necessary in checkRosterSizes, and getBest won't sign min contract player unless under the roster limit
    payroll = await team.getPayroll(team.tid)
    playerToSign = getBest(playersOnRoster, playersSorted, payroll)
    if playerToSign
      # Remove from list of free agents
      playersSorted = playersSorted.filter (freeAgent) -> freeAgent isnt playerToSign

      await player.sign(playerToSign, team.tid, playerToSign.contract, g.get("phase"))
      await idb.cache.players.put(playerToSign)
      await team.rosterAutoSort(team.tid)

export default autoSign
