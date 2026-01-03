return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        fish = { "fish_indent" },
        python = { "isort", "black" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        liquid = { "prettier" },
        php = { "php_smart_formatter" },
        ["_"] = { "trim_whitespace" },
      },
      formatters = {
        php_smart_formatter = {
          command = function(ctx)
            -- Enhanced WordPress detection with directory traversal
            local function is_wordpress_project()
              -- Function to traverse up directory tree looking for WordPress indicators
              local function traverse_up_for_wordpress(start_dir, max_depth)
                local current_dir = start_dir
                local depth = 0
                
                while current_dir ~= "" and depth < max_depth do
                  -- Check for wp-config.php
                  if vim.fn.filereadable(current_dir .. "/wp-config.php") == 1 then
                    return true
                  end
                  
                  -- Check for wp-content directory
                  if vim.fn.isdirectory(current_dir .. "/wp-content") == 1 then
                    return true
                  end
                  
                  -- Check if we're inside wp-content/themes (common theme location)
                  local parent = vim.fn.fnamemodify(current_dir, ":h")
                  local grandparent = vim.fn.fnamemodify(parent, ":h")
                  local greatgrandparent = vim.fn.fnamemodify(grandparent, ":h")
                  
                  -- Check for the pattern: wp-root/wp-content/themes/theme-name
                  if vim.fn.fnamemodify(parent, ":t") == "themes" and 
                     vim.fn.fnamemodify(grandparent, ":t") == "wp-content" and
                     greatgrandparent ~= grandparent and 
                     vim.fn.filereadable(greatgrandparent .. "/wp-config.php") == 1 then
                    return true
                  end
                  
                  current_dir = vim.fn.fnamemodify(current_dir, ":h")
                  depth = depth + 1
                end
                
                return false
              end
              
              -- First, try directory traversal up to reasonable depth
              if traverse_up_for_wordpress(vim.fn.getcwd(), 8) then
                return true
              end
              
              -- Check composer.json for WordPress dependencies (traverses up automatically)
              local composer_path = vim.fn.findfile("composer.json", ".;")
              if composer_path ~= "" then
                local content = table.concat(vim.fn.readfile(composer_path), "\n")
                if content:match('"wpcs"') or content:match('"wordpress"') or 
                   content:match('"wp%-cli"') or content:match('"roots/wordpress"') or
                   content:match('"johnpbloch/wordpress"') then
                  return true
                end
              end
              
              -- Check for phpcs.xml with WordPress rules (traverses up automatically)
              local phpcs_path = vim.fn.findfile("phpcs.xml", ".;")
              if phpcs_path ~= "" then
                local content = table.concat(vim.fn.readfile(phpcs_path), "\n")
                if content:match("WordPress") then
                  return true
                end
              end
              
              return false
            end
            
            local is_wordpress = is_wordpress_project()
            local has_php_cs_fixer = vim.fn.executable("php-cs-fixer") == 1
            local has_phpcbf = vim.fn.executable("phpcbf") == 1
            
            -- Default to phpcbf for WordPress projects, fallback to php-cs-fixer
            if is_wordpress and has_phpcbf then
              return "phpcbf"
            elseif has_php_cs_fixer then
              return "php-cs-fixer"
            elseif has_phpcbf then
              return "phpcbf"
            else
              return "echo" -- fallback that does nothing
            end
          end,
          args = function(ctx)
            local formatter = ctx.command
            
            if formatter == "phpcbf" then
              -- Use the configured phpcs.xml if it exists, otherwise WordPress standard
              local phpcs_config = vim.fn.expand("$HOME/.config/.phpcs.xml")
              if vim.fn.filereadable(phpcs_config) == 1 then
                return {
                  "--standard=" .. phpcs_config,
                  "--no-cache",
                  "$FILENAME"
                }
              else
                return {
                  "--standard=WordPress",
                  "--no-cache",
                  "$FILENAME"
                }
              end
            elseif formatter == "php-cs-fixer" then
              -- Check for project config in current directory and parents
              local config_files = {
                ".php-cs-fixer.php",
                ".php-cs-fixer.dist.php", 
                "php-cs-fixer.php"
              }
              
              local has_config = false
              for _, file in ipairs(config_files) do
                if vim.fn.findfile(file, ".;") ~= "" then
                  has_config = true
                  break
                end
              end
              
              if has_config then
                return { "fix", "--using-cache=no", "--allow-risky=no", "$FILENAME" }
              else
                return { "fix", "--using-cache=no", "--allow-risky=no", "--rules=@PSR12", "$FILENAME" }
              end
            else
              return { "$FILENAME" }
            end
          end,
          stdin = false,
        },
      },
    },
  },
}