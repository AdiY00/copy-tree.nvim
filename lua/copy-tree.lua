local M = {}

M.config = {
    root_dir = nil, -- Starts from working directory unless specified otherwise
    max_file_rows = 1000, -- Limit number of rows displayed per file
    max_files_per_directory = 30, -- Limit number of files shown per directory
    max_depth = nil, -- Maximum directory traversal depth (nil for infinite)
    max_characters = 1000000, -- Threshold for character estimation

    valid_extensions = {
        "%.lua$","%.rs$","%.py$","%.js$","%.jsx$","%.ts$","%.md$","%.txt$","%.json$","%.html$","%.css$","%.c$","%.cs$","%.cpp$","%.java$","%.php$","%.rb$","%.go$","%.swift$","%.kt$","%.dart$","%.m$","%.r$","%.pl$","%.sh$","%.scala$","%.tsv$","%.vue$","%.yaml$","%.xml$","%.sql$","%.hs$","%.jl$","%.groovy$","%.erl$","%.elm$","%.f90$","%.mat$","%.v$","%.vhd$","%.tex$","%.scss$","%.sass$","%.coffee$",
    },

    ignore_dirs = {
        "^%.", -- Hidden directories
        "node_modules",
        "__pycache__",
        "undo",
    },
}

function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

local function should_ignore(path)
    for _, pattern in ipairs(M.config.ignore_dirs) do
        if path:match(pattern) then
            return true
        end
    end
    return false
end

local function is_valid_file(path)
    for _, ext in ipairs(M.config.valid_extensions) do
        if path:match(ext) then
            return true
        end
    end
    return false
end

local function read_file(file_path)
    local file = io.open(file_path, "r")
    if not file then
        return nil
    end

    local content = {}
    local line_count = 0
    for line in file:lines() do
        line_count = line_count + 1
        if line_count > M.config.max_file_rows then
            content[#content + 1] = "\n[Content truncated - file exceeds max rows]"
            break
        end
        content[#content + 1] = line
    end

    file:close()
    return table.concat(content, "\n")
end

local function traverse_directory(dir, depth, tree, output)
    -- Check for infinite depth handling
    if M.config.max_depth and depth > M.config.max_depth then
        return 0
    end

    if should_ignore(dir) then
        return 0
    end

    local handle = vim.loop.fs_scandir(dir)
    if not handle then
        return 0
    end

    local entries = {}
    local total_size = 0
    local entries_shown = 0

    while true do
        local name, type = vim.loop.fs_scandir_next(handle)
        if not name then
            break
        end
        entries[#entries + 1] = { name = name, type = type }
    end

    table.sort(entries, function(a, b)
        return a.name < b.name
    end)

    for _, entry in ipairs(entries) do
        local path = dir .. "/" .. entry.name
        local display_name = string.rep("    ", depth - 1)
            .. (entry.type == "directory" and "├── " or "└── ")
            .. entry.name

        if entries_shown >= M.config.max_files_per_directory then
            tree[#tree + 1] = string.rep("    ", depth)
                .. "["
                .. (#entries - M.config.max_files_per_directory)
                .. " more files...]"
            break
        end

        tree[#tree + 1] = display_name

        if entry.type == "directory" then
            total_size = total_size + traverse_directory(path, depth + 1, tree, output)
        elseif is_valid_file(path) then
            local stat = vim.loop.fs_stat(path)
            if stat and stat.size then
                total_size = total_size + stat.size
            end

            local relative_path = path:sub(#M.config.root_dir + 2)
            output[#output + 1] = "File: " .. relative_path .. "\nContents:\n```"

            local content = read_file(path)
            output[#output + 1] = content or "[Error reading file]"
            output[#output + 1] = "```\n-------------------\n"
        end

        entries_shown = entries_shown + 1
    end

    return total_size
end

function M.copy_tree(args)
    M.config.root_dir = args.args ~= "" and args.args or M.config.root_dir or vim.fn.getcwd()
    local root_dir = M.config.root_dir

    local tree = { "Project Structure for '" .. root_dir .. "':\n" }
    local output = {}

    local estimated_size = traverse_directory(root_dir, 1, tree, output)

    if estimated_size > M.config.max_characters then
        local confirm = vim.fn.confirm(
            string.format(
                "The output is estimated to be %d characters, which might take a while. Are you sure you want to continue?",
                estimated_size
            ),
            "&Yes\n&No",
            2
        )
        if confirm ~= 1 then
            return
        end
    end

    vim.fn.setreg("+", table.concat(tree, "\n") .. "\n\nFile Contents:\n" .. table.concat(output, "\n"))
    print(string.format("Project structure and contents from '%s' yanked into \"+", root_dir))
end

vim.api.nvim_create_user_command("CopyTree", M.copy_tree, { nargs = "?" })

return M
