# copy-tree.nvim
A Neovim plugin that helps you capture your project's structure and file contents for better responses from Large Language Models.

## ✨ Features
- **📁 Capture Project Structure & Contents**: Copy the directory structure and relevant file contents to your clipboard seamlessly.
- **🎯 File Filtering**: Focuses on essential files like code and documentation, ignoring irrelevant ones (e.g., cache, build artifacts).
- **🔧 Configurability**: Customize limits, file types, and directories to ignore according to your needs.

## 🚀 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "AdiY00/copy-tree.nvim",
  cmd = "CopyTree",
  config = function()
    require("copy-tree").setup()
  end,
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

- **Specify Root Directory**:
  ```vim
  :CopyTree /path/to/project
  ```

- **Override Configurations**:
  ```vim
  :CopyTree max_depth=2 max_files_per_directory=10
  ```

- **Combine Path and Configurations**:
  ```vim
  :CopyTree /path/to/project max_depth=2
  ```

### Programmatic Usage

- **Basic Function Call**:
  ```lua
  require("copy-tree").copy_tree()
  ```

- **With Configurations**:
  ```lua
  require("copy-tree").copy_tree {
    root_dir = "/path/to/project",
    max_depth = 2,
    max_files_per_directory = 10,
  }
  ```

## ⚙️ Configuration

### Default Settings
```lua
{
  root_dir = nil,               -- Current directory
  max_file_rows = 2000,         -- Max lines per file
  max_files_per_directory = 30, -- Max files per directory
  max_depth = nil,              -- No depth limit
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
  -- other settings
}
```

### Per Invocation Overrides

- **Command-Line**:
  ```vim
  :CopyTree max_file_rows=500 max_depth=3
  ```

- **Programmatic**:
  ```lua
  require("copy-tree").copy_tree {
    max_file_rows = 500,
    max_depth = 3,
  }
  ```

## 🤖 Why copy-tree.nvim?

When interacting with LLMs, providing context is crucial. `copy-tree.nvim` improves the quality of responses you receive by:

1. **Comprehensive Project Snapshot**: Captures project structure, helping LLMs understand relationships between files and modules.
2. **Selective Content Inclusion**: Includes only relevant file contents, ensuring LLMs get meaningful context.
3. **Optimized Formatting**: Outputs content in a clean, LLM-friendly format.
4. **Scalable for Large Projects**: Handles large projects efficiently, with configurable limits to focus on essential information.

## 🤝 Contributing

Contributions are welcome! If you encounter any issues or have feature suggestions, feel free to open an issue or submit a pull request.

