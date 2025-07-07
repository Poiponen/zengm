from common.index import WEBSITE_ROOT
from common.types import Conditions
from util.index import g, helpers, log_event
from newScheduleGood import new_schedule_good

def new_schedule(teams, conditions=None):
    tids, warning = new_schedule_good(teams)

    # Add trade deadline
    trade_deadline = g.get("tradeDeadline")
    if trade_deadline < 1:
        ind = round(helpers.bound(trade_deadline, 0, 1) * len(tids))
        tids.insert(ind, [-3, -3])

    # Add an All-Star Game
    all_star_game = g.get("allStarGame")
    if all_star_game is not None and all_star_game >= 0:
        ind = round(helpers.bound(all_star_game, 0, 1) * len(tids))
        tids.insert(ind, [-1, -2])

    if warning is not None:
        # print(g.get("season"), warning)
        log_event(
            {
                "type": "info",
                "text": f'Your <a href="{helpers.league_url(["settings"])}">schedule settings (# Games, # Division Games, and # Conference Games)</a> combined with your teams/divs/confs cannot be handled by the schedule generator, so instead it will generate round robin matchups between all your teams. Message from the schedule generator: "{warning}" <a href="https://{WEBSITE_ROOT}/manual/customization/schedule-settings/" target="_blank">More details.</a>',
                "saveToDb": False,
            },
            conditions,
        )

    return tids
