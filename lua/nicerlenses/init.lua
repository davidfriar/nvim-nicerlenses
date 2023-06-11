local defaults = {
	hide_virtual_text = true,
	pattern = "*.hs",
	icon = "",
	highlight = "LspDiagnosticsDefaultInformation",
	priority = 500,
}
local codelens = require("vim.lsp.codelens")
local M = {}

local SIGN_GROUP = "nicerlenses"
local SIGN_NAME = "LensLightBulbSign"

M.setup = function(opts)
	M.options = vim.tbl_deep_extend("keep", opts, defaults)

	if vim.tbl_isempty(vim.fn.sign_getdefined(SIGN_NAME)) then
		vim.fn.sign_define(SIGN_NAME, { text = M.options.icon, texthl = M.options.highlight })
	end

	vim.api.nvim_create_autocmd(
		{ "CursorHold", "CursorHoldI" },
		{ callback = M.update_signs, pattern = M.options.pattern }
	)

	if M.options.hide_virtual_text then
		vim.cmd("hi LspCodeLens guifg=bg")
		vim.cmd("hi LspCodeLensSeparator guifg=bg")
	end

	vim.api.nvim_create_user_command("NicerLensesRun", require("nicerlenses").run, {})
end

M.update_signs = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local var_name = "lens_line"
	local ok, previousLine = pcall(vim.api.nvim_buf_get_var, bufnr, var_name)
	if ok and previousLine then
		M.remove_sign(previousLine, bufnr)
	end

	local currentLine = vim.api.nvim_win_get_cursor(0)[1]
	local lenses = M.get_lenses_for_current_line()
	if #lenses > 0 then
		M.set_sign(currentLine, bufnr)
		vim.api.nvim_buf_set_var(bufnr, var_name, currentLine)
	end
end

M.set_sign = function(line, bufnr)
	vim.fn.sign_place(line, SIGN_GROUP, SIGN_NAME, bufnr, { lnum = line, priority = M.options.priority })
end

M.remove_sign = function(line, bufnr)
	vim.fn.sign_unplace(SIGN_GROUP, { id = line, buffer = bufnr })
end

M.get_lenses_for_current_line = function()
	local results = {}
	local line = vim.api.nvim_win_get_cursor(0)[1]
	local allLenses = codelens.get(0)
	for client, lens in pairs(allLenses) do
		if lens.range.start.line == (line - 1) then
			table.insert(results, { client = client, lens = lens })
		end
	end
	return results
end

M.has_lenses_for_current_line = function()
	return #M.get_lenses_for_current_line() > 0
end

M.run = function()
	local lenses = M.get_lenses_for_current_line()
	if #lenses == 0 then
		vim.notify("No codelens found on current line")
	elseif #lenses == 1 then
		vim.ui.select(lenses, {
			prompt = "Code lenses",
			kind = "codelens",
			format_item = function(lens)
				return lens.lens.command.title
			end,
		}, codelens.run)
	else
		codelens.run()
	end
	codelens.refresh()
end

return M
