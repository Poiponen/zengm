# Translated from TypeScript to Ruby
# This code uses the Ruby standard library.

GRACE_PERIOD = 60 * 60 * 24 * 3

def update_account(inputs, update_events, state, conditions)
  if update_events.include?("firstRun") || update_events.include?("account")
    partial_top_menu = check_account(conditions)
    logged_in = !partial_top_menu[:username].nil? && !partial_top_menu[:username].empty?
    gold_until_date = Time.at(partial_top_menu[:goldUntil])
    gold_until_date_string = gold_until_date.strftime("%a %b %d %Y")
    current_timestamp = (Time.now.to_i - GRACE_PERIOD)
    show_gold_active = logged_in && !partial_top_menu[:goldCancelled] && current_timestamp < partial_top_menu[:goldUntil]
    show_gold_cancelled = logged_in && partial_top_menu[:goldCancelled] && current_timestamp < partial_top_menu[:goldUntil]
    show_gold_pitch = !logged_in || !show_gold_active

    return {
      email: partial_top_menu[:email],
      gold_message: inputs[:goldMessage],
      gold_success: inputs[:goldSuccess],
      gold_until_date_string: gold_until_date_string,
      logged_in: logged_in,
      show_gold_active: show_gold_active,
      show_gold_cancelled: show_gold_cancelled,
      show_gold_pitch: show_gold_pitch,
      username: partial_top_menu[:username]
    }
  end
end
