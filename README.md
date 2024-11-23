# copy-tree.nvim

A Neovim plugin that helps you capture your project's structure and file contents for context-aware responses from Large Language Models.

## ✨ Features

- **📁 Capture Project Structure & Contents**: Copy the directory structure and relevant file contents to your clipboard seamlessly.
- **🎯 File Filtering**: Focuses on essential files like code and documentation, ignoring irrelevant ones (e.g., cache, build artifacts).
- **🔧 Configurability**: Customize limits, file types, and directories to ignore according to your needs.

## 🚀 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "AdiY00/copy-tree.nvim",
  cmd = { "CopyTree", "SaveTree" },
  config = function()
    require("copy-tree").setup()
  end,
  -- Example keymap  
  vim.keymap.set("n", "<leader>ct", "<cmd>CopyTree<cr>", { desc = "Copy project structure from current directory" }),
},
```

## 📖 Usage

### Command-Line Usage

- **Basic Command**:
  
  ```vim
  :CopyTree
  ```
  
  Copies from the current directory using default settings.
  
- **Override Configurations**:
  
  ```vim
  :CopyTree /path/to/project max_depth=2 max_files_per_directory=10
  ```
  
- **Save Command**:
  
  ```vim
  :SaveTree /path/to/output.txt
  ```
  
  Saves the project structure and contents to the specified file.
  
- **Save Command with Override Configurations**:
  
  ```vim
  :SaveTree /path/to/output.txt max_depth=2 max_files_per_directory=10
  ```
  
  Saves the project structure and contents to the specified file with custom settings.

### Keymapping

- **Basic Keymaps**:
  
  ```lua
  local set = vim.keymap.set
  local ct = require("copy-tree")
  
  -- Basic function call with default settings:
  set("n", "<leader>ct", function() ct.copy_tree() end, { desc = "Copy project structure from current directory" })
  -- Alternatively,
  -- set("n", "<leader>ct", "<cmd>CopyTree<cr>", { desc = "Copy project structure from current directory" }),
  ```

### Example Output

`:CopyTree max_file_rows=5`

````plaintext
Project Structure for '/home/adiy00/plugins/copy-tree.nvim':

├── .git [Contents hidden]
└── LICENSE
└── README.md
├── lua
    └── copy-tree.lua

File Contents:
File: README.md
Contents:
```
# copy-tree.nvim

A Neovim plugin that helps you capture your project's structure and file contents for context-aware responses from Large Language Models.

## ✨ Features

[Content truncated - file exceeds max rows]
```
-------------------

File: lua/copy-tree.lua
Contents:
```
local M = {}

M.config = {
    root_dir = nil, -- Starts from working directory unless specified otherwise
    max_file_rows = 2000, -- Limit number of rows displayed per file

[Content truncated - file exceeds max rows]
```
-------------------
````

## ⚙️ Configuration

### Default Settings

```lua
{
  root_dir = nil,               -- Current directory
  max_file_rows = 2000,         -- Max lines per file
  max_files_per_directory = 30, -- Max files per directory
  max_depth = nil,              -- Nil for no depth limit
  max_characters = 1000000,     -- Output character warning
  valid_extensions = {          -- File extensions to include
    "%.lua$", "%.rs$", "%.py$", "%.js$", "%.jsx$", "%.ts$", "%.md$", "%.txt$",
    "%.json$", "%.html$", "%.css$", "%.c$", "%.cs$", "%.cpp$", "%.java$",
    "%.php$", "%.rb$", "%.go$", "%.swift$", "%.kt$", "%.dart$", "%.m$",
    "%.r$", "%.pl$", "%.sh$", "%.scala$", "%.tsv$", "%.vue$", "%.yaml$",
    "%.xml$", "%.sql$", "%.hs$", "%.jl$", "%.groovy$", "%.erl$", "%.elm$",
    "%.f90$", "%.mat$", "%.v$", "%.vhd$", "%.tex$", "%.scss$", "%.sass$",
    "%.coffee$",
  },
  additional_extensions = {},    -- Add extra extensions to valid_extensions
  exclude_extensions = {},       -- Remove extensions from valid_extensions
  ignore_dirs = { "^%.", "node_modules", "__pycache__", "undo" },
}
```

### Global Configuration

Set defaults in your Neovim config:

```lua
require("copy-tree").setup {
  max_file_rows = 1000,
  max_files_per_directory = 20,
  max_depth = 5,
  additional_extensions = { "%.tf$", },
  exclude_extensions = { "%.coffee$", }
  -- other settings
}
```

### Keymap with Configuration Override

```lua
local set = vim.keymap.set
local ct = require("copy-tree")

-- Function call with configuration override:
set("n", "<leader>ct", function()
  ct.copy_tree {
    root_dir = "/path/to/project",
    max_depth = 2,
    max_files_per_directory = 10,
    -- Other settings
  }
end, { desc = "Copy project structure with custom settings" })
```

## 🤖 Why copy-tree.nvim?

When interacting with LLMs, providing context is crucial. `copy-tree.nvim` improves the quality of responses you receive by:

- **📸 Comprehensive Project Snapshot**: Captures project structure, helping LLMs understand relationships between files and modules.
  
- **✂️ Selective Content Inclusion**: Includes only relevant file contents, ensuring LLMs get meaningful context.
  
- **📝 Optimized Formatting**: Outputs content in a clean, LLM-friendly format.
  
- **📈 Scalable for Large Projects**: Manages large projects with configurable limits to focus on essential information.
  
## 🚧 Future Plans

`copy-tree.nvim` is a work in progress, with additional features planned for future updates:

- **🔢 Token Counting**: Integrate token counting using specified tokenizers to help manage context size effectively for your favorite proprietary or local LLMs.
- **📏 Max Token Limit & Truncation**: Implement maximum token limits with smart truncation to fit within LLM constraints, while minimizing loss of essential context.
- **⚙️ Additional Configurations**: Offer more settings to fine-tune the plugin according to different workflows.
- **🛠️ Enhanced Functionality**: Explore new ways to improve usability and integration with other tools.
- **🔧 Code Refinement**: Continuously improve code stability and performance to ensure reliable operation and efficient handling of larger projects.

Stay tuned for updates, and feel free to suggest features you'd like to see!

## 🤝 Contributing

Contributions are welcome! If you encounter any issues or have feature suggestions, feel free to open an issue or submit a pull request.
