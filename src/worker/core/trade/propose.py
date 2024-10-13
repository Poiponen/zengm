

from common import PHASE
from .. import team
from ../../util import g
from .clear import clear
from .processTrade import process_trade
from .summary import summary
from .get import get
from ../../db import idb

async def propose(force_trade: bool = False) -> tuple[bool, str | None]:
    if g.get("phase") >= PHASE.AFTER_TRADE_DEADLINE and g.get("phase") <= PHASE.PLAYOFFS:
        return (
            False,
            f"Error! You're not allowed to make trades {'after the trade deadline' if g.get('phase') == PHASE.AFTER_TRADE_DEADLINE else 'now'}.",
        )

    teams_data = await get()
    team_ids = [teams_data['teams'][0]['tid'], teams_data['teams'][1]['tid']]
    player_ids = [teams_data['teams'][0]['pids'], teams_data['teams'][1]['pids']]
    dead_player_ids = [teams_data['teams'][0]['dpids'], teams_data['teams'][1]['dpids']]

    # The summary will return a warning if there is a problem. In that case,
    # that warning will already be pushed to the user so there is no need to
    # return a redundant message here.
    summary_result = await summary(teams_data['teams'])

    if summary_result['warning'] and not force_trade:
        return (False, None)

    trade_outcome = "rejected"  # Default

    value_change = await team.value_change(
        teams_data['teams'][1]['tid'],
        teams_data['teams'][0]['pids'],
        teams_data['teams'][1]['pids'],
        teams_data['teams'][0]['dpids'],
        teams_data['teams'][1]['dpids'],
        None,
        g.get("userTid"),
    )

    if value_change > 0 or force_trade:
        # Trade players
        trade_outcome = "accepted"
        await process_trade(team_ids, player_ids, dead_player_ids)

    if trade_outcome == "accepted":
        await clear()  # Auto-sort team rosters

        for team_id in team_ids:
            team_data = await idb.cache.teams.get(team_id)
            only_new_players = g.get("userTids").count(team_id) > 0 and team_data and not team_data['keepRosterSorted']

            await team.roster_auto_sort(team_id, only_new_players)

        return (True, 'Trade accepted! "Nice doing business with you!"')

    # Return a different rejection message based on how close we are to a deal. When value_change < 0, the closer to 0, the better the trade for the AI.
    if value_change > -2:
        rejection_message = "Close, but not quite good enough."
    elif value_change > -5:
        rejection_message = "That's not a good deal for me."
    else:
        rejection_message = "What, are you crazy?!"

    return (False, f'Trade rejected! "{rejection_message}"')
