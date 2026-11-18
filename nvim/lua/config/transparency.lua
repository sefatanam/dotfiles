-- Transparent mode (see CONTEXT.md): follow the on/off state written by the
-- `transparency` command. When on, rose-pine stops painting the editor background so
-- Ghostty's blur shows through; floats and the completion menu stay solid so they
-- remain readable. The snacks explorer is the sidebar, so it follows the editor
-- background, not the float panels. The state file is watched, so switching applies to
-- running sessions without a restart.

local M = {}

function M.state_file()
  local state_home = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
  return state_home .. "/transparent-mode"
end

-- Mirrors the command: anything but a first line of exactly "on" is off.
function M.enabled()
  local f = io.open(M.state_file(), "r")
  if not f then
    return false
  end
  local first = f:read("*l")
  f:close()
  return first == "on"
end

-- Groups rose-pine's transparency clears that should keep a solid panel background.
local solid_groups = {
  NormalFloat = { bg = "surface" },
  FloatBorder = { fg = "muted", bg = "surface" },
  FloatTitle = { fg = "foam", bg = "surface", bold = true },
  Pmenu = { fg = "subtle", bg = "surface" },
  PmenuExtra = { fg = "text", bg = "surface" },
  PmenuKind = { fg = "foam", bg = "surface" },
  WhichKeyFloat = { bg = "surface" },
  WhichKeyNormal = { bg = "surface" },
  TelescopeNormal = { fg = "subtle", bg = "surface" },
  TelescopePromptNormal = { fg = "text", bg = "surface" },
  TroubleNormal = { bg = "surface" },
}

function M.rose_pine_opts(enabled)
  return {
    styles = { transparency = enabled },
    highlight_groups = enabled and vim.deepcopy(solid_groups) or {},
  }
end

-- rose-pine deep-merges each setup() into its previous options, so overrides from
-- an earlier "on" would survive into "off". Clear them first.
function M.apply()
  local ok, rose_pine = pcall(require, "rose-pine")
  if not ok then
    return
  end
  require("rose-pine.config").options.highlight_groups = {}
  rose_pine.setup(M.rose_pine_opts(M.enabled()))
  local current = vim.g.colors_name
  if current and current:find("^rose%-pine") then
    vim.cmd.colorscheme(current)
  end
end

-- Point a window's background groups at SnacksSidebar, keeping its other mappings.
function M.sidebar_winhl(winhl)
  local out = winhl:gsub("(Normal%a*):[%w_]+", function(group)
    if group == "Normal" or group == "NormalNC" or group == "NormalFloat" then
      return group .. ":SnacksSidebar"
    end
  end)
  return out
end

-- Called from the explorer's on_show: snacks builds the windows' highlights itself
-- and ignores a configured winhighlight, so rewrite them once they exist.
function M.sidebar(picker)
  local wins = vim.tbl_values(picker.layout.box_wins)
  vim.list_extend(wins, { picker.list.win, picker.input.win })
  for _, win in ipairs(wins) do
    if win:valid() then
      vim.wo[win.win].winhighlight = M.sidebar_winhl(vim.wo[win.win].winhighlight)
    end
  end
end

local function define_sidebar_group()
  vim.api.nvim_set_hl(0, "SnacksSidebar", M.enabled() and { bg = "NONE" } or { link = "NormalFloat" })
end

-- The command replaces the file with a rename, so watch the directory, not the file.
local function watch()
  local file = M.state_file()
  local dir, name = vim.fs.dirname(file), vim.fs.basename(file)
  vim.fn.mkdir(dir, "p")
  local handle = vim.uv.new_fs_event()
  if not handle then
    return
  end
  handle:start(dir, {}, function(err, changed)
    if not err and changed == name then
      vim.schedule(M.apply)
    end
  end)
end

function M.setup()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("TransparentMode", { clear = true }),
    callback = define_sidebar_group,
  })
  define_sidebar_group()
  watch()
end

return M
