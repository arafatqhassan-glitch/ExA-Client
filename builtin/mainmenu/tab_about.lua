-- Luanti
-- Copyright (C) 2013 sapier
-- SPDX-License-Identifier: LGPL-2.1-or-later

local function prepare_credits(dest, source)
	if type(source) ~= "table" then
		return
	end

	local lines = {}

	for _, name in ipairs(source) do
		if type(name) == "string" and name ~= "" then
			-- Escape names so special characters are safe in hypertext.
			local escaped = core.hypertext_escape(name)

			-- Color role labels such as [Engine founder] grey.
			escaped = escaped:gsub(
				"%[([^%]]*)%]",
				"<gray>[%1]</gray>"
			)

			lines[#lines + 1] = escaped
		end
	end

	if #lines > 0 then
		table.insert(dest, table.concat(lines, "\n"))
	end
end

local function get_credits()
	local path = core.get_mainmenu_path() .. "/credits.json"
	local file = io.open(path, "r")

	if not file then
		core.log("warning", "[About] Could not open " .. path)
		return {}
	end

	local contents = file:read("*all")
	file:close()

	if not contents then
		core.log("warning", "[About] Could not read credits.json")
		return {}
	end

	local ok, credits = pcall(core.parse_json, contents)

	if not ok or type(credits) ~= "table" then
		core.log("error", "[About] Failed to parse credits.json")
		return {}
	end

	return credits
end

local function get_renderer_info()
	local ret = {}

	local s1 = core.get_active_renderer()
	if s1:sub(1, 7) == "OpenGL " then
		s1 = s1:sub(8)
	end

	local m = s1:match("^[%d.]+")
	if not m then
		m = s1:match("^ES [%d.]+")
	end
	ret[#ret + 1] = m or s1

	ret[#ret + 1] = core.get_active_driver():lower()
	ret[#ret + 1] = core.get_active_irrlicht_device():upper()

	return table.concat(ret, " / ")
end

return {
	name = "about",
	caption = fgettext("About"),

	cbf_formspec = function(tabview, name, tabdata)
		local logofile = defaulttexturedir .. "logo.png"
		local version = core.get_version()

		local hypertext = {
			"<tag name=heading color=#ffff00>",
			"<tag name=gray color=#aaaaaa>",
		}

		local credits = get_credits()
		local developers = credits.core_developers

		if type(developers) == "table" then
			table.insert_all(hypertext, {
				"<heading>",
				core.hypertext_escape(fgettext_ne("Core Developers")),
				"</heading>\n",
			})

			prepare_credits(hypertext, developers)
		else
			core.log("warning",
				"[About] credits.json has no core_developers array")
			table.insert(hypertext,
				core.hypertext_escape(
					fgettext_ne("Core developers credits unavailable.")
				))
		end

		local credits_text = table.concat(hypertext)

		local fs = {
			"image[1,0.5;3.4,3.4;",
			core.formspec_escape(logofile),
			"]",

			"style_type[label;valign=center;halign=center;font=mono,bold;font_size=*1.1]",
			"label[0.1,4;5.4,0.6;",
			core.formspec_escape(
				version.project .. " " .. version.string
			),
			"]",

			"style_type[button_url;border=false;textcolor=#4cd9f9]",
			"button_url[1.5,4.6;2.5,0.5;homepage;luanti.org;https://www.luanti.org/]",
		}

		if PLATFORM == "Android" then
			fs[#fs + 1] =
				"button[0.5,5.1;4.5,0.8;share_debug;" ..
				core.formspec_escape(fgettext("Share debug log")) .. "]"
		else
			fs[#fs + 1] =
				"tooltip[userdata;" ..
				core.formspec_escape(fgettext(
					"Opens the directory that contains user-provided worlds, games, mods,\n" ..
					"and texture packs in a file manager / explorer."
				)) .. "]"

			fs[#fs + 1] =
				"button[0.5,5.1;4.5,0.8;userdata;" ..
				core.formspec_escape(
					fgettext("Open User Data Directory")
				) .. "]"
		end

		local active_renderer_info =
			fgettext("Active renderer:") .. "\n" ..
			core.formspec_escape(get_renderer_info())

		table.insert_all(fs, {
			"style_type[textarea;valign=center;halign=center;font_size=*0.9]",
			"textarea[0.1,6;5.4,1;;",
			active_renderer_info,
			";]",

			"hypertext[5.5,0.25;9.75,6.6;credits;",
			core.formspec_escape(credits_text),
			"]",
		})

		return table.concat(fs, "")
	end,

	cbf_button_handler = function(this, fields, name, tabdata)
		if fields.share_debug then
			local path = core.get_user_path() .. DIR_DELIM .. "debug.txt"
			core.share_file(path)
		end

		if fields.userdata then
			core.open_dir(core.get_user_path())
		end
	end,

	on_change = function(type)
		if type == "ENTER" then
			mm_game_theme.set_engine()
		end
	end,
}
