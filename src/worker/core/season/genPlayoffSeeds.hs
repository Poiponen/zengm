type Seed = (Int, Maybe Int) -- Return the seeds (0 indexed) for the matchups, in order (Nothing is a bye)

genPlayoffSeeds :: Int -> Int -> [Seed]
genPlayoffSeeds numPlayoffTeams numPlayoffByes =
    let numRounds = logBase 2 (fromIntegral (numPlayoffTeams + numPlayoffByes))
    in if not (isInteger numRounds)
        then error $ "Invalid genSeeds input: " ++ show numPlayoffTeams ++ " teams and " ++ show numPlayoffByes ++ " byes"
        else let byeSeeds = [numPlayoffTeams + i | i <- [0..(numPlayoffByes - 1)]]
                 addMatchup currentRound team1 maxTeamInRound =
                     if team1 < 0 then error "Invalid type"
                     else let otherTeam = maxTeamInRound - team1
                          in currentRound ++ [(team1, if otherTeam `elem` byeSeeds then Nothing else Just otherTeam)]
                 lastRound = [(0, Just 1)]
                 currentRounds = take (floor (numRounds - 1)) $ iterate growRound lastRound
                 growRound currentRound =
                     let numTeamsInRound = length currentRound * 4
                         maxTeamInRound = numTeamsInRound - 1
                         newRound = foldl (\acc matchup ->
                             let swapOrder = (length acc `div` 2) `mod` 2 == 1 && snd matchup /= Nothing
                             in addMatchup acc (if swapOrder then snd matchup else fst matchup) maxTeamInRound ++
                                addMatchup acc (if swapOrder then fst matchup else snd matchup) maxTeamInRound) [] currentRound
                     in newRound
             in last currentRounds

isInteger :: Float -> Bool
isInteger x = x == fromIntegral (round x)
