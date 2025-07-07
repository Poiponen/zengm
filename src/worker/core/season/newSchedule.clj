(ns my-namespace
  (:require [common.index :refer [WEBSITE_ROOT]]
            [common.types :as types]
            [util.index :refer [g helpers log-event]]
            [newScheduleGood :refer [new-schedule-good]]))

(defn new-schedule [teams conditions]
  (let [{:keys [tids warning]} (new-schedule-good teams)]

    ;; Add trade deadline
    (let [trade-deadline (g/get "tradeDeadline")]
      (when (< trade-deadline 1)
        (let [index (Math/round (* (helpers/bound trade-deadline 0 1) (count tids)))]
          (assoc tids index [-3 -3]))))

    ;; Add an All-Star Game
    (let [all-star-game (g/get "allStarGame")]
      (when (and (not (nil? all-star-game)) (>= all-star-game 0))
        (let [index (Math/round (* (helpers/bound all-star-game 0 1) (count tids)))]
          (assoc tids index [-1 -2]))))

    (when (not (nil? warning))
      ;; console.log(g.get("season"), warning);
      (log-event
        {:type "info"
         :text (str "Your <a href=\"" (helpers/league-url ["settings"]) "\">schedule settings (# Games, # Division Games, and # Conference Games)</a> combined with your teams/divs/confs cannot be handled by the schedule generator, so instead it will generate round robin matchups between all your teams. Message from the schedule generator: \"" warning "\" <a href=\"https://" WEBSITE_ROOT "/manual/customization/schedule-settings/\" target=\"_blank\">More details.</a>")
         :save-to-db false}
        conditions))

    tids))
