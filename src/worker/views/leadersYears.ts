import { idb } from "../db/index.ts";
import { g } from "../util/index.ts";
import type { UpdateEvents, ViewInput } from "../../common/types.ts";
import { groupByUnique, range } from "../../common/utils.ts";
import {
	GamesPlayedCache,
	getCategoriesAndStats,
	iterateAllPlayers,
	type Leader,
	leadersAddFirstNameShort,
	playerMeetsCategoryRequirements,
} from "./leaders.ts";

const NUM_LEADERS = 10;

type MyLeader = Omit<
	Leader,
	| "abbrev"
	| "jerseyNumber"
	| "pos"
	| "injury"
	| "retiredYear"
	| "skills"
	| "tid"
	| "season"
>;

const updateLeadersYears = async (
	inputs: ViewInput<"leadersYears">,
	updateEvents: UpdateEvents,
	state: any,
) => {
	// Respond to watchList in case players are listed twice in different categories
	if (
		updateEvents.includes("firstRun") ||
		updateEvents.includes("watchList") ||
		inputs.stat !== state.stat ||
		inputs.playoffs !== state.playoffs ||
		inputs.statType !== state.statType
	) {
		const { categories: allCategories } = getCategoriesAndStats();
		const allStats = allCategories.map((cat) => cat.stat);

		const { categories, stats } = getCategoriesAndStats(inputs.stat);

		const cat = categories[0]!;

		const seasons = range(g.get("startingSeason"), g.get("season") + 1);

		let allLeaders = seasons
			.map((season) => ({
				season,
				linkSeason: false,
				leaders: [] as MyLeader[],
			}))
			.reverse();

		for (const row of allLeaders) {
			const awards = await idb.getCopy.awards({
				season: row.season,
			});
			if (awards) {
				row.linkSeason = true;
			}
		}

		const leadersBySeason = groupByUnique(allLeaders, "season");

		const gamesPlayedCache = new GamesPlayedCache();
		if (inputs.playoffs === "combined") {
			await gamesPlayedCache.loadSeasons(seasons, false);
			await gamesPlayedCache.loadSeasons(seasons, true);
		} else {
			await gamesPlayedCache.loadSeasons(
				seasons,
				inputs.playoffs === "playoffs",
			);
		}

		await iterateAllPlayers("all", async (pRaw, season) => {
			if (typeof season !== "number") {
				throw new Error("Invalid season");
			}

			const current = leadersBySeason[season];
			if (!current) {
				return;
			}

			const p = await idb.getCopy.playersPlus(pRaw, {
				attrs: [
					"pid",
					"firstName",
					"lastName",
					"injury",
					"watch",
					"jerseyNumber",
					"hof",
					"retiredYear",
				],
				ratings: ["skills", "pos"],
				stats: ["abbrev", "tid", ...stats],
				season,
				playoffs: inputs.playoffs === "playoffs",
				regularSeason: inputs.playoffs === "regularSeason",
				combined: inputs.playoffs === "combined",
				mergeStats: "totOnly",
				statType: inputs.statType,
			});
			if (!p) {
				return;
			}

			const value = p.stats[cat.stat];
			if (value === undefined) {
				// value should only be undefined in historical data before certain stats were tracked
				return;
			}

			const lastValue = current.leaders.at(-1)?.stat;
			if (
				lastValue !== undefined &&
				current.leaders.length >= NUM_LEADERS &&
				((cat.sortAscending && value > lastValue) ||
					(!cat.sortAscending && value < lastValue))
			) {
				// Value is not good enough for the top 10
				return;
			}

			const pass = playerMeetsCategoryRequirements({
				career: false,
				cat,
				gamesPlayedCache,
				p,
				playerStats: p.stats,
				seasonType: inputs.playoffs,
				season,
				statType: inputs.statType,
			});

			if (pass) {
				const leader = {
					hof: p.hof,
					key: p.pid,
					firstName: p.firstName,
					lastName: p.lastName,
					pid: p.pid,
					stat: p.stats[cat.stat],
					userTeam: g.get("userTid", season) === p.stats.tid,
					watch: p.watch,
				};

				current.leaders = current.leaders.slice(0, NUM_LEADERS - 1);
				current.leaders.push(leader);
				if (cat.sortAscending) {
					current.leaders.sort((a, b) => a.stat - b.stat);
				} else {
					current.leaders.sort((a, b) => b.stat - a.stat);
				}
			}
		});

		allLeaders = allLeaders.filter((row) => row.leaders.length > 0);

		return {
			allLeaders: leadersAddFirstNameShort(allLeaders),
			playoffs: inputs.playoffs,
			stat: inputs.stat,
			statType: inputs.statType,
			stats: allStats,
		};
	}
};

export default updateLeadersYears;
