-- This code is translated from TypeScript to Haskell
import qualified Database as DB
import qualified Util as Helpers
import Data.Map (Map)

data UpdateEvents = FirstRun | GameSim deriving (Eq, Show)
type AllStars = [AllStar] -- assuming AllStar is defined elsewhere

data AllStar = AllStar {
    gid :: Int,
    mvp :: Maybe TeamInfo,
    overtimes :: Int,
    score :: Int,
    season :: Int,
    teamNames :: [String],
    captain1 :: TeamInfo,
    captain2 :: TeamInfo,
    dunk :: Maybe TeamInfo,
    three :: Maybe TeamInfo
} deriving (Show)

data TeamInfo = TeamInfo {
    tid :: Int,
    abbrev :: String,
    pid :: Int,
    count :: Int
} deriving (Show)

addAbbrevAndCount :: TeamInfo -> TeamInfo
addAbbrevAndCount teamInfo = teamInfo { abbrev = getAbbrev (tid teamInfo), count = 0 }

getAbbrev :: Int -> String
getAbbrev teamId = maybe "" id (lookup teamId teamInfoCache)

teamInfoCache :: [(Int, String)]
teamInfoCache = [] -- Populate this with actual data

augment :: [AllStar] -> [AllStar]
augment allAllStars = 
    let augmented = map (\row -> 
            AllStar {
                gid = gid row,
                mvp = fmap addAbbrevAndCount (mvp row),
                overtimes = overtimes row,
                score = score row,
                season = season row,
                teamNames = teamNames row,
                captain1 = addAbbrevAndCount (head (teams row)),
                captain2 = addAbbrevAndCount (teams row !! 1),
                dunk = fmap addAbbrevAndCount (fmap (flip (!!) (winner (dunk row))) (dunk row)),
                three = fmap addAbbrevAndCount (fmap (flip (!!) (winner (three row))) (three row))
            }) allAllStars
        counts = Map.fromList [("captain", Map.empty), ("mvp", Map.empty), ("dunk", Map.empty), ("three", Map.empty)]
        keys = ["captain", "mvp", "dunk", "three"]

        updateCount key row = 
            let object = case key of
                    "captain1" -> Just (captain1 row)
                    "captain2" -> Just (captain2 row)
                    "mvp" -> mvp row
                    "dunk" -> dunk row
                    "three" -> three row
                in case object of
                    Just obj -> let pidValue = pid obj
                                    countKey = if key == "captain1" || key == "captain2" then "captain" else key
                                in case Map.lookup pidValue (counts Map.! countKey) of
                                    Nothing -> 
                                        let newCount = 1
                                        in counts Map.! countKey Map.insert (pidValue, newCount)
                                    Just count -> 
                                        let newCount = count + 1
                                        in counts Map.! countKey Map.insert (pidValue, newCount)
                                in object { count = newCount }
                    Nothing -> return ()

    in foldl (\augmentedRow row -> foldl (flip updateCount) augmentedRow keys) augmented

updateAllStarHistory :: [UpdateEvents] -> IO (Maybe (Map String [AllStar], Int))
updateAllStarHistory updateEvents = 
    if FirstRun `elem` updateEvents || GameSim `elem` updateEvents
    then do
        allAllStars <- DB.getAllStars
        return (Just (Map.fromList [("allAllStars", augment allAllStars)], getUserTid))
    else
        return Nothing

getUserTid :: Int
getUserTid = 0 -- Replace with actual userTid retrieval

```
