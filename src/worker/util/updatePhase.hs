import qualified Common (NO_LOTTERY_DRAFT_TYPES, PHASE_TEXT, PHASE)
import qualified G (get)
import qualified Local (phaseText)
import qualified ToUI (toUI)
import qualified Core (league)

-- Calculate phase text in worker rather than UI, because here we can easily cache it in the meta database
updatePhase :: Maybe Conditions -> IO ()
updatePhase conditions = do
    let phase = G.get "phase"
    let text = Common.PHASE_TEXT !! phase

    let updatedText = if phase == Common.PHASE.DRAFT_LOTTERY && 
                          (G.get "repeatSeason" || 
                           elem (G.get "draftType") Common.NO_LOTTERY_DRAFT_TYPES)
                     then "after playoffs"
                     else text

    let phaseText = show (G.get "season") ++ " " ++ updatedText

    if phaseText /= Local.phaseText
        then do
            Local.phaseText <- phaseText
            ToUI.toUI "updateLocal" [PhaseText phaseText]

            -- Update phase in meta database. No need to have this block updating the UI or anything.
            Core.league.updateMeta (PhaseText phaseText, Season (G.get "season"))
        else case conditions of
            Just cond -> ToUI.toUI "updateLocal" [PhaseText phaseText] cond
            Nothing -> return ()
