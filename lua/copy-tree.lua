local M = {}

M.config = {
    root_dir = nil, -- Starts from working directory unless specified otherwise
    max_file_rows = 2000, -- Limit number of rows displayed per file
    max_files_per_directory = 30, -- Limit number of files shown per directory
    max_depth = nil, -- Maximum directory traversal depth (nil for infinite)
    max_characters = 1000000, -- Threshold for character estimation

    valid_extensions = {
        "%.lua$","%.rs$","%.py$","%.js$","%.jsx$","%.ts$","%.md$","%.txt$","%.json$","%.html$","%.css$","%.c$","%.cs$","%.cpp$","%.java$","%.php$","%.rb$","%.go$","%.swift$","%.kt$","%.dart$","%.m$","%.r$","%.pl$","%.sh$","%.scala$","%.tsv$","%.vue$","%.yaml$","%.xml$","%.sql$","%.hs$","%.jl$","%.groovy$","%.erl$","%.elm$","%.f90$","%.mat$","%.v$","%.vhd$","%.tex$","%.scss$","%.sass$","%.coffee$",
    },

    additional_extensions = {}, -- List of extensions to add to the valid_extensions list
    exclude_extensions = {},    -- List of extensions to remove from the valid_extensions list

    ignore_dirs = {
        "^%.", -- Hidden directories starting with a dot
        "node_modules", "__pycache__", "undo",
    },
}

function M.setup(opts)
    local new_config = vim.tbl_deep_extend("force", M.config, opts or {})

    -- Add additional extensions
    if new_config.additional_extensions then
        vim.list_extend(new_config.valid_extensions, new_config.additional_extensions)
    end

    -- Remove excluded extensions
    if new_config.exclude_extensions then
        local final_extensions = {}
        for _, ext in ipairs(new_config.valid_extensions) do
            local should_keep = true
            for _, excluded in ipairs(new_config.exclude_extensions) do
                if ext == excluded then
                    should_keep = false
                    break
                end
            end
            if should_keep then
                table.insert(final_extensions, ext)
            end
        end
        new_config.valid_extensions = final_extensions
    end

    M.config = new_config
end

local function should_ignore(path, config)
    local basename = vim.fn.fnamemodify(path, ':t')
    for _, pattern in ipairs(config.ignore_dirs) do
        if basename:match(pattern) then
            return true
        end
    end
    return false
end

local function is_valid_file(path, config)
    for _, ext in ipairs(config.valid_extensions) do
        if path:match(ext) then
            return true
        end
    end
    return false
end

