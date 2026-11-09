-- TypeScript/JavaScript via vtsls (LazyVim lang.typescript extra defaults).
---@type vim.lsp.Config
local typescript = {
  updateImportsOnFileMove = { enabled = "always" },
  suggest = {
    completeFunctionCalls = true,
  },
  inlayHints = {
    enumMemberValues = { enabled = true },
    functionLikeReturnTypes = { enabled = true },
    parameterNames = { enabled = "literals" },
    parameterTypes = { enabled = true },
    propertyDeclarationTypes = { enabled = true },
    variableTypes = { enabled = false },
  },
}

---@param command lsp.Command
---@param ctx { bufnr: integer, client_id: integer }
local function move_to_file(command, ctx)
  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if not client then
    return
  end

  ---@type string, string, lsp.Range
  local action, uri, range = table.unpack(command.arguments)

  local function move(newf)
    client:request("workspace/executeCommand", {
      command = command.command,
      arguments = { action, uri, range, newf },
    })
  end

  local fname = vim.uri_to_fname(uri)
  client:request("workspace/executeCommand", {
    command = "typescript.tsserverRequest",
    arguments = {
      "getMoveToRefactoringFileSuggestions",
      {
        file = fname,
        startLine = range.start.line + 1,
        startOffset = range.start.character + 1,
        endLine = range["end"].line + 1,
        endOffset = range["end"].character + 1,
      },
    },
  }, function(_, result)
    local files = result.body.files
    table.insert(files, 1, "Enter new path...")
    vim.ui.select(files, {
      prompt = "Select move destination:",
      format_item = function(f)
        return vim.fn.fnamemodify(f, ":~:.")
      end,
    }, function(f)
      if f and f:find("^Enter new path") then
        vim.ui.input({
          prompt = "Enter move destination:",
          default = vim.fn.fnamemodify(fname, ":h") .. "/",
          completion = "file",
        }, function(newf)
          return newf and move(newf)
        end)
      elseif f then
        move(f)
      end
    end)
  end)
end

---@param client vim.lsp.Client
---@param bufnr integer
local function on_attach(client, bufnr)
  ---@param params lsp.ExecuteCommandParams
  local function lsp_command(params)
    return function()
      require("trouble").open({ mode = "lsp_command", params = params })
    end
  end

  local pos = vim.lsp.util.make_position_params(0, "utf-16")

  vim.keymap.set(
    "n",
    "gD",
    lsp_command({
      command = "typescript.goToSourceDefinition",
      arguments = { pos.textDocument.uri, pos.position },
    }),
    { buffer = bufnr, desc = "Goto Source Definition", silent = true }
  )

  vim.keymap.set(
    "n",
    "gR",
    lsp_command({
      command = "typescript.findAllFileReferences",
      arguments = { vim.uri_from_bufnr(bufnr) },
    }),
    { buffer = bufnr, desc = "File References", silent = true }
  )

  vim.keymap.set("n", "<leader>cM", function()
    vim.lsp.buf.code_action({
      apply = true,
      context = { only = { "source.addMissingImports.ts" }, diagnostics = {} },
    })
  end, { buffer = bufnr, desc = "Add missing imports", silent = true })

  vim.keymap.set("n", "<leader>cD", function()
    vim.lsp.buf.code_action({
      apply = true,
      context = { only = { "source.fixAll.ts" }, diagnostics = {} },
    })
  end, { buffer = bufnr, desc = "Fix all diagnostics", silent = true })

  vim.keymap.set("n", "<leader>cV", function()
    client:exec_cmd({ command = "typescript.selectTypeScriptVersion" }, { bufnr = bufnr })
  end, { buffer = bufnr, desc = "Select TS workspace version", silent = true })
end

return {
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  settings = {
    complete_function_calls = true,
    vtsls = {
      enableMoveToFileCodeAction = true,
      autoUseWorkspaceTsdk = true,
      experimental = {
        maxInlayHintLength = 30,
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
    },
    typescript = typescript,
    -- vtsls ignores `typescript` settings for JS buffers unless mirrored.
    javascript = vim.deepcopy(typescript),
  },
  commands = {
    ["_typescript.moveToFileRefactoring"] = move_to_file,
  },
  on_attach = on_attach,
}
