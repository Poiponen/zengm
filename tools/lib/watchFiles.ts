import chokidar from "chokidar";
import * as build from "./buildFuncs";

// Would be better to only copy individual files on update, but this is fast enough

const watchFiles = (
	updateStart: (filename: string) => void,
	updateEnd: (filename: string) => void,
	updateError: (filename: string, error: Error) => void,
) => {
	const watcher = chokidar.watch(
		["public", "data", "node_modules/flag-icon-css"],
		{},
	);

	const outFilename = "static files";

	const buildWatchFiles = () => {
		try {
			updateStart(outFilename);

			build.copyFiles(true);

			const rev = build.genRev();
			build.setTimestamps(rev, true);
			//build.minifyIndexHTML();

			updateEnd(outFilename);
		} catch (error) {
			updateError(outFilename, error);
		}
	};

	build.reset();
	buildWatchFiles();

	watcher.on("change", buildWatchFiles);
};

export default watchFiles;
