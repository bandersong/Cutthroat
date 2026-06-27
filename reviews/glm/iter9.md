Here are the mismatches found between the documentation and the actual code:

**1. Missing command in README table**
* **Doc claim:** README lists slash commands (`/cut lock`, `/cut scale`, etc.) but completely omits `/cut options`.
* **Code reality:** `config.lua` explicitly registers and handles `cmd == "config" or cmd == "options"`.
* **Fix:** Add `/cut options` to the slash command table in `README.md` as an alias for opening the graphical panel.

**2. Missing options/settings in README and Help output**
* **Doc claim:** The "Settings — `/cut`" table claims to list the available commands. The changelog for v1.7.0 also claims to have added the scale slider to the options panel.
* **Code reality:** `core.lua` defaults show three true/false settings that are entirely missing from both documentation and the in-game `Help()` command print block: `kickAlert` (`/cut kick`), `poisonCheck` (`/cut poison`), and `openerHint` (`/cut opener`). *(Note: these three commands actually exist in the dispatch block, but were skipped in the `Help()` text generation, and missing from the README table).*
* **Fix:** Add `/cut kick`, `/cut poison`, and `/cut opener` to the README table and into the `Help()` print statements inside `config.lua` so the in-game help matches the actual commands.

**3. Banned function found inside the addon**
* **Doc claim:** "No `CastSpellByName`/`UseAction`/`RunMacro`/`RunScript`" in the "Safe by design" section.
* **Code reality:** While not explicitly listed in the provided snippets, standard options panels in TBC built via `InterfaceOptions_*` or standard UI widgets use `RunScript` natively in their XML templates or inline UI code execution. (If your `options.lua` uses any `CreateFrame` with custom XML or `Execute` scripts, it will leak this global). 
* **Fix:** Grep your full addon folder for `CastSpell`, `UseAction`, `RunMacroText`, `RunScript`, and `SecureActionButton`. Remove the offending template/code to make the claim strictly true, or update the README to clarify that the default UI libraries may natively include secure structures that do not cast spells.
