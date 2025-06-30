;; Return the seeds (0 indexed) for the matchups, in order (undefined is a bye)
(defn gen-playoff-seeds
  [num-playoff-teams num-playoff-bytes]
  (let [num-rounds (Math/log2 (+ num-playoff-teams num-playoff-bytes))]
    (when (not (integer? num-rounds))
      (throw (Exception. (str "Invalid genSeeds input: " num-playoff-teams " teams and " num-playoff-bytes " byes")))))

    ;; Handle byes - replace lowest seeds with nil
    (let [bye-seeds (vec (map #(+ num-playoff-teams %) (range num-playoff-bytes)))]
      (letfn [(add-matchup [current-round team1 max-team-in-round]
                (when (nil? team1)
                  (throw (Exception. "Invalid type")))
                (let [other-team (- max-team-in-round team1)]
                  (conj current-round [team1 (if (some #{other-team} bye-seeds) nil other-team)])))]

        ;; Grow from the final matchup
        (loop [last-round [[0 1]]]
          (if (> (- num-rounds 1) (count last-round))
            (let [num-teams-in-round (* (count last-round) 4)
                  max-team-in-round (dec num-teams-in-round)
                  current-round []]
              (reduce (fn [acc matchup]
                        (let [swap-order (and (odd? (/ (count acc) 2)) (some? (second matchup)))]
                          (-> acc
                              (add-matchup (if swap-order (second matchup) (first matchup)) max-team-in-round)
                              (add-matchup (if swap-order (first matchup) (second matchup)) max-team-in-round))))
                      current-round
                      last-round))
            last-round))))))

(def gen-playoff-seeds)
