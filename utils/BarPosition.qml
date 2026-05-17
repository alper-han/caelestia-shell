pragma Singleton

import Quickshell

Singleton {
    function resolvedPosition(rawPosition): string {
        switch (rawPosition) {
        case "right":
            return "right";
        case "top":
            return "top";
        case "bottom":
            return "bottom";
        default:
            return "left";
        }
    }

    function isVertical(rawPosition): bool {
        const position = resolvedPosition(rawPosition);
        return position === "left" || position === "right";
    }

    function isHorizontal(rawPosition): bool {
        const position = resolvedPosition(rawPosition);
        return position === "top" || position === "bottom";
    }

    function isLeft(rawPosition): bool {
        return resolvedPosition(rawPosition) === "left";
    }

    function isRight(rawPosition): bool {
        return resolvedPosition(rawPosition) === "right";
    }

    function isTop(rawPosition): bool {
        return resolvedPosition(rawPosition) === "top";
    }

    function isBottom(rawPosition): bool {
        return resolvedPosition(rawPosition) === "bottom";
    }

    function oppositePosition(rawPosition): string {
        switch (resolvedPosition(rawPosition)) {
        case "right":
            return "left";
        case "top":
            return "bottom";
        case "bottom":
            return "top";
        default:
            return "right";
        }
    }

    function thicknessAxis(rawPosition): string {
        return isVertical(rawPosition) ? "width" : "height";
    }

    function mainCoord(rawPosition, x, y) {
        return isVertical(rawPosition) ? y : x;
    }

    function crossCoord(rawPosition, x, y) {
        return isVertical(rawPosition) ? x : y;
    }

    function edgeInset(rawPosition, thickness): var {
        const position = resolvedPosition(rawPosition);
        return {
            left: position === "left" ? thickness : 0,
            right: position === "right" ? thickness : 0,
            top: position === "top" ? thickness : 0,
            bottom: position === "bottom" ? thickness : 0,
        };
    }

    function isInEdgeArea(rawPosition, x, y, width, height, thickness): bool {
        switch (resolvedPosition(rawPosition)) {
        case "right":
            return x > width - thickness;
        case "top":
            return y < thickness;
        case "bottom":
            return y > height - thickness;
        default:
            return x < thickness;
        }
    }
}
