# Translated from TypeScript to Ruby
# This code utilizes standard Ruby syntax and conventions.

require_relative './new_league'

def update_exhibition
  default_settings = {
    **get_default_settings(),
    num_active_teams: nil
  }

  {
    default_settings: default_settings,
    real_team_info: get_real_team_info
  }
end

module_function :update_exhibition
