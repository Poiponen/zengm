use crate::common::{PHASE, PLAYER};
use crate::player;
use crate::db::idb;
use crate::util::{g, helpers, lock, update_play_menu, update_status};

/**
 * Start a new contract negotiation with a player.
 *
 * @memberOf core.contractNegotiation
 * @param pid An integer that must correspond with the player ID of a free agent.
 * @param resigning Set to true if this is a negotiation for a contract extension, which will allow multiple simultaneous negotiations. Set to false otherwise.
 * @param tid Team ID the contract negotiation is with. This only matters for Multi Team Mode. If undefined, defaults to g.get("userTid").
 * @return If an error occurs, resolve to a string error message.
 */
pub async fn create(
    player_id: i32,
    is_resigning: bool,
    team_id: Option<i32>,
) -> Result<Option<String>, String> {
    let team_id = team_id.unwrap_or_else(|| g.get("userTid"));

    if g.get("phase") > PHASE.AFTER_TRADE_DEADLINE && g.get("phase") <= PHASE.RESIGN_PLAYERS && !is_resigning {
        return Err("You're not allowed to sign free agents now.".to_string());
    }

    if lock.get("gameSim") {
        return Err("You cannot initiate a new negotiation while game simulation is in progress.".to_string());
    }

    if g.get("phase") < 0 {
        return Err("You're not allowed to sign free agents now.".to_string());
    }

    let player_data = idb.cache.players.get(player_id).await.map_err(|_| "Invalid pid".to_string())?;
    
    if player_data.tid != PLAYER.FREE_AGENT {
        return Err(format!("{} {} is not a free agent.", player_data.first_name, player_data.last_name));
    }

    if !is_resigning {
        let mood_info = player.mood_info(&player_data, team_id).await?;
        if !mood_info.willing {
            return Err(format!(
                "<a href=\"{}\">{} {}</a> refuses to sign with you, no matter what you offer.",
                helpers.league_url(vec!["player", player_data.pid]),
                player_data.first_name,
                player_data.last_name
            ));
        }
    }

    let negotiation = Negotiation {
        pid: player_id,
        tid: team_id,
        resigning: is_resigning,
    };

    // Except in re-signing phase, only one negotiation at a time
    if !is_resigning {
        idb.cache.negotiations.clear().await?;
    }

    idb.cache.negotiations.add(negotiation).await?;

    if !is_resigning {
        update_status("Contract negotiation").await?;
        update_play_menu().await?;
    }

    Ok(None)
}

struct Negotiation {
    pid: i32,
    tid: i32,
    resigning: bool,
}
