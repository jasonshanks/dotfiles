return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
  -- stylua: ignore
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
  },
  },

  {
    "echasnovski/mini.hipatterns",
    event = "BufReadPre",
    opts = {
      highlighters = {
        -- Highlight hex colors (explicit definition to avoid conflicts)
        hex_color = {
          pattern = "#%x%x%x%x%x%x", -- Match 6-digit HEX colors
          group = function(_, match)
            return MiniHipatterns.compute_hex_color_group(match, "bg")
          end,
        },

        -- Highlight hsl() colors
        hsl_color = {
          pattern = "hsl%(%s*%d+%s*,%s*%d+%%%s*,%s*%d+%%%s*%)",
          group = function(_, match)
            -- Extract HSL values
            local nh, ns, nl = match:match("hsl%((%d+)%s*,%s*(%d+)%%%s*,%s*(%d+)%%%s*%)")
            local h, s, l = tonumber(nh), tonumber(ns), tonumber(nl)
            if not (h and s and l) then
              return nil
            end

            -- Convert HSL to HEX
            local function hslToHex(h, s, l)
              h = h / 360
              s = s / 100
              l = l / 100
              local function hueToRgb(p, q, t)
                if t < 0 then
                  t = t + 1
                end
                if t > 1 then
                  t = t - 1
                end
                if t < 1 / 6 then
                  return p + (q - p) * 6 * t
                end
                if t < 1 / 2 then
                  return q
                end
                if t < 2 / 3 then
                  return p + (q - p) * (2 / 3 - t) * 6
                end
                return p
              end
              local q = l < 0.5 and l * (1 + s) or l + s - l * s
              local p = 2 * l - q
              local r = hueToRgb(p, q, h + 1 / 3)
              local g = hueToRgb(p, q, h)
              local b = hueToRgb(p, q, h - 1 / 3)
              return string.format("#%02x%02x%02x", math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
            end

            local hex_color = hslToHex(h, s, l)
            return MiniHipatterns.compute_hex_color_group(hex_color, "bg")
          end,
        },

        -- Highlight rgb() colors
        rgb_color = {
          -- Match rgb values in the format: rgb(<red>, <green>, <blue>)
          pattern = "rgb%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*%)",
          group = function(_, match)
            -- Extract red, green, and blue values from the matched string
            local nr, ng, nb = match:match("rgb%((%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)")
            local r, g, b = tonumber(nr), tonumber(ng), tonumber(nb)

            -- Validate extracted values
            if not (r and g and b) then
              return nil -- Return nil if parsing fails
            end

            -- Convert RGB to Hex color
            local function rgbToHex(r, g, b)
              return string.format("#%02x%02x%02x", r, g, b)
            end

            -- Get the hex color from the RGB values
            local hex_color = rgbToHex(r, g, b)

            -- Use MiniHipatterns to compute a highlight group for the color
            return MiniHipatterns.compute_hex_color_group(hex_color, "bg")
          end,
        },

        -- Highlight rgba() colors
        rgba_color = {
          -- Match rgba values in the format: rgba(<red>, <green>, <blue>, <alpha>)
          pattern = "rgba%(%s*%d+%s*,%s*%d+%s*,%s*%d+%s*,%s*%d*%.?%d+%s*%)",
          group = function(_, match)
            -- Extract red, green, blue, and alpha values from the matched string
            local nr, ng, nb, na = match:match("rgba%((%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d*%.?%d+)%s*%)")
            local r, g, b, a = tonumber(nr), tonumber(ng), tonumber(nb), tonumber(na)

            -- Validate extracted values
            if not (r and g and b and a) then
              return nil -- Return nil if parsing fails
            end

            -- Convert RGB to Hex color (ignoring alpha for now)
            local function rgbToHex(r, g, b)
              return string.format("#%02x%02x%02x", r, g, b)
            end

            local hex_color = rgbToHex(r, g, b)

            -- Use MiniHipatterns to compute a highlight group for the color
            return MiniHipatterns.compute_hex_color_group(hex_color, "bg")
          end,
        },
      },
    },
  },

  -- Set Transparency to editor
  vim.cmd([[
  autocmd VimEnter * highlight Normal guibg=NONE ctermbg=NONE
  autocmd VimEnter * highlight NonText guibg=NONE ctermbg=NONE
]]),
}
