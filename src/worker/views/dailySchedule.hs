module DailySchedule where

import qualified Database as DB
import qualified Util as Util
import qualified Core as Core
import qualified Common.Types as Types
import Control.Monad (forM_)
import Data.Map (Map)
import qualified Data.Map as Map

data UpdateEvents = FirstRun | GameSim | NewPhase deriving (Eq, Show)
data ViewInput a = ViewInput { season :: Int, day :: Maybe Int, today :: Bool }

prevInputsDay :: Maybe Int
prevInputsDay = Nothing

updateDailySchedule :: ViewInput "dailySchedule" -> [UpdateEvents] -> State -> IO ()
updateDailySchedule inputs updateEvents state = do
    currentSeason <- Util.get "season"

    if 
        FirstRun `elem` updateEvents || 
        (season inputs == currentSeason && GameSim `elem` updateEvents) || 
        NewPhase `elem` updateEvents || 
        season inputs /= season state || 
        day inputs /= day state
    then do
        let process inputsDayOverride = do
                games <- DB.getCopiesGames (season inputs) "noCopyCache"

                let daysAndPlayoffs = Map.fromList [(game.day, game.playoffs) | game <- games, game.day /= Nothing]

                let isToday = False

                let day = case today inputs of
                            True -> -1
                            False -> case inputsDayOverride of
                                        Just dayOverride -> dayOverride
                                        Nothing -> case day inputs of
                                                     Just d -> d
                                                     Nothing -> -1

                prevInputsDay <- return (Just (day inputs))

                if season inputs == currentSeason
                then do
                    schedule <- Core.getSchedule

                    let day = if day == -1 && not (null schedule) && day (head schedule) /= Nothing
                              then day (head schedule)
                              else if day == -1 
                                   then 1 
                                   else day

                    let scheduleDay = filter (\game -> game.day == day) schedule
                    let isToday = not (null scheduleDay) && gid (head schedule) == gid (head scheduleDay)

                    let isPlayoffs = Util.get "phase" == PHASE_PLAYOFFS

                    forM_ schedule $ \game -> 
                        if game.day /= Nothing 
                        then Map.insert (game.day) isPlayoffs daysAndPlayoffs
                        else return ()
                else do
                    let day = if day == -1 then 1 else day
        process Nothing
    else return ()

data State = State { season :: Int, day :: Maybe Int }

completedGames :: [Game] -> Day -> [Game]
completedGames games day = filter (\game -> day game == day) games

getUpcomingGames :: Inputs -> Season -> Day -> IO [UpcomingGame]
getUpcomingGames inputs currentSeason day = do
    let upcomingGames = []
    if season inputs == currentSeason
        then do
            -- If it's the current season, get any upcoming games
            upcomingGames <- getUpcoming (UpcomingParams day)
        else return upcomingGames

daysAndPlayoffsList :: Map Day Playoffs -> [(Day, Playoffs)]
daysAndPlayoffsList daysAndPlayoffs = 
    sortBy (\(dayA, _) (dayB, _) -> compare dayA dayB) $ 
    map (\(day, playoffs) -> (day, playoffs)) (Map.toList daysAndPlayoffs)

process :: Day -> IO Info
process day = do
    completed <- completedGames games day
    upcoming <- getUpcomingGames inputs currentSeason day
    let days = daysAndPlayoffsList daysAndPlayoffs
    return Info { completed = completed, day = day, days = days, isToday = isToday, upcoming = upcoming }

updateDailySchedule :: IO Result
updateDailySchedule = do
    info <- process currentDay

    if null (completed info) && null (upcoming info) && not (null (days info))
        then do
            let dayAbove = find (\dayInfo -> key dayInfo > day info) (days info)
            let newDay = maybe (last (days info)) key dayAbove
            info <- process newDay
        else return info

    let completed = completed info
    let day = day info
    let days = days info
    let isToday = isToday info
    let upcoming = upcoming info

    topPlayers <- getTopPlayers Nothing 1

    return Result {
        completed = completed,
        currentSeason = currentSeason,
        day = day,
        days = days,
        elam = Map.lookup "elam" g,
        elamASG = Map.lookup "elamASG" g,
        isToday = isToday,
        phase = Map.lookup "phase" g,
        season = season inputs,
        ties = hasTies season "current",
        topPlayers = topPlayers,
        upcoming = upcoming,
        userTid = Map.lookup "userTid" g
    }
```
