;; Clojure code translation for TypeScript source code
(ns lottery.core
  (:require [lottery.log-action :refer [log-action]]
            [lottery.log-lottery-txt :refer [log-lottery-txt]]))

(defn log-lottery-chances
  [chances teams draft-picks-indexed & [conditions]]
  (doseq [index (range (count chances))]
    (when (< index (count teams))
      (let [original-tid (:tid (nth teams index))
            draft-pick (get-in draft-picks-indexed [original-tid 1])]
        (when draft-pick
          (let [tid (:tid draft-pick)
                txt (log-lottery-txt tid "chance" (nth chances index))]
            (log-action tid txt 0 conditions)))))))
