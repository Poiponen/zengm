// This code is translated from TypeScript to Rust.

use crate::common::{WEBSITE_ROOT, Conditions};
use crate::util::{g, helpers, log_event};
use crate::new_schedule_good;

pub fn new_schedule(teams: Vec<Team>, conditions: Option<Conditions>) -> Vec<Vec<i32>> {
    let (team_ids, warning) = new_schedule_good(&teams);

    // Add trade deadline
    let trade_deadline = g.get("tradeDeadline");
    if trade_deadline < 1 {
        let index = (helpers::bound(trade_deadline, 0.0, 1.0) * team_ids.len() as f64).round() as usize;
        team_ids.insert(index, vec![-3, -3]);
    }

    // Add an All-Star Game
    let all_star_game = g.get("allStarGame");
    if all_star_game.is_some() && all_star_game.unwrap() >= 0 {
        let index = (helpers::bound(all_star_game.unwrap() as f64, 0.0, 1.0) * team_ids.len() as f64).round() as usize;
        team_ids.insert(index, vec![-1, -2]);
    }

    if let Some(warning_message) = warning {
        // println!("{:?}", g.get("season"), warning_message);
        log_event(
            Event {
                event_type: "info".to_string(),
                text: format!(
                    "Your <a href=\"{}\">schedule settings (# Games, # Division Games, and # Conference Games)</a> combined with your teams/divs/confs cannot be handled by the schedule generator, so instead it will generate round robin matchups between all your teams. Message from the schedule generator: \"{}\" <a href=\"https://{}/manual/customization/schedule-settings/\" rel=\"noopener noreferrer\" target=\"_blank\">More details.</a>",
                    helpers::league_url(&["settings"]),
                    warning_message,
                    WEBSITE_ROOT
                ),
                save_to_db: false,
            },
            conditions,
        );
    }

    team_ids
}

struct Team {
    season_attrs: SeasonAttributes,
    tid: i32,
}

struct SeasonAttributes {
    cid: i32,
    did: i32,
}

struct Event {
    event_type: String,
    text: String,
    save_to_db: bool,
}
