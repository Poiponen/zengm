# This code is converted from TypeScript to Ruby.
require_relative '../../common'
require_relative '../util'

def update_account_update_card(inputs, update_events, state, conditions)
  if update_events.include?("firstRun") || update_events.include?("account")
    partial_top_menu = check_account(conditions)

    begin
      data = fetch_wrapper({
        url: "#{ACCOUNT_API_URL}/gold_card_info.php",
        method: "GET",
        data: {
          sport: ENV['SPORT'],
        },
        credentials: "include"
      })
      return {
        gold_cancelled: partial_top_menu[:goldCancelled],
        last_4: data[:last4],
        exp_month: data[:expMonth],
        exp_year: data[:expYear],
        username: partial_top_menu[:username]
      }
    rescue => err
      return {
        gold_cancelled: partial_top_menu[:goldCancelled],
        last_4: "????",
        exp_month: "??",
        exp_year: "????",
        username: partial_top_menu[:username]
      }
    end
  end
end

# Exporting the method as a module
module_function :update_account_update_card
