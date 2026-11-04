-- ExAI Brain v2.1
-- Offline, rule-based assistant for ExA Client and Luanti.
-- Place this file beside tab_exai.lua in builtin/mainmenu/.
-- No API keys, network access, browser, or external libraries are required.

local brain = {}

local function trim(s)
    s = tostring(s or "")
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalize(s)
    s = string.lower(trim(s))
    s = s:gsub("[%c]", " ")
    s = s:gsub("[^%w%s_%-]", " ")
    s = s:gsub("%s+", " ")
    return s
end

local function contains_any(text, words)
    local i
    for i = 1, #words do
        if text:find(words[i], 1, true) then
            return true
        end
    end
    return false
end

local function starts_with(text, prefix)
    return text:sub(1, #prefix) == prefix
end

local knowledge = {
    {
        id = "identity",
        priority = 100,
        keys = {"who are you", "what are you", "your name", "introduce yourself"},
        answer = "I'm ExAI, the built-in offline assistant for ExA Client. I run locally using Lua rules and a knowledge base, so I don't need an API key or an internet connection. I can help with Luanti, ExA Client, Lua modding, Android builds, and troubleshooting."
    },
    {
        id = "capabilities",
        priority = 95,
        keys = {"what can you do", "your features", "your capabilities", "how can you help"},
        answer = "I can explain Luanti gameplay and settings, guide you through Lua mod development, help understand formspecs and callbacks, explain Android APK/AAB builds, and troubleshoot common errors. I'm an offline rule-based assistant, not a cloud language model, so detailed or unfamiliar questions may need a more specific wording."
    },
    {
        id = "luanti",
        priority = 90,
        keys = {"luanti", "minetest", "voxel game", "voxel sandbox"},
        answer = "Luanti (formerly known as Minetest) is an open-source voxel game engine. It supports worlds made from nodes, mods written in Lua, texture packs, multiplayer servers, and different games. A game defines the overall experience, while mods add or change features. ExA Client is based on this Luanti ecosystem."
    },
    {
        id = "game_vs_engine",
        priority = 84,
        keys = {"game vs engine", "difference between game and engine", "what is a game in luanti"},
        answer = "In Luanti, the engine provides the core systems: rendering, maps, networking, formspecs, and the Lua API. A game supplies the actual gameplay, such as default items, nodes, crafting, and rules. Mods can extend either a game or a world, depending on how they are installed."
    },
    {
        id = "worlds",
        priority = 75,
        keys = {"world", "worlds", "map", "mapgen", "map generation", "seed"},
        answer = "A Luanti world stores its map, player data, settings, and world-specific environment. A seed influences procedural map generation. Mapgen creates terrain such as caves, hills, and landforms. Back up a world folder before testing unfamiliar mods or changing major world settings."
    },
    {
        id = "biomes",
        priority = 65,
        keys = {"biome", "biomes", "forest", "desert", "snow biome"},
        answer = "Biomes describe different environmental regions in a generated world. They can define terrain, heat and humidity ranges, nodes, decorations, and other map-generation properties. A game's mapgen configuration and registered biome definitions determine which biomes appear."
    },
    {
        id = "nodes",
        priority = 82,
        keys = {"node", "nodes", "block", "blocks", "register_node"},
        answer = "A node is a placeable map element in Luanti. Mods commonly register nodes with minetest.register_node(name, definition). The definition can include description, tiles, groups, sounds, and interaction callbacks. Node names should use a unique mod namespace, for example mymod:blue_block, to avoid collisions."
    },
    {
        id = "items",
        priority = 78,
        keys = {"item", "items", "register_craftitem", "craft item"},
        answer = "A craft item is an inventory item that is not itself a placeable node. Mods register one with minetest.register_craftitem(name, definition). Its definition can include description, inventory_image, stack_max, groups, and callbacks such as on_use."
    },
    {
        id = "tools",
        priority = 72,
        keys = {"tool", "tools", "pickaxe", "shovel", "axe", "register_tool"},
        answer = "Tools are registered with minetest.register_tool. Their tool_capabilities can define digging times, damage groups, and supported node groups. Balance tool capabilities carefully so a tool behaves consistently with the game's intended progression."
    },
    {
        id = "crafting",
        priority = 72,
        keys = {"crafting", "craft recipe", "craftitem", "register_craft", "recipe"},
        answer = "Crafting recipes are registered with minetest.register_craft. Common recipe types include normal shaped recipes, shapeless recipes, cooking, and fuel. Recipe item names must match registered item or node names. Check the game's existing recipes to avoid accidental conflicts."
    },
    {
        id = "mod_structure",
        priority = 86,
        keys = {"mod structure", "mod folder", "create a mod", "new mod", "mod.conf"},
        answer = "A basic Luanti mod usually has a folder containing init.lua and mod.conf. The mod.conf file declares metadata such as name, description, and optional dependencies. init.lua contains the mod's Lua code. Keep textures in a textures/ directory and use namespaced item IDs such as example:stone."
    },
    {
        id = "init_lua",
        priority = 88,
        keys = {"init.lua", "init lua", "main lua file"},
        answer = "In a Luanti mod, init.lua is normally the entry point loaded by the engine. It is used to register nodes, items, tools, entities, callbacks, and other features. Keep code organized into separate Lua files as a mod grows, and load them with dofile using paths relative to the mod directory."
    },
    {
        id = "mod_conf",
        priority = 80,
        keys = {"mod.conf", "depends", "optional_depends", "mod dependencies"},
        answer = "mod.conf stores mod metadata and dependency information. Common fields include name, description, depends, and optional_depends. Required dependencies must be available before the mod loads. Use optional dependencies only when your mod can still work without them."
    },
    {
        id = "lua",
        priority = 88,
        keys = {"lua", "lua language", "lua programming", "learn lua"},
        answer = "Lua is a lightweight scripting language used extensively by Luanti mods and parts of its main menu. Important basics include local variables, tables, functions, loops, conditionals, and modules. Prefer local variables to avoid polluting global state. Luanti's embedded Lua environment may differ from the newest standalone Lua release, so check API compatibility."
    },
    {
        id = "callbacks",
        priority = 78,
        keys = {"callback", "callbacks", "register_on", "on_joinplayer", "on_leaveplayer"},
        answer = "Callbacks let a mod react to engine events. Examples include registering a callback for a player joining, leaving, dying, or interacting with a node. Use the exact callback name and signature documented by the Luanti API for your target version. Avoid doing expensive work every frame or every globalstep."
    },
    {
        id = "globalstep",
        priority = 70,
        keys = {"globalstep", "register_globalstep", "every frame"},
        answer = "A globalstep callback runs repeatedly as the server advances. It receives a delta-time value, usually named dtime. Use it for logic that genuinely needs periodic updates, and accumulate elapsed time when an action only needs to run occasionally. Heavy work in every globalstep can hurt server performance."
    },
    {
        id = "formspec",
        priority = 86,
        keys = {"formspec", "formspecs", "formspec_version", "show_formspec"},
        answer = "A formspec is Luanti's declarative interface format for menus and inventories. It can contain fields, buttons, labels, boxes, lists, images, and other elements. A typical flow is to build a formspec string, show it with minetest.show_formspec, then handle submissions with a receive-fields callback. Escape user-provided text with minetest.formspec_escape before inserting it into a formspec."
    },
    {
        id = "receive_fields",
        priority = 78,
        keys = {"receive_fields", "on_player_receive_fields", "button handler", "handle_buttons"},
        answer = "A receive-fields callback handles submitted formspec fields. It commonly receives the player, formname, and fields table. Check which button or field was submitted, validate the input, and then perform the requested action. Treat all user-submitted values as untrusted input."
    },
    {
        id = "textures",
        priority = 76,
        keys = {"texture", "textures", "texture pack", "texturepack", "pixel art"},
        answer = "Textures are image assets used for nodes, items, entities, and the interface. In a mod, place texture files in textures/ and refer to them by their registered filename. Texture packs can replace many game textures without changing Lua code. Use consistent dimensions and test textures in-game under different lighting."
    },
    {
        id = "entities",
        priority = 75,
        keys = {"entity", "entities", "register_entity", "luaentity"},
        answer = "A Lua entity is a scripted object registered with minetest.register_entity. Entity definitions can include physical properties, collision boxes, visual settings, textures, and lifecycle callbacks such as on_activate and on_step. Keep on_step logic efficient because it may execute frequently."
    },
    {
        id = "abm_lbm",
        priority = 74,
        keys = {"abm", "lbm", "active block modifier", "loading block modifier"},
        answer = "ABMs run actions on matching nodes at configured intervals and can be useful for periodic world behavior, but excessive ABMs can affect performance. LBMs run when map blocks are loaded and are often useful for one-time node updates or migrations. Choose the simplest mechanism that fits the task."
    },
    {
        id = "privileges",
        priority = 68,
        keys = {"privilege", "privileges", "privs", "protection"},
        answer = "Privileges control which server actions a player may perform. Mods can register custom privileges and check a player's privileges before allowing sensitive actions. For multiplayer servers, validate permissions on the server side rather than trusting client interface state."
    },
    {
        id = "multiplayer",
        priority = 80,
        keys = {"multiplayer", "server", "join server", "connect to server", "port"},
        answer = "Luanti multiplayer uses a client-server model. The server owns authoritative world state, while clients display and interact with it. To join, you generally need the server address, port, and any required account details. Connection failures can come from an incorrect address, unavailable server, firewall, network restrictions, or version mismatch."
    },
    {
        id = "lag",
        priority = 82,
        keys = {"lag", "fps", "low fps", "stutter", "slow", "performance"},
        answer = "For better Luanti performance, try lowering view range, reducing shader and shadow quality, disabling heavy visual effects, and closing other demanding apps. Large numbers of animated entities, particles, and expensive mod callbacks can also affect performance. Change one setting at a time so you can identify what helps."
    },
    {
        id = "crash",
        priority = 92,
        keys = {"crash", "crashing", "force close", "not opening", "closes immediately"},
        answer = "If ExA Client or Luanti crashes, first note what action happened immediately before the crash. Check the debug log for the first meaningful Lua error or engine error, not just the final shutdown line. Temporarily disable recently added mods, restore the last known working settings, and back up worlds before testing changes. Share the exact error text to narrow it down."
    },
    {
        id = "lua_error",
        priority = 98,
        keys = {"attempt to index", "attempt to call", "nil value", "syntax error", "stack traceback", "lua error"},
        answer = "That sounds like a Lua error. Read the first error line and the file name plus line number in the traceback. 'attempt to index a nil value' often means a variable or table entry was not set; 'attempt to call a nil value' often means a function is missing or misspelled. Check spelling, load order, and whether the required API exists in your Luanti version. Paste the full error for a more precise explanation."
    },
    {
        id = "missing_dependency",
        priority = 85,
        keys = {"missing dependency", "dependency not found", "depends on", "mod not found", "failed to load mod"},
        answer = "A missing dependency means a mod requires another mod or game component that Luanti cannot find. Check the dependency name in mod.conf, confirm the required mod folder is installed and enabled, and verify the folder name matches the expected mod name. Optional dependencies should be declared as optional only if the mod can operate without them."
    },
    {
        id = "android",
        priority = 85,
        keys = {"android", "phone", "mobile", "touch controls", "android build"},
        answer = "On Android, Luanti runs as a native app and can use touch controls. When developing an Android build, keep the package ID, manifest, native libraries, assets, and build configuration consistent. Test on the actual device and check logcat or the app's debug log when startup fails."
    },
    {
        id = "apk",
        priority = 90,
        keys = {"apk", "install apk", "app not installed", "apk install"},
        answer = "An APK is an installable Android application package. If Android says 'App not installed', possible causes include a conflicting package/signature, unsupported Android version, wrong CPU architecture, corrupted download, or an incompatible split package. Check the exact error, device ABI, minSdk, signing configuration, and whether an older build with the same package ID is installed."
    },
    {
        id = "aab",
        priority = 86,
        keys = {"aab", "android app bundle", "app bundle", "bundletool"},
        answer = "An AAB is an Android App Bundle used to generate device-specific APKs; it is not normally installed directly like a universal APK. A tool such as bundletool can generate APK sets from an AAB. For testing, make sure the generated APK set includes the device's supported ABI, screen density, and language configuration."
    },
    {
        id = "abi",
        priority = 82,
        keys = {"architecture", "abi", "arm64", "armeabi", "x86", "x86_64", "cpu architecture"},
        answer = "Android native libraries are built for CPU ABIs such as arm64-v8a, armeabi-v7a, x86, and x86_64. The APK must contain a compatible native library for the target device unless the app is entirely Java/Kotlin. You can check supported ABIs in Android settings or with Android debugging tools."
    },
    {
        id = "manifest",
        priority = 88,
        keys = {"androidmanifest", "manifest", "package id", "application id", "namespace"},
        answer = "AndroidManifest.xml declares important app information such as package identity, activities, permissions, features, and application settings. XML must have one declaration at the very beginning if present, with no stray characters before it. Keep the manifest package/application identity consistent with Gradle configuration and any code that references the app ID."
    },
    {
        id = "android_tv",
        priority = 84,
        keys = {"android tv", "android television", "tv support", "television"},
        answer = "Android TV support needs more than a larger screen. The interface should be usable with a D-pad and remote, focus should be clearly visible, touch-only actions should have remote-friendly alternatives, and the manifest should declare the appropriate TV support features and launcher configuration. Keep phone support intact and test both layouts separately."
    },
    {
        id = "github",
        priority = 82,
        keys = {"github", "repository", "repo", "commit", "pull request", "branch"},
        answer = "GitHub hosts repositories and collaboration workflows. A branch lets you develop changes separately from another branch; a commit records a snapshot of changes; a pull request proposes merging one branch into another. Before large edits, check the current branch and working tree, and keep a backup or commit of the last working version."
    },
    {
        id = "actions",
        priority = 80,
        keys = {"github actions", "workflow", "yaml", "yml", "ci", "build action"},
        answer = "GitHub Actions workflows are YAML files commonly stored in .github/workflows/. They define triggers, jobs, runners, and steps. Check YAML indentation carefully, confirm action versions and required permissions, and inspect the first failing step in the Actions log. A successful workflow does not automatically guarantee the resulting APK works on every device."
    },
    {
        id = "git",
        priority = 70,
        keys = {"git", "git status", "git clone", "git merge", "git rebase"},
        answer = "Git tracks source-code history. Useful commands include git status to inspect changes, git diff to review edits, git add to stage files, and git commit to save a snapshot. Use branches for experiments and review a diff before committing so unrelated files are not included."
    },
    {
        id = "offline",
        priority = 84,
        keys = {"offline", "without internet", "no internet", "no api", "no network"},
        answer = "ExAI's brain is designed to work offline. It uses local Lua code and keyword-based rules, so it does not send your messages to an AI service. Its knowledge is limited to the information and response rules programmed into the file; it cannot automatically learn new facts or generate unrestricted answers like a large language model."
    },
    {
        id = "privacy",
        priority = 74,
        keys = {"privacy", "data", "messages stored", "chat history", "save chats"},
        answer = "The brain file itself does not need a server to answer questions. Whether chat messages are saved depends on the surrounding tab code. If you want chats to stay temporary, keep the transcript only in tab data and avoid writing it to files or settings. Do not put passwords or API keys into chat."
    },
    {
        id = "settings",
        priority = 70,
        keys = {"settings", "configuration", "configure", "setting"},
        answer = "Luanti settings control gameplay, graphics, sound, controls, and other engine behavior. Some settings are available through the in-game settings menu, while advanced settings may be stored in a configuration file. Change one setting at a time and keep a backup before editing configuration files manually."
    },
    {
        id = "controls",
        priority = 68,
        keys = {"controls", "keyboard", "mouse", "keybind", "touch"},
        answer = "Controls depend on the game and device. On desktop, keyboard and mouse are common; on Android, touch controls are used; Android TV needs remote or controller navigation. Check the controls menu and remap keys or buttons where supported."
    },
    {
        id = "sound",
        priority = 65,
        keys = {"sound", "music", "audio", "volume"},
        answer = "Sound behavior can depend on the game, device audio settings, and Luanti configuration. Check both the in-game volume settings and the Android media volume. If sound disappears after changing mods or assets, test with a clean world or the default game to isolate the cause."
    },
    {
        id = "content",
        priority = 68,
        keys = {"content tab", "content store", "download mods", "install mods", "packages"},
        answer = "Luanti's content features can help discover games, mods, and texture packs. Check that a package supports your Luanti version and the game you are using. Read its dependencies and description, and back up your world before adding mods that change map nodes or gameplay."
    },
    {
        id = "backup",
        priority = 76,
        keys = {"backup", "back up", "restore world", "world backup"},
        answer = "Before changing mods, replacing important files, or testing a new build, make a backup of your world and configuration. Copy the relevant world folder to a separate location and verify the copy exists. Do not rely on a backup stored only in the same folder you are modifying."
    },
    {
        id = "debug_log",
        priority = 84,
        keys = {"debug log", "debug.txt", "where is log", "log file"},
        answer = "The debug log records engine messages, warnings, and errors. When troubleshooting, search near the first error and include a few lines before and after it. Remove private information before sharing logs, and avoid sharing access tokens, passwords, or personal data."
    },
    {
        id = "thanks",
        priority = 50,
        keys = {"thanks", "thank you", "thx"},
        answer = "You're welcome! If something in ExA Client or Luanti isn't working, send me the exact message or describe what you were trying to do and I'll try to guide you."
    },
    {
        id = "greeting",
        priority = 40,
        keys = {"hello", "hi", "hey", "good morning", "good evening", "good afternoon"},
        answer = "Hello! I'm ExAI, your offline ExA Client and Luanti helper. Ask me about gameplay, mods, Lua, Android builds, or troubleshooting."
    },
    {
        id = "help",
        priority = 35,
        keys = {"help", "what should i ask", "examples", "commands"},
        answer = "Try asking: 'How do I create a Luanti mod?', 'What belongs in mod.conf?', 'How do formspec callbacks work?', 'Why does my APK say App not installed?', or 'How do I investigate a Lua stack traceback?' Include your Luanti version and exact error when troubleshooting."
    }
}

local function score_rule(text, rule)
    local score = 0
    local i
    for i = 1, #rule.keys do
        local key = normalize(rule.keys[i])
        if key ~= "" and text:find(key, 1, true) then
            local points = 10 + math.min(#key, 24)
            if text == key then
                points = points + 20
            elseif starts_with(text, key) then
                points = points + 5
            end
            if points > score then
                score = points
            end
        end
    end
    return score + (rule.priority or 0) / 100
end

local function fallback(text)
    if contains_any(text, {"how do i", "how to", "create", "make", "build", "write", "code"}) then
        return "I can try to help, but I don't have a specific programmed answer for that wording yet. Please mention whether you're working with Luanti gameplay, a Lua mod, a formspec, the ExA Client main menu, or an Android build. If it's a coding problem, include the relevant code and exact error."
    end
    if contains_any(text, {"why", "error", "problem", "issue", "not working", "failed"}) then
        return "I need a little more detail to identify the problem. Tell me what you expected, what happened instead, your Luanti or ExA Client version, and the exact error text if one appeared."
    end
    return "I don't have a confident match for that question in my offline knowledge base yet. I specialize in Luanti, ExA Client, Lua modding, Android builds, and troubleshooting. Try rephrasing with a specific topic or include more details."
end

function brain.ask(question)
    local text = normalize(question)
    if text == "" then
        return "Please type a question about Luanti, ExA Client, Lua modding, Android builds, or troubleshooting."
    end

    local best_rule = nil
    local best_score = 0
    local i
    for i = 1, #knowledge do
        local rule = knowledge[i]
        local score = score_rule(text, rule)
        if score > best_score then
            best_score = score
            best_rule = rule
        end
    end

    if best_rule and best_score >= 10 then
        return best_rule.answer
    end

    return fallback(text)
end

function brain.get_info()
    return {
        name = "ExAI Brain",
        version = "2.1",
        mode = "offline_rule_based",
        topics = #knowledge,
        network_required = false
    }
end

return brain
