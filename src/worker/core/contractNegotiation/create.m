function errorMessage = create(playerId, isResigning, teamId)
    if nargin < 3
        teamId = g.get("userTid");
    end

    if g.get("phase") > PHASE.AFTER_TRADE_DEADLINE && g.get("phase") <= PHASE.RESIGN_PLAYERS && ~isResigning
        errorMessage = "You're not allowed to sign free agents now.";
        return;
    end

    if lock.get("gameSim")
        errorMessage = "You cannot initiate a new negotiation while game simulation is in progress.";
        return;
    end

    if g.get("phase") < 0
        errorMessage = "You're not allowed to sign free agents now.";
        return;
    end

    playerData = idb.cache.players.get(playerId);
    if isempty(playerData)
        error("Invalid playerId");
    end

    if playerData.tid ~= PLAYER.FREE_AGENT
        errorMessage = sprintf('%s %s is not a free agent.', playerData.firstName, playerData.lastName);
        return;
    end

    if ~isResigning
        moodInformation = player.moodInfo(playerData, teamId);
        if ~moodInformation.willing
            errorMessage = sprintf('<a href="%s">%s %s</a> refuses to sign with you, no matter what you offer.', ...
                helpers.leagueUrl({"player", playerData.pid}), playerData.firstName, playerData.lastName);
            return;
        end
    end

    negotiation = struct('pid', playerId, 'tid', teamId, 'resigning', isResigning);

    % Except in re-signing phase, only one negotiation at a time
    if ~isResigning
        idb.cache.negotiations.clear();
    end

    idb.cache.negotiations.add(negotiation); % This will be handled by phase change when re-signing

    if ~isResigning
        updateStatus("Contract negotiation");
        updatePlayMenu();
    end

    errorMessage = []; % No error
end
