# Flash Inspect

[![Tests](https://github.com/flshmodels/flash-inspect/actions/workflows/test.yml/badge.svg)](https://github.com/flshmodels/flash-inspect/actions/workflows/test.yml)

Find unanchored scenery and missing or duplicate interaction IDs in Studio. Click a result to select the object, then decide whether it needs fixing.

## What it checks

| Rule | When it reports a finding |
| --- | --- |
| STATIC_UNANCHORED | A BasePart is unanchored and it or an ancestor has the StaticScenery tag. |
| INVALID_INTERACTION_ID | An object tagged Interactable lacks a valid InteractionId string attribute. |
| DUPLICATE_INTERACTION_ID | Two or more Interactable objects in the scanned scope share a valid ID. Every affected object is listed. |

IDs are case-sensitive: a letter first, then letters, digits, underscores or hyphens; maximum 64 ASCII characters. Interactable tags apply to the tagged object, while StaticScenery applies to descendants too. An unanchored welded part may be intentional; a finding is a prompt to review it, not proof of a bug.

## Setup

1. Download this repository and find **FlashInspect.rbxmx**. It contains the same source as the src folder.
2. Insert that model into a separate Studio test place using **Insert from File** in Explorer. The root is a Script named FlashInspect with three child ModuleScripts.
3. Select the root Script and use Studio's **Save as Local Plugin** action. Do this in edit mode, before playing the place.
4. Remove the imported source Script from the place after saving the plugin, so it is not used as a game Script. Open **Flash Inspect → Inspect** from the Plugins toolbar.

The plugin runs in Studio edit mode. To rebuild the model after editing its source, run `python build.py` with Python 3.11 or newer. No extra Python packages are needed.

## Using the plugin

Add tags and attributes with Studio's Properties or tag tools. Tag a scenery Model **StaticScenery**, or tag a door **Interactable** and give it a string attribute **InteractionId**, such as Door_Main.

**Scan Workspace** checks Workspace and its descendants. **Scan selection** checks selected objects and their descendants; overlapping selections are deduplicated. A tag on an ancestor outside the selection still determines whether a part counts as static. Duplicate IDs outside the scanned scope cannot be detected.

The panel reports the object count, total findings and up to 300 clickable results. Scans over 25,000 objects stop with an explanation instead of showing an incomplete success. Results are snapshots: rescan after editing tags or attributes. Clicking a deleted result asks you to rescan. Play-mode scans are refused.

Change tag names, the attribute name or scan/display limits in `src/Config.luau`, then rebuild and save the local plugin again. The header uses the default tag names; update that text if you rename them.

## Limits

It does not read script source, detect exploits, find every broken reference, measure performance, or modify your place. It has no automatic fixes. IDs only have meaning if your own gameplay code uses them.

## Related tools

[Roblox Tag Editor](https://github.com/tiffany352/Roblox-Tag-Editor) manages CollectionService tags. You can also use Studio's tag tools to set up the tags that Flash Inspect checks.

## Tests

Luau tests cover inherited tags, invalid and duplicate IDs, overlapping selections and scan limits using mock objects in Lune. Python checks that the packaged model matches the source. GitHub Actions rebuilds the model to catch stale output and platform differences.

The dock widget and local-plugin installation have not been tested in a live Studio session.

MIT licensed. See [LICENSE](LICENSE).
