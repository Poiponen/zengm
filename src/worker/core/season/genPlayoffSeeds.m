typedef NSArray<NSNumber *> Seed; // Return the seeds (0 indexed) for the matchups, in order (nil is a bye)

NSArray<Seed> *genPlayoffSeeds(NSInteger numPlayoffTeams, NSInteger numPlayoffByes) {
    double numRounds = log2(numPlayoffTeams + numPlayoffByes);

    if (numRounds != floor(numRounds)) {
        @throw [NSException exceptionWithName:@"InvalidInputException"
                                       reason:[NSString stringWithFormat:@"Invalid genSeeds input: %ld teams and %ld byes", (long)numPlayoffTeams, (long)numPlayoffByes]
                                     userInfo:nil];
    }

    // Handle byes - replace lowest seeds with nil
    NSMutableArray<NSNumber *> *byeSeeds = [NSMutableArray array];

    for (NSInteger i = 0; i < numPlayoffByes; i++) {
        [byeSeeds addObject:@(numPlayoffTeams + i)];
    }

    void (^addMatchup)(NSMutableArray<Seed> *, NSNumber *, NSInteger) = ^(NSMutableArray<Seed> *currentRound, NSNumber *team1, NSInteger maxTeamInRound) {
        if (![team1 isKindOfClass:[NSNumber class]]) {
            @throw [NSException exceptionWithName:@"InvalidTypeException"
                                           reason:@"Invalid type"
                                         userInfo:nil];
        }

        NSInteger otherTeam = maxTeamInRound - team1.integerValue;
        [currentRound addObject:@[team1, [byeSeeds containsObject:@(otherTeam)] ? [NSNull null] : @(otherTeam)]];
    };

    // Grow from the final matchup
    NSMutableArray<Seed> *lastRound = [NSMutableArray arrayWithObject:@[@0, @1]];

    for (NSInteger i = 0; i < numRounds - 1; i++) {
        // Add two matchups to currentRound, for the two teams in lastRound. The sum of the seeds in a matchup is constant for an entire round!
        NSInteger numTeamsInRound = lastRound.count * 4;
        NSInteger maxTeamInRound = numTeamsInRound - 1;
        NSMutableArray<Seed> *currentRound = [NSMutableArray array];

        for (Seed matchup in lastRound) {
            // swapOrder stuff is just cosmetic, matchups would be the same without it, just displayed slightly differently
            BOOL swapOrder = (currentRound.count / 2) % 2 == 1 && matchup[1] != [NSNull null];
            addMatchup(currentRound, swapOrder ? matchup[1] : matchup[0], maxTeamInRound);
            addMatchup(currentRound, swapOrder ? matchup[0] : matchup[1], maxTeamInRound);
        }

        lastRound = currentRound;
    }

    return lastRound;
}
