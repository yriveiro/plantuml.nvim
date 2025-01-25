# plantuml.nvim

PlantUML rendering for Neovim with real-time preview, intelligent caching, and dynamic image scaling.

## ✨ Features

- Real-time preview of PlantUML diagrams directly in Neovim
- Intelligent caching system using SHA-256 hashing
- Dynamic image scaling and aspect ratio preservation
- Zoom controls for image manipulation
- Cross-platform support (Linux and macOS)
- Memory-efficient image handling
- Vim-style keybindings for navigation

## 📦 Dependencies

### Required

- Neovim >= 0.10.2
- [plantuml](https://plantuml.com/starting) - For diagram rendering
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - For Lua utilities
- [image.nvim](https://github.com/3rd/image.nvim) - For terminal graphics

## 💻 Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'yriveiro/plantuml.nvim',
  dependencies = {
    '3rd/image.nvim',
  },
  config = function()
    require('plantuml').setup({
      -- Optional configuration
    })
  end,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'yriveiro/plantuml.nvim',
  requires = { '3rd/image.nvim' },
  config = function()
    require('plantuml').setup({})
  end
}
```

## ⚙️ Configuration

Default configuration:

```lua
{
  win = {
    border = 'single',
    title = {
      name = ' PlantUML Preview ',
    },
  },
  cache = {
    path = vim.fs.joinpath(tostring(vim.fn.stdpath 'cache'), '/plantuml/'),
  },
  cmd = 'plantuml',

}
```

## 🚀 Usage

1. Open a `.puml` file in Neovim
2. Use the following commands:
   - `:PlantUMLPreview` - Open preview window
   - Press `+` to zoom in
   - Press `-` to zoom out
   - Press `q` to close preview

## 🤝 Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 🙏 Acknowledgements

This plugin builds upon the work of:

- [hologram.nvim](https://github.com/edluffy/hologram.nvim)
- [image.nvim](https://github.com/3rd/image.nvim)

## 📝 License

Licensed under the MIT License. See [LICENSE](LICENSE) for details.
