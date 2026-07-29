local M = {}

local function is_blank(line)
	return line:match("^%s*$") ~= nil
end

local function split_blocks(lines)
	local blocks = {}
	local current = {}

	for _, line in ipairs(lines) do
		if is_blank(line) then
			if #current > 0 then
				table.insert(blocks, current)
				current = {}
			end
			table.insert(blocks, { line, blank = true })
		else
			table.insert(current, line)
		end
	end

	if #current > 0 then
		table.insert(blocks, current)
	end

	return blocks
end

local function align_equals(lines)
	local max = 0

	for _, line in ipairs(lines) do
		local lhs = line:match("^(.-)%s*=")
		if lhs then
			max = math.max(max, #lhs)
		end
	end

	for i, line in ipairs(lines) do
		local lhs, rhs = line:match("^(.-)%s*=%s*(.*)$")
		if lhs then
			lines[i] = lhs .. string.rep(" ", max - #lhs + 1) .. "= " .. rhs
		end
	end
end

local function parse_args(text)
	local args = {}
	local depth = 0
	local start = 1

	for i = 1, #text do
		local c = text:sub(i, i)

		if c == "(" then
			depth = depth + 1
		elseif c == ")" then
			depth = depth - 1
		elseif c == "," and depth == 0 then
			table.insert(args, vim.trim(text:sub(start, i - 1)))
			start = i + 1
		end
	end

	table.insert(args, vim.trim(text:sub(start)))

	return args
end

local function align_arg_group(arglists)
	local widths = {}

	for _, args in ipairs(arglists) do
		for i, arg in ipairs(args) do
			widths[i] = math.max(
				widths[i] or 0,
				#arg
			)
		end
	end

	local out = {}

	for idx, args in ipairs(arglists) do
		local pieces = {}

		for i, arg in ipairs(args) do
			if i ~= #args then
				table.insert(
					pieces,
					arg .. ", " .. string.rep(
						" ",
						widths[i] - #arg
					)
				)
			else
				table.insert(
					pieces,
					arg
				)
			end
		end

		out[idx] = table.concat(pieces)
	end

	return out
end

local function align_functions(lines)
	local groups = {}

	for i, line in ipairs(lines) do
		local before, inside, suffix =
			line:match("^(.-)%((.*)%)((.*))$")

		if before and inside then
			table.insert(groups, {
				index = i,
				prefix = before,
				suffix = suffix,
				args = parse_args(inside),
			})
		end
	end

	if #groups == 0 then
		return
	end

	local arglists = {}

	for _, g in ipairs(groups) do
		table.insert(arglists, g.args)
	end

	local aligned = align_arg_group(arglists)

	for i, g in ipairs(groups) do
		lines[g.index] = g.prefix .. "(" .. aligned[i] .. ")"
		if g.suffix ~= "" then
			lines[g.index] = lines[g.index] .. g.suffix
		end
	end
end

function M.align()
	local start = vim.fn.line("'<")
	local finish = vim.fn.line("'>")
	local lines = vim.api.nvim_buf_get_lines(
		0,
		start - 1,
		finish,
		false
	)

	local blocks = split_blocks(lines)
	local out = {}

	for _, block in ipairs(blocks) do
		if block.blank then
			table.insert(out, "")
		else
			align_equals(block)
			align_functions(block)

			for _, l in ipairs(block) do
				table.insert(out, l)
			end
		end
	end

	vim.api.nvim_buf_set_lines(
		0,
		start - 1,
		finish,
		false,
		out
	)
end

vim.api.nvim_create_user_command('Align', function()
	M.align()
end, { range = true })

vim.api.nvim_set_keymap('x', '<leader>lq', ":'<,'>Align<CR>",
	{ noremap = true, silent = true, desc = 'Align format' })

return M
