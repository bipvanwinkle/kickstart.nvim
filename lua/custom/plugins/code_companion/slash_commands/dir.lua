local SlashCommand = {}

function SlashCommand.new(args)
  local self = setmetatable({
    Chat = args.Chat,
    config = args.config,
    context = args.context,
    opts = args.opts,
  }, { __index = SlashCommand })

  return self
end

function SlashCommand:execute()
  require('telescope.builtin').find_files {
    prompt_title = 'Select Directory',
    find_command = { 'find', '.', '-type', 'd', '-not', '-path', '*/\\.*' },
    attach_mappings = function(prompt_bufnr, map)
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'

      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if not selection then
          return
        end

        local dir_path = selection.value
        dir_path = vim.fn.fnamemodify(dir_path, ':p')
        local files = vim.fn.glob(dir_path .. '/*', false, true)

        -- First append the directory header
        self.Chat:append_to_buf { content = '[!Directory: `' .. dir_path .. '`]\n' }

        local file_count = 0
        for _, file in ipairs(files) do
          if vim.fn.isdirectory(file) ~= 1 then
            local filename = vim.fn.fnamemodify(file, ':t')
            local ft = vim.filetype.match { filename = file } or ''
            local file_content = vim.fn.readfile(file)

            if file_content and #file_content > 0 then
              -- Append each file with proper formatting
              self.Chat:append_to_buf { content = '[!File: `' .. filename .. '`]\n' }
              self.Chat:append_to_buf { content = '```' .. ft .. '\n' .. table.concat(file_content, '\n') .. '```' }
              file_count = file_count + 1
            end
          end
        end

        -- Fold code blocks after adding them all
        self.Chat:fold_code()

        if file_count == 0 then
          vim.notify('No files found in directory: ' .. dir_path, vim.log.levels.INFO, { title = 'CodeCompanion' })
        end
      end)
      return true
    end,
  }
end

return {
  description = 'Share files from a directory',
  callback = SlashCommand,
  opts = {
    contains_code = true,
  },
}
