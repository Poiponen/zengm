module expansion_draft_module
  implicit none
contains

  function auto_protect(team_id) result(protected_player_ids)
    integer, intent(in) :: team_id
    integer, allocatable :: protected_player_ids(:)
    integer :: expansion_draft_phase, max_num_can_protect, i
    type(player), allocatable :: players(:)
    character(len=20) :: phase

    ! Retrieve the current expansion draft information
    expansion_draft_phase = g%get("expansionDraft")
    phase = g%get("phase")

    if (phase /= "EXPANSION_DRAFT" .or. expansion_draft_phase /= "protection") then
      call throw_error("Invalid expansion draft phase")
    end if

    ! Get all players for the given team
    players = idb%cache%players%index_get_all("playersByTid", team_id)
    max_num_can_protect = min(expansion_draft_phase%num_protected_players, size(players) - expansion_draft_phase%num_per_team)

    ! Sort players by their value in descending order and select the appropriate player IDs
    allocate(protected_player_ids(max_num_can_protect))
    do i = 1, max_num_can_protect
      protected_player_ids(i) = players(i)%pid
    end do

  end function auto_protect

end module expansion_draft_module
