import fuzzRating from "./fuzzRating.ts";
import { g } from "../../util/index.ts";
import type {
	MinimalPlayerRatings,
	Player,
	PlayerWithoutKey,
} from "../../../common/types.ts";
import valueCombineOvrPot from "./valueCombineOvrPot.ts";
import { bySport, isSport } from "../../../common/index.ts";

/**
 * Returns a numeric value for a given player, representing is general worth to a typical team
 * (i.e. ignoring how well he fits in with his teammates and the team's strategy/finances). It
 * is similar in scale to the overall and potential ratings of players (0-100), but it is based
 * on stats in addition to ratings. The main components are:
 *
 * 1. Recent stats: Avg of last 2 seasons' PER if min > 2000. Otherwise, scale by min / 2000 and
 *     use ratings to estimate the rest.
 * 2. Potential for improvement (or risk for decline): Based on age and potential rating.
 *
 * @memberOf core.player
 * @param {Object} p Player object.
 * @param {Object=} options Object containing several optional options:
 *     noPot: When true, don't include potential in the value calcuation (useful for roster
 *         ordering and game simulation). Default false.
 *     fuzz: When true, used fuzzed ratings (useful for roster ordering, draft prospect
 *         ordering). Default false.
 * @return {number} Value of the player, usually between 50 and 100 like overall and potential
 *     ratings.
 */
const value = (
	p: Player<MinimalPlayerRatings> | PlayerWithoutKey<MinimalPlayerRatings>,
	options: {
		fuzz?: boolean;
		noPot?: boolean;
		ovrMean: number;
		ovrStd: number;
	},
): number => {
	options.noPot = !!options.noPot;
	options.fuzz = !!options.fuzz;

	// Current ratings
	const pr: any = {}; // Start blank, add what we need

	// Latest season
	const ratings = p.ratings.at(-1)!;

	pr.pos = ratings.pos;

	// Fuzz?
	if (options.fuzz) {
		pr.ovr = fuzzRating(ratings.ovr, ratings.fuzz);
		pr.pot = fuzzRating(ratings.pot, ratings.fuzz);
	} else {
		pr.ovr = ratings.ovr;
		pr.pot = ratings.pot;
	}

	// Normalize ovr/pot, these are values for a typical random players league
	const defaultOvrMean = bySport({
		baseball: 47,
		basketball: 47,
		football: 48,
		hockey: 50,
	});
	const defaultOvrStd = bySport({
		baseball: 11,
		basketball: 10,
		football: 11,
		hockey: 11,
	});
	if (options.ovrStd > 0) {
		pr.ovr =
			((pr.ovr - options.ovrMean) / options.ovrStd) * defaultOvrStd +
			defaultOvrMean;
		pr.pot =
			((pr.pot - options.ovrMean) / options.ovrStd) * defaultOvrStd +
			defaultOvrMean;
	} else {
		pr.ovr = pr.ovr - options.ovrMean + defaultOvrMean;
		pr.pot = pr.pot - options.ovrMean + defaultOvrMean;
	}

	// From linear regression OVR ~ PER
	const slope = 1.531;
	const intercept = 31.693;

	// 1. Account for stats (and current ratings if not enough stats)
	const ps = p.stats.filter((playerStats) => !playerStats.playoffs);
	let current = pr.ovr;

	// No stats at all? Just look at ratings more, then.
	if (isSport("basketball") && ps.length > 0) {
		const ps1 = ps.at(-1); // Most recent stats

		// PER may be undefined for exhibition game players from old historical seasons. See ps2 check below too.
		if (Object.hasOwn(ps1, "per")) {
			if (ps.length === 1 || ps1.min >= 2000) {
				// Only one year of stats
				current = intercept + slope * ps1.per;

				if (ps1.min < 2000) {
					current = (current * ps1.min) / 2000 + pr.ovr * (1 - ps1.min / 2000);
				}
			} else {
				// Two most recent seasons
				const ps2 = ps.at(-2)!;

				if (Object.hasOwn(ps2, "per")) {
					if (ps1.min + ps2.min > 0) {
						current =
							intercept +
							(slope * (ps1.per * ps1.min + ps2.per * ps2.min)) /
								(ps1.min + ps2.min);

						if (ps1.min + ps2.min < 2000) {
							current =
								(current * (ps1.min + ps2.min)) / 2000 +
								pr.ovr * (1 - (ps1.min + ps2.min) / 2000);
						}
					}
				}
			}

			current = 0.8 * pr.ovr + 0.2 * current; // Include some part of the ratings
		}
	}

	// 2. Potential
	let potential = pr.pot;

	if (isSport("football")) {
		if (pr.pos === "QB") {
			current *= 1.1;
			potential *= 1.1;
		} else if (pr.pos === "K" || pr.pos === "P") {
			current *= 0.7;
			potential *= 0.7;
		}
	}

	// Short circuit if we don't care about potential
	if (options.noPot) {
		return current;
	}

	// If performance is already exceeding predicted potential, just use that
	if (current >= potential) {
		potential = current;
	}

	let age;

	if (p.draft.year > g.get("season")) {
		// Draft prospect
		age = p.draft.year - p.born.year;
	} else {
		age = g.get("season") - p.born.year;
	}

	// Otherwise, combine based on age
	const combined = valueCombineOvrPot(current, potential, age);

	return combined < 0 ? Number.MIN_VALUE : combined;
};

export default value;
