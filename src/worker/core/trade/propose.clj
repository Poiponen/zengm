;; This code is translated from TypeScript to Clojure

(ns core.trade
  (:require [common :refer [PHASE]]
            [team :refer :all]
            [util :refer [g]]
            [clear :refer [clear]]
            [process-trade :refer [process-trade]]
            [summary :refer [summary]]
            [get :refer [get]]
            [db :refer [idb]]))

;; 
;; Proposes the current trade in the database.
;; 
;; Before proposing the trade, the trade is validated to ensure that all player IDs match up with team IDs.
;; 
;; @param force-trade When true (like in God Mode), this trade is accepted regardless of the AI
;; @return A promise that resolves to a vector. The first element is a boolean for whether the trade was accepted or not. The second element is a string containing a message to be displayed to the user.
(defn propose
  ([force-trade]
   (let [phase (g/get "phase")]
     (if (and (>= phase PHASE/AFTER_TRADE_DEADLINE)
              (<= phase PHASE/PLAYOFFS))
       [false (str "Error! You're not allowed to make trades "
                   (if (= phase PHASE/AFTER_TRADE_DEADLINE)
                     "after the trade deadline"
                     "now"))]
       (let [{:keys [teams]} (await (get))
             tids [(-> teams first :tid) (-> teams second :tid)]
             pids [(-> teams first :pids) (-> teams second :pids)]
             dpids [(-> teams first :dpids) (-> teams second :dpids)]
             summary-result (await (summary teams))
             warning (:warning summary-result)]
         (if (and warning (not force-trade))
           [false nil]
           (let [outcome "rejected"
                 dv (await (team/value-change
                             (-> teams second :tid)
                             (-> teams first :pids)
                             (-> teams second :pids)
                             (-> teams first :dpids)
                             (-> teams second :dpids)
                             nil
                             (g/get "userTid")))]
             (if (or (> dv 0) force-trade)
               (do
                 (def outcome "accepted")
                 (await (process-trade tids pids dpids)))
               (if (= outcome "accepted")
                 (do
                   (await (clear))
                   (doseq [tid tids]
                     (let [t (await (get-in idb/cache.teams [tid]))
                           only-new-players (and (some #(= tid %) (g/get "userTids"))
                                                 t
                                                 (not (:keepRosterSorted t)))]
                       (await (team/roster-auto-sort tid only-new-players))))
                   [true "Trade accepted! \"Nice doing business with you!\""])
                 (let [message (cond
                                 (> dv -2) "Close, but not quite good enough."
                                 (> dv -5) "That's not a good deal for me."
                                 :else "What, are you crazy?!")]
                   [false (str "Trade rejected! \"" message "\"")])))))))))

(defn propose-default []
  (propose false))
