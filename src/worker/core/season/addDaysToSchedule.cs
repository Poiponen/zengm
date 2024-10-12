// Framework: .NET

using System;
using System.Collections.Generic;
using System.Linq;

public class Game
{
    public int Season { get; set; }
    public int Day { get; set; }
}

public class ScheduleGameWithoutKey
{
    public int HomeTid { get; set; }
    public int AwayTid { get; set; }
    public int Day { get; set; }
}

public static class Util
{
    public static Dictionary<string, object> g = new Dictionary<string, object>
    {
        { "season", 2023 } // Example season value
    };
}

public static class ScheduleManager
{
    public static List<ScheduleGameWithoutKey> AddDaysToSchedule(
        List<(int HomeTid, int AwayTid)> games,
        List<Game> existingGames = null)
    {
        var dayTids = new HashSet<int>();
        bool prevDayAllStarGame = false;
        bool prevDayTradeDeadline = false;

        int day = 1;

        // If there are other games already played this season, start after that day
        if (existingGames != null)
        {
            int season = (int)Util.g["season"];
            foreach (var game in existingGames)
            {
                if (game.Season == season && game.Day >= day)
                {
                    day = game.Day + 1;
                }
            }
        }

        return games.Select(game =>
        {
            int awayTid = game.AwayTid;
            int homeTid = game.HomeTid;

            bool allStarGame = awayTid == -2 && homeTid == -1;
            bool tradeDeadline = awayTid == -3 && homeTid == -3;
            if (dayTids.Contains(homeTid) ||
                dayTids.Contains(awayTid) ||
                allStarGame ||
                prevDayAllStarGame ||
                tradeDeadline ||
                prevDayTradeDeadline)
            {
                day += 1;
                dayTids.Clear();
            }

            dayTids.Add(homeTid);
            dayTids.Add(awayTid);

            prevDayAllStarGame = allStarGame;
            prevDayTradeDeadline = tradeDeadline;

            return new ScheduleGameWithoutKey
            {
                HomeTid = homeTid,
                AwayTid = awayTid,
                Day = day
            };
        }).ToList();
    }
}
