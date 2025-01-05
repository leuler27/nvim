local M = {}

-- Bind keymap
function M.map(mode, keys, command, opts)
  local default_options = { silent = true }
  -- merge default + user opts
  local options = vim.tbl_extend('force', default_options, opts or {})

  if type(keys) == 'table' then
    for _, keymap in ipairs(keys) do
      M.map(mode, keymap, command, options)
    end
    return
  end

  vim.keymap.set(mode, keys, command, opts)
end

-- Get home dir ($HOME)
function M.get_homedir()
  return os.getenv 'HOME'
end

-- function M.map(mode, lhs, rhs)
--	vim.api.nvim_set_keymap(mode, lhs, rhs, { silent = true })
-- end

function M.noremap(mode, lhs, rhs)
  vim.api.nvim_set_keymap(mode, lhs, rhs, { noremap = true, silent = true })
end

function M.exprnoremap(mode, lhs, rhs)
  vim.api.nvim_set_keymap(mode, lhs, rhs, { noremap = true, silent = true, expr = true })
end

-- Useful mode-specific shortcuts
-- nomenclature: "<expr?><mode><nore?>map(lhs, rhs)" where:
--      "expr?" optional expr option
--      "nore?" optional no-remap option
--      modes -> 'n' = NORMAL, 'i' = INSERT, 'x' = 'VISUAL', 'v' = VISUAL + SELECT, 't' = TERMINAL

function M.nmap(lhs, rhs)
  M.map('n', lhs, rhs)
end

function M.xmap(lhs, rhs)
  M.map('x', lhs, rhs)
end

function M.nnoremap(lhs, rhs)
  M.noremap('n', lhs, rhs)
end

function M.vnoremap(lhs, rhs)
  M.noremap('v', lhs, rhs)
end

function M.xnoremap(lhs, rhs)
  M.noremap('x', lhs, rhs)
end

function M.inoremap(lhs, rhs)
  M.noremap('i', lhs, rhs)
end

function M.tnoremap(lhs, rhs)
  M.noremap('t', lhs, rhs)
end

function M.exprnnoremap(lhs, rhs)
  M.exprnoremap('n', lhs, rhs)
end

function M.exprinoremap(lhs, rhs)
  M.exprnoremap('i', lhs, rhs)
end

M.load_on_file_open = function(plugin)
  vim.api.nvim_create_autocmd({ 'BufRead', 'BufWinEnter', 'BufNewFile' }, {
    group = vim.api.nvim_create_augroup('BeLazyOnFileOpen' .. plugin, {}),
    callback = function()
      local file = vim.fn.expand '%'
      local condition = file ~= 'NvimTree_1' and file ~= '[lazy]' and file ~= ''

      if condition then
        vim.api.nvim_del_augroup_by_name('BeLazyOnFileOpen' .. plugin)

        -- dont defer for treesitter as it will show slow highlighting
        -- This deferring only happens only when we do "nvim filename"
        if plugin ~= 'nvim-treesitter' then
          vim.schedule(function()
            require('lazy').load { plugins = plugin }
            if plugin == 'nvim-lspconfig' then
              vim.cmd 'silent! do FileType'
            end
          end, 0)
        else
          require('lazy').load { plugins = plugin }
        end
      end
    end,
  })
end

M.load_on_repo_open = function(plugin)
  vim.api.nvim_create_autocmd({ 'BufRead' }, {
    group = vim.api.nvim_create_augroup('BeLazyLoadOnGitRepoOpen' .. plugin, { clear = true }),
    callback = function()
      vim.fn.system('git -C ' .. '"' .. vim.fn.expand '%:p:h' .. '"' .. ' rev-parse')
      if vim.v.shell_error == 0 then
        vim.api.nvim_del_augroup_by_name('BeLazyLoadOnGitRepoOpen' .. plugin)
        vim.schedule(function()
          require('lazy').load { plugins = plugin }
        end)
      end
    end,
  })
end

return M
