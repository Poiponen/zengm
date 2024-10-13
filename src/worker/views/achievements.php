require_once "../util.php";

function updateAchievements(
    $inputs, // Assuming $inputs is of type ViewInput
    $updateEvents, // Assuming $updateEvents is of type UpdateEvents
    $state, // Assuming $state is of type unknown
    $conditions // Assuming $conditions is of type Conditions
) {
    if (in_array("firstRun", $updateEvents) || in_array("account", $updateEvents)) {
        checkAccount($conditions);
        $achievements = achievement::getAll();

        return [
            'achievements' => $achievements,
        ];
    }
}