local function read_file(file_path, config)
    local file = io.open(file_path, "r")
    if not file then
        return nil
    end

    local content = {}
    local line_count = 0
    for line in file:lines() do
        line_count = line_count + 1
        if line_count > config.max_file_rows then
            content[#content + 1] = "\n[Content truncated - file exceeds max rows]"
            break
        end
        content[#content + 1] = line
    end

    file:close()
    return table.concat(content, "\n")
end

local function traverse_directory(dir, depth, tree, output, config)
    -- Check for infinite depth handling
    if config.max_depth and depth > config.max_depth then
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

        if entries_shown >= config.max_files_per_directory then
            tree[#tree + 1] = string.rep("    ", depth)
                .. "["
                .. (#entries - config.max_files_per_directory)
                .. " more files...]"
            break
        end

        if should_ignore(path, config) then
            if entry.type == "directory" then
                tree[#tree + 1] = display_name .. " [Contents hidden]"
            end
            entries_shown = entries_shown + 1
            goto continue
        end

        tree[#tree + 1] = display_name

        if entry.type == "directory" then
            total_size = total_size + traverse_directory(path, depth + 1, tree, output, config)
        elseif is_valid_file(path, config) then
            local stat = vim.loop.fs_stat(path)
            if stat and stat.size then
                total_size = total_size + stat.size
            end

            local relative_path = path:sub(#config.root_dir + 2)
            output[#output + 1] = "File: " .. relative_path .. "\nContents:\n```"

            local content = read_file(path, config)
            output[#output + 1] = content or "[Error reading file]"
            output[#output + 1] = "```\n-------------------\n"
        end

        entries_shown = entries_shown + 1

        ::continue::
    end

    return total_size
end

function M.generate_tree_output(args)
    -- Process arguments and build config
    local config_overrides = {}
    local root_dir_arg = nil

    if type(args) == "table" and args.args then
        -- Called via command-line with arguments
        local arg_str = args.args
        for _, arg in ipairs(vim.split(arg_str, "%s+")) do
            if arg ~= "" then  -- Skip empty arguments
                if arg:find("=") then
                    local key_value = vim.split(arg, "=", { plain = true })
                    local key = key_value[1]
                    local value = key_value[2]
                    if key and value then
                        config_overrides[key] = value
                    end
                else
                    -- If arg doesn't contain '=', assume it's the root_dir
                    root_dir_arg = arg
                end
            end
        end
    elseif type(args) == "table" then
        -- Called programmatically with configurations
        config_overrides = args
    elseif type(args) == "string" then
        -- If a single string is passed, assume it's the root_dir
        root_dir_arg = args
    end

    -- Set root_dir if provided
    if root_dir_arg and root_dir_arg ~= "" then
        config_overrides.root_dir = root_dir_arg
    end

    -- Create a local config with overrides
    local config = vim.tbl_deep_extend("force", {}, M.config)
    for key, value in pairs(config_overrides) do
        if key ~= "" and config[key] ~= nil then
            -- Convert value to the correct type
            if type(config[key]) == "number" then
                config[key] = tonumber(value)
            elseif type(config[key]) == "boolean" then
                config[key] = (value == "true")
            elseif type(config[key]) == "table" then
                -- For list-type configurations like valid_extensions or ignore_dirs
                if type(value) == "string" then
                    config[key] = vim.split(value, ",")
                elseif type(value) == "table" then
                    config[key] = value
                end
            else
                config[key] = value
            end
        elseif key ~= "" then
            print("Warning: Invalid configuration key: " .. key)
        end
    end

    config.root_dir = config.root_dir or vim.fn.getcwd()
    local root_dir = config.root_dir

    local tree = { "Project Structure for '" .. root_dir .. "':\n" }
    local output = {}

    local estimated_size = traverse_directory(root_dir, 1, tree, output, config)

    return estimated_size, tree, output, config
end

function M.copy_tree(args)
    local estimated_size, tree, output, config = M.generate_tree_output(args)

    if estimated_size > config.max_characters then
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
    print(string.format("Project structure and contents from '%s' yanked into \"+", config.root_dir))
end

function M.save_tree(args)
    local file_path = nil
    if type(args) == "table" and args.args then
        local arg_str = args.args
        local args_list = vim.split(arg_str, "%s+")
        if #args_list == 0 then
            print("Error: No file path provided.")
            return
        end
        file_path = args_list[1]
        -- Remove the file path from args_list
        table.remove(args_list, 1)
        args.args = table.concat(args_list, " ")
    elseif type(args) == "string" then
        file_path = args
    else
        print("Error: Invalid arguments.")
        return
    end

    if not file_path or file_path == "" then
        print("Error: No file path provided.")
        return
    end

    local estimated_size, tree, output, config = M.generate_tree_output(args)

    if estimated_size > config.max_characters then
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

    local full_output = table.concat(tree, "\n") .. "\n\nFile Contents:\n" .. table.concat(output, "\n")

    local file = io.open(file_path, "w")
    if not file then
        print("Error: Could not open file '" .. file_path .. "' for writing.")
        return
    end

    file:write(full_output)
    file:close()

    print(string.format("Project structure and contents from '%s' saved to '%s'", config.root_dir, file_path))
end

vim.api.nvim_create_user_command("CopyTree", M.copy_tree, { nargs = "*" })
vim.api.nvim_create_user_command("SaveTree", M.save_tree, { nargs = "*" })

return M
