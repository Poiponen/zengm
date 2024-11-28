# Start a new contract negotiation with a player.
#
# @param [int] $playerId An integer that must correspond with the player ID of a free agent.
# @param [bool] $isResigning Set to true if this is a negotiation for a contract extension, which will allow multiple simultaneous negotiations. Set to false otherwise.
# @param [int] $teamId Team ID the contract negotiation is with. This only matters for Multi Team Mode. If undefined, defaults to $global:userTid.
# @return [string] If an error occurs, return a string error message.
function Create-ContractNegotiation {
    param (
        [int] $playerId,
        [bool] $isResigning,
        [int] $teamId = $global:userTid
    )

    if ($global:phase -gt $global:PHASE.AFTER_TRADE_DEADLINE -and 
        $global:phase -le $global:PHASE.RESIGN_PLAYERS -and 
        -not $isResigning) {
        return "You're not allowed to sign free agents now."
    }

    if ($lock.GameSim) {
        return "You cannot initiate a new negotiation while game simulation is in progress."
    }

    if ($global:phase -lt 0) {
        return "You're not allowed to sign free agents now."
    }

    $player = Get-PlayerFromDatabase -PlayerId $playerId
    if (-not $player) {
        throw "Invalid player ID"
    }

    if ($player.TeamId -ne $global:PLAYER.FREE_AGENT) {
        return "$($player.FirstName) $($player.LastName) is not a free agent."
    }

    if (-not $isResigning) {
        $moodInformation = Get-MoodInfo -Player $player -TeamId $teamId
        if (-not $moodInformation.Willing) {
            return "<a href='$($global:helpers.LeagueUrl(['player', $player.PlayerId]))'>$($player.FirstName) $($player.LastName)</a> refuses to sign with you, no matter what you offer."
        }
    }

    $negotiation = @{
        PlayerId = $playerId
        TeamId = $teamId
        IsResigning = $isResigning
    }

    # Except in re-signing phase, only one negotiation at a time
    if (-not $isResigning) {
        Clear-Negotiations
    }

    Add-Negotiation -Negotiation $negotiation

    if (-not $isResigning) {
        Update-Status -Status "Contract negotiation"
        Update-PlayMenu
    }
}
