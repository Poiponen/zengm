import { NUM_STARTING_PITCHERS } from "../../../common/constants.baseball";
import { random } from "../../util";
import type { PlayerGameSim } from "./types";

const CLOSER_INDEX = NUM_STARTING_PITCHERS;

export const getStartingPitcher = (pitchers: PlayerGameSim[]) => {
	// First pass - look for starting pitcher with no fatigue
	let firstFound;
	for (let i = 0; i < pitchers.length; i++) {
		const p = pitchers[i];
		if (p.pFatigue === 0 && !p.injured) {
			// Add some randomness, to get lower starters some extra starts
			if (Math.random() < 0.8) {
				return p;
			}

			firstFound = p;
		}

		if (i === NUM_STARTING_PITCHERS - 1) {
			break;
		}
	}

	if (firstFound) {
		// If randomness didn't turn up another candidate
		return firstFound;
	}

	// Second pass - reliever with no fatigue
	for (let i = CLOSER_INDEX + 1; i < pitchers.length; i++) {
		const p = pitchers[i];
		if (p.pFatigue === 0 && !p.injured) {
			return p;
		}
	}

	// Third pass - look for slightly tired starting pitcher
	for (let i = 0; i < pitchers.length; i++) {
		const p = pitchers[i];
		if (p.pFatigue <= 30 && !p.injured) {
			return p;
		}

		if (i === NUM_STARTING_PITCHERS - 1) {
			break;
		}
	}

	// Fourth pass - tired reliever
	for (let i = CLOSER_INDEX + 1; i < pitchers.length; i++) {
		const p = pitchers[i];
		if (p.pFatigue <= 30 && !p.injured) {
			return p;
		}
	}

	// Fifth pass - anybody
	let p = random.choice(pitchers.filter(p => !p.injured));
	if (!p) {
		p = random.choice(pitchers);
	}

	if (!p) {
		throw new Error("Should never happen");
	}

	return p;
};
