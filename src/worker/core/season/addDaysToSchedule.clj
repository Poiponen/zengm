;; Translated from TypeScript to Clojure
(ns my-game-schedule.core
  (:require [my-util :as util]))

(defn add-days-to-schedule
  [games & [existing-games]]
  (let [day-tids (atom #{})
        prev-day-all-star-game (atom false)
        prev-day-trade-deadline (atom false)
        day (atom 1)]
    
    ;; If there are other games already played this season, start after that day
    (when existing-games
      (let [season (util/g "season")]
        (doseq [game existing-games]
          (when (and (= (:season game) season)
                     (number? (:day game))
                     (>= (:day game) @day))
            (reset! day (inc (:day game)))))))
    
    (map (fn [game]
           (let [{:keys [awayTid homeTid]} game
                 all-star-game (= awayTid -2)
                 trade-deadline (= awayTid -3)]
             (when (or (contains? @day-tids homeTid)
                       (contains? @day-tids awayTid)
                       all-star-game
                       @prev-day-all-star-game
                       trade-deadline
                       @prev-day-trade-deadline)
               (swap! day inc)
               (reset! day-tids #{}))
             
             (swap! day-tids conj homeTid)
             (swap! day-tids conj awayTid)

             (reset! prev-day-all-star-game all-star-game)
             (reset! prev-day-trade-deadline trade-deadline)

             (assoc game :day @day)))
         games)))
