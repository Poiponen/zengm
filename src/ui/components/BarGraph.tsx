import type { CSSProperties } from "react";
import { OverlayTrigger, Tooltip } from "react-bootstrap";

/**
 * Bar plots, both stacked and normal.
 *
 * Displays simple and elegant bar plots that are just series of rectangles with no visible text that completely fill up a container div. When hovering over a bar, a tooltip appears with a complete annotation.
 *
 * CSS: Set the size of your bar graph (.my-plot here) and specify your colors. These colors were taken from Bootstrap. You only need as many colors as you have stacked components in your bar graphs (so, just .bar-graph-1 is used if you aren't stacking - the exception to this rule is that bar-graph-6 is used for negative values).
 *
 *     .my-plot { height: 80px; }
 *     .bar-graph-1 { background-color: #049cdb; }
 *     .bar-graph-2 { background-color: #f89406; }
 *     .bar-graph-3 { background-color: #9d261d; }
 *     .bar-graph-4 { background-color: #ffc40d; }
 *     .bar-graph-5 { background-color: #7a43b6; }
 *     .bar-graph-6 { background-color: #46a546; }
 *     .bar-graph-7 { background-color: #c3325f; }
 */

// Default scale for bar chart. This finds the max and min values in the data, adds 10% in each direction so you don't end up with tiny slivers, and then expands the upper/lower lims to 0 if 0 wasn't already in the range.
const defaultYlim = <Y extends string[], Row extends Record<Y[number], number>>(
	data: Row[],
	y: Y,
): [number, number] => {
	const values: number[] = data.map(row => {
		// If stacked, add up all the components
		let value = 0;
		for (const key of y) {
			value += row[key];
		}
		return value;
	});

	let min = Math.min(...values);
	let max = Math.max(...values);

	// Add on some padding
	min -= 0.1 * (max - min);
	max += 0.1 * (max - min); // Make sure 0 is in range

	if (min > 0) {
		min = 0;
	}

	if (max < 0) {
		max = 0;
	}

	// For stacked plots, min is always 0
	if (y.length > 1) {
		min = 0;
	}

	return [min, max];
};

const scale = (val: number, ylim: [number, number]) => {
	if (val > ylim[1]) {
		return 100;
	}

	if (val < ylim[0]) {
		return 0;
	}

	return ((val - ylim[0]) / (ylim[1] - ylim[0])) * 100;
};

const Block = ({
	className,
	style,
	tooltip,
}: {
	className: string;
	style: CSSProperties;
	tooltip: string | undefined;
}) => {
	if (tooltip === undefined) {
		return <div className={className} style={style} />;
	}
	return (
		<OverlayTrigger
			overlay={<Tooltip id="bar-graph-tooltip">{tooltip}</Tooltip>}
		>
			<div className={className} style={style} />
		</OverlayTrigger>
	);
};

const BarGraph = <Row extends unknown, Y extends (keyof Row)[]>({
	data,
	y,
	tooltip,
	ylim = defaultYlim(data, y),
	classNameOverride,
}: {
	data: Row[];
	y: Y;
	tooltip?: (row: Row, y: Y[number]) => string;
	ylim?: [number, number];
	classNameOverride?: (row: Row) => string | undefined;
}) => {
	const gap = 2; // Gap between bars, in pixels

	const numBars = data.length;

	if (numBars === 0) {
		return null;
	}

	const widthPct = 100 / numBars;

	const scaled = data.map(row => y.map(key => scale(row[key], ylim)));

	// Draw bars
	const bars = [];
	for (let j = 0; j < scaled.length; j++) {
		let offset = 0;
		for (let i = 0; i < scaled[j].length; i++) {
			if (i > 0) {
				offset += scaled[j][i - 1];
			}

			bars.push(
				<Block
					key={`${i}.${j}`}
					className={classNameOverride?.(data[j]) ?? `bar-graph-${i + 1}`}
					style={{
						marginLeft: `${gap}px`,
						position: "absolute",
						bottom: `${offset}%`,
						height: `${scaled[j][i]}%`,
						left: `${j * widthPct}%`,
						width: `calc(${widthPct}% - ${gap}px)`,
					}}
					tooltip={tooltip?.(data[j], y[i])}
				/>,
			);
		}
	}

	return (
		<div
			style={{
				height: "100%",
				marginLeft: `-${gap}px`,
				position: "relative",
			}}
		>
			{bars}
		</div>
	);
};

export default BarGraph;
