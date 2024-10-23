module GameSchedule
  implicit none
contains

  function addDaysToSchedule(games, existingGames) result(scheduledGames)
    type :: Game
      integer :: homeTid
      integer :: awayTid
      integer :: day
    end type Game

    type :: ScheduleGameWithoutKey
      integer :: homeTid
      integer :: awayTid
      integer :: day
    end type ScheduleGameWithoutKey

    type(Game), dimension(:), allocatable :: games
    type(Game), dimension(:), optional :: existingGames
    type(ScheduleGameWithoutKey), dimension(:), allocatable :: scheduledGames

    integer :: dayTids(100)  ! Assuming a maximum of 100 teams
    logical :: prevDayAllStarGame
    logical :: prevDayTradeDeadline
    integer :: day
    integer :: i, season

    prevDayAllStarGame = .false.
    prevDayTradeDeadline = .false.
    day = 1

    ! If there are other games already played this season, start after that day
    if (present(existingGames)) then
      season = g%get("season")
      do i = 1, size(existingGames)
        if (existingGames(i)%season == season .and. existingGames(i)%day >= day) then
          day = existingGames(i)%day + 1
        end if
      end do
    end if

    allocate(scheduledGames(size(games)))
    do i = 1, size(games)
      integer :: awayTid, homeTid
      logical :: allStarGame, tradeDeadline

      awayTid = games(i)%awayTid
      homeTid = games(i)%homeTid

      allStarGame = (awayTid == -2 .and. homeTid == -1)
      tradeDeadline = (awayTid == -3 .and. homeTid == -3)

      if (any(dayTids == homeTid) .or. any(dayTids == awayTid) .or. &
          allStarGame .or. prevDayAllStarGame .or. &
          tradeDeadline .or. prevDayTradeDeadline) then
        day = day + 1
        dayTids = 0  ! Clear the dayTids array
      end if

      dayTids(i) = homeTid
      dayTids(i+1) = awayTid

      prevDayAllStarGame = allStarGame
      prevDayTradeDeadline = tradeDeadline

      scheduledGames(i)%homeTid = homeTid
      scheduledGames(i)%awayTid = awayTid
      scheduledGames(i)%day = day
    end do
  end function addDaysToSchedule

end module GameSchedule
