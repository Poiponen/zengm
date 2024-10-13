import qualified Util (checkAccount)
import qualified Common.Types (Conditions, UpdateEvents, ViewInput)
import qualified Achievement (getAll)

updateAchievements :: Common.Types.ViewInput "account" -> [Common.Types.UpdateEvents] -> () -> Common.Types.Conditions -> IO (Maybe (Achievements))
updateAchievements inputs updateEvents state conditions = do
    if "firstRun" `elem` updateEvents || "account" `elem` updateEvents
        then do
            Util.checkAccount conditions
            achievements <- Achievement.getAll
            return $ Just achievements
        else
            return Nothing

data Achievements = Achievements {
    achievements :: [AchievementType]
}
