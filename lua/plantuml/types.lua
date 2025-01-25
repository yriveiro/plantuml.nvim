---@class plantuml.png
---@field read fun(file: file*, n: integer): table|nil Reads a specific number of bytes from a file.
---@field to_int fun(buf: table, offset: integer): integer Converts 4 bytes from a buffer to a 32-bit integer.
---@field dimensions fun(file: file*): table|nil Extracts the dimensions (width and height) of a PNG image file.

---@class plantuml.window
---@field geometry fun(size: table, term: table): table Computes the scaled dimensions of an image.
---@field zoom fun(scale_factor: number, operation: string) Adjusts the zoom level of the image.
---@field create fun(dim: table, opts: table|nil): number, number Creates a floating window for displaying an image.

--- @class plantuml.config
--- @field win plantuml.config.win Options for the preview window.
--- @field cache plantuml.config.cache Cache-related options.
--- @field cmd string PlantUML command to execute for rendering diagrams.

---@class plantuml.config.win
---@field border string Border style for the window.
---@field title plantuml.config.win.title Title options for the window.

---@class plantuml.config.win.title
---@field name string Title text for the window.
---@field pos string Position of the title ('center', 'left', etc.).

---@class plantuml.config.cache
---@field path string Path to the cache directory for storing rendered PNGs.
