
require 'lodash-es/order_by'
require_relative '../../../common'
require_relative '../..'
require_relative './get_best'
require_relative '../../db'
require_relative '../../util'

# 
# AI teams sign free agents.
#
# Each team (in random order) will sign free agents up to their salary cap or roster size limit. This should eventually be made smarter
#
# @memberOf core.freeAgents
# @return {Promise}
def auto_sign
  players = idb.cache.players.index_get_all("playersByTid", PLAYER::FREE_AGENT)

  return if players.empty?

  # List of free agents, sorted by value
  players_sorted = order_by(players, 'value', 'desc')

  # Randomly order teams
  teams = idb.cache.teams.get_all
  random.shuffle(teams)

  teams.each do |team|
    # Skip the user's team
    if g.get("userTids").include?(team.tid) && !local.auto_play_until && !g.get("spectator")
      next
    end

    next if team.disabled

    prob_skip = if is_sport("basketball")
                  team.strategy == "rebuilding" ? 0.9 : 0.75
                else
                  0.5
                end

    # Skip teams sometimes
    next if rand < prob_skip

    players_on_roster = idb.cache.players.index_get_all("playersByTid", team.tid)

    # Ignore roster size, will drop bad player if necessary in checkRosterSizes, and get_best won't sign min contract player unless under the roster limit
    payroll = team.get_payroll(team.tid)
    best_player = get_best(players_on_roster, players_sorted, payroll)
    if best_player
      # Remove from list of free agents
      players_sorted.reject! { |p2| p2 == best_player }

      player.sign(best_player, team.tid, best_player.contract, g.get("phase"))
      idb.cache.players.put(best_player)
      team.roster_auto_sort(team.tid)
    end
  end
end

export :auto_sign
