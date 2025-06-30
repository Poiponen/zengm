(ns your-namespace
  (:require [your-db-namespace :as db]))

;; Get an array of games from the schedule.
;;
;; options - a map containing:
;;   :ot An IndexedDB object store or transaction on schedule; if nil is passed, then a new transaction will be used.
;;   :oneDay Return just one day (true) or all days (false). Default false.
;; 
;; Returns a promise that resolves to the requested schedule array.
(defn get-schedule
  ([one-day]
   (let [schedule (db/idb-cache-schedule-get-all)
         partial-schedule (atom [])
         tids (atom #{})]
     (if (empty? schedule)
       schedule
       (if one-day
         (do
           (doseq [game schedule]
             (when (= (:day game) (:day (first schedule)))
               (when (not (or (contains? @tids (:homeTid game))
                              (contains? @tids (:awayTid game))))
                 (when (or (neg? (:homeTid game))
                           (neg? (:awayTid game)))
                   (when (pos? (count @tids))
                     (recur)))
                 (swap! partial-schedule conj game)
                 (swap! tids conj (:homeTid game) (:awayTid game))))
           @partial-schedule)
         schedule))))
  ([]
   (get-schedule false)))

(def get-schedule-default (partial get-schedule false))
