import { afterAll, assert, beforeAll, test } from "vitest";
import { PLAYER } from "../../../common/index.ts";
import testHelpers from "../../../test/helpers.ts";
import { draft } from "../index.ts";
import { idb } from "../../db/index.ts";
import { g } from "../../util/index.ts";
import { getDraftTids, loadTeamSeasons } from "./testHelpers.ts";
import { DEFAULT_LEVEL } from "../../../common/budgetLevels.ts";

const testRunPicks = async (numNow: number, numTotal: number) => {
	const pids = await draft.runPicks({ type: "untilYourNextPick" });
	assert.strictEqual(pids.length, numNow);
	const players = (
		await idb.cache.players.indexGetAll("playersByDraftYearRetiredYear", [
			[g.get("season")],
			[g.get("season"), Infinity],
		])
	).filter((p) => p.tid === PLAYER.UNDRAFTED);
	assert.strictEqual(players.length, 70 - numTotal);
};

let userPick1: number;
let userPick2: number;

const testDraftUser = async (round: number) => {
	const draftPicks = await draft.getOrder();
	const dp = draftPicks.shift();
	if (!dp) {
		throw new Error("No draft pick");
	}

	assert.strictEqual(dp.round, round);

	if (round === 1) {
		assert.strictEqual(dp.pick, userPick1);
	} else {
		assert.strictEqual(dp.pick, userPick2 - 30);
	}

	assert.strictEqual(dp.tid, g.get("userTid"));
	const players = (
		await idb.cache.players.indexGetAll("playersByDraftYearRetiredYear", [
			[g.get("season")],
			[g.get("season"), Infinity],
		])
	).filter((p) => p.tid === PLAYER.UNDRAFTED);
	const p = players[0]!;
	await draft.selectPlayer(dp, p.pid);
	assert.strictEqual(p.tid, g.get("userTid"));
};

beforeAll(async () => {
	await loadTeamSeasons();
	idb.league = testHelpers.mockIDBLeague();
	await draft.genPlayers(g.get("season"), DEFAULT_LEVEL);
	const draftTids = await getDraftTids();
	userPick1 = draftTids.indexOf(g.get("userTid")) + 1;
	userPick2 = draftTids.lastIndexOf(g.get("userTid")) + 1;
});
afterAll(() => {
	// @ts-expect-error
	idb.league = undefined;
});

test("draft players before the user's team first round pick", () => {
	return testRunPicks(userPick1 - 1, userPick1 - 1);
});

test("then allow the user to draft in the first round", () => {
	return testDraftUser(1);
});

test("when called again after the user drafts, should draft players before the user's second round pick comes up", () => {
	return testRunPicks(userPick2 - userPick1 - 1, userPick2 - 1);
});

test("then allow the user to draft in the second round", () => {
	return testDraftUser(2);
});

test("when called again after the user drafts, should draft more players to finish the draft", () => {
	const numAfter = 60 - userPick2;
	return testRunPicks(numAfter, userPick2 + numAfter);
});
