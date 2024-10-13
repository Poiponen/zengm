# Translated from TypeScript to Ruby
require_relative './autoPlay'
require_relative '../../util'

def init_auto_play(conditions)
  if g.get("gameOver")
    log_event(
      {
        type: "error",
        text: "You can't auto play while you're fired!",
        show_notification: true,
        persistent: true,
        save_to_db: false
      },
      conditions
    )
    return false
  end

  result = to_ui(
    "autoPlayDialog",
    [g.get("season"), g.get("repeatSeason") ? true : false],
    conditions
  )

  return false unless result

  season = result.season.to_i
  phase = result.phase.to_i

  if season > g.get("season") || (season == g.get("season") && phase > g.get("phase"))
    local.auto_play_until = {
      season: season,
      phase: phase,
      start: Time.now.to_i
    }
    auto_play(conditions)
  else
    return false
  end
end

# No explicit export in Ruby, but you can call init_auto_play directly.
