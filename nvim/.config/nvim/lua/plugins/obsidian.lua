return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    lazy = true,
    event = {
      "BufReadPre " .. vim.env.HOME .. "/vault/**.md",
      "BufNewFile " .. vim.env.HOME .. "/vault/**.md",
    },
    cmd = { "Obsidian" },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = "vault",
          path = "~/vault",
        },
      },
      notes_subdir = "1-fleeting",
      new_notes_location = "notes_subdir",
      daily_notes = {
        folder = "0-daily",
        date_format = "%Y-%m-%d",
        template = "daily.md",
      },
      templates = {
        folder = "8-templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
        customizations = {
          literature = { notes_subdir = "2-literature" },
          permanent = { notes_subdir = "3-permanent" },
          writing = { notes_subdir = "4-writing" },
          ["project-charter"] = { notes_subdir = "5-projects" },
          meeting = { notes_subdir = "6-meetings" },
          index = { notes_subdir = "7-index" },
          review = { notes_subdir = "0-daily" },
        },
      },
      note = {
        template = "fleeting.md",
      },
      completion = {
        blink = true,
        nvim_cmp = false,
        min_chars = 2,
      },
      ui = {
        enable = false,
      },
      attachments = {
        folder = "9-assets",
      },
      note_id_func = function(title)
        if title ~= nil then
          return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        end
        return tostring(os.time())
      end,
    },
    keys = {
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New note" },
      { "<leader>oN", "<cmd>Obsidian new_from_template<cr>", desc = "New from template" },
      { "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "Find note" },
      { "<leader>od", "<cmd>Obsidian today<cr>", desc = "Daily note" },
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search vault" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
      { "<leader>ot", "<cmd>Obsidian template<cr>", desc = "Insert template" },
      { "<leader>ol", "<cmd>Obsidian links<cr>", desc = "Links" },
      { "<leader>op", "<cmd>Obsidian paste_img<cr>", desc = "Paste image" },
    },
  },
}
