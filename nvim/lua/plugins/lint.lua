return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      php = { "phpcs" },
    },
    linters = {
      phpcs = {
        cmd = "phpcs",
        args = {
          "--standard=" .. vim.fn.expand("$HOME/.config/.phpcs.xml"),
          "--report=json",
          "-q",
          "-s",
          "--basepath=" .. vim.fn.getcwd(),
          "-",
        },
        stdin = true,
        ignore_exitcode = true,
        parser = function(output, bufnr)
          -- If output is empty or contains an error message, return empty diagnostics
          if output == "" or output:match("^ERROR: ") then
            return {}
          end

          -- Attempt to decode JSON
          local ok, decoded = pcall(vim.json.decode, output)
          if not ok or not decoded or not decoded.files then
            return {}
          end

          local diagnostics = {}
          -- Get the first (and usually only) file's messages
          for _, file in pairs(decoded.files) do
            for _, message in ipairs(file.messages or {}) do
              table.insert(diagnostics, {
                lnum = (message.line or 1) - 1,
                col = (message.column or 1) - 1,
                end_lnum = (message.line or 1) - 1,
                end_col = (message.column or 1),
                severity = message.type == "ERROR" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
                message = message.message or "Unknown error",
                source = "phpcs",
              })
            end
          end
          return diagnostics
        end,
      },
    },
  },
}
