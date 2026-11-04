-- ExA Client - ExAI main-menu tab
-- Offline assistant. No API, browser, or network connection is used.

local function escape(value)
	value = tostring(value or "")
	if core and core.formspec_escape then
		return core.formspec_escape(value)
	end
	return value:gsub("\\", "\\\\")
		:gsub("%]", "\\]")
		:gsub("%[", "\\[")
		:gsub(";", "\\;")
		:gsub(",", "\\,")
end

local function load_brain()
	if not core or not core.get_mainmenu_path then
		return nil, "Cannot locate the ExA Client main-menu folder."
	end

	local path = core.get_mainmenu_path() .. DIR_DELIM .. "exai_brain.lua"
	local ok, result = pcall(dofile, path)
	if not ok then
		return nil, "Could not load exai_brain.lua: " .. tostring(result)
	end
	if type(result) ~= "table" or type(result.ask) ~= "function" then
		return nil, "exai_brain.lua must return a table with an ask() function."
	end
	return result
end

local brain, brain_error = load_brain()

local function get_formspec(tabview, name, tabdata)
	tabdata = tabdata or {}
	local transcript = tabdata.transcript or ""
	local status = tabdata.status or (brain and "OFFLINE  |  READY" or "BRAIN ERROR  |  " .. (brain_error or "Unavailable"))
	local input = tabdata.input or ""

	-- Layout uses the main-menu tab's normal coordinate space (about 15.5 x 7.1).
	-- Each panel has its own spacing; no controls overlap.
	local fs = {
		"formspec_version[4]",

		-- Header
		"box[0.35,0.22;14.8,0.82;#17232D]",
		"label[0.72,0.48;ExAI]",
		"label[2.05,0.50;EXA CLIENT  /  OFFLINE ASSISTANT]",

		-- Conversation panel
		"box[0.35,1.22;14.8,4.35;#101820]",
		"textarea[0.62,1.43;14.25,3.95;;;",
		escape(transcript),
		"]",

		-- Composer panel
		"box[0.35,5.78;14.8,0.98;#17232D]",
		"field[0.68,5.91;11.45,0.72;message;Message;",
		escape(input),
		"]",
		"field_enter_after_edit[message;true]",
		"button[12.35,5.91;2.35,0.72;send;Send]",

		-- Status line
		"label[0.62,6.88;",
		escape(status),
		"]",
	}

	return table.concat(fs, "")
end

local function handle_buttons(this, fields, name, tabdata)
	tabdata = tabdata or {}

	-- Keep the typed value if the formspec reports a field update.
	if fields.message ~= nil then
		tabdata.input = fields.message
	end

	-- Send button or Enter in the message field.
	if not fields.send and not fields.key_enter then
		return false
	end

	local message = tostring(fields.message or tabdata.input or "")
	message = message:gsub("^%s+", ""):gsub("%s+$", "")

	if message == "" then
		tabdata.status = "TYPE A MESSAGE BEFORE SENDING"
		return true -- Tell the tabview to redraw the tab.
	end

	-- Clear the input after submission and show exactly what was sent.
	tabdata.input = ""

	if not brain then
		tabdata.transcript = "YOU\n" .. message .. "\n\nExAI\n" ..
			"The offline brain could not be loaded. Check that exai_brain.lua is in builtin/mainmenu/."
		tabdata.status = "BRAIN ERROR  |  CHECK exai_brain.lua"
		return true
	end

	local ok, answer = pcall(brain.ask, message)
	if not ok or type(answer) ~= "string" or answer == "" then
		answer = "I couldn't process that message. Please try asking in a different way."
		tabdata.status = "REPLY ERROR"
	else
		tabdata.status = "OFFLINE  |  REPLY READY"
	end

	-- Only the latest exchange is kept in memory. Nothing is written to disk.
	tabdata.transcript = "YOU\n" .. message .. "\n\nExAI\n" .. answer

	return true -- Required: refresh the formspec so the reply becomes visible.
end

return {
	name = "exai",
	caption = "ExAI",
	cbf_formspec = get_formspec,
	cbf_button_handler = handle_buttons,
}
