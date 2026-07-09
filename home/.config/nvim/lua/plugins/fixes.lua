-- Local health/behaviour fixes for this machine (foot terminal, Fedora Sericea).
return {
  -- foot does not support the kitty graphics protocol, so snacks image rendering
  -- (and its mermaid/LaTeX/kitty checkhealth errors) can never work here. Disable it.
  {
    "folke/snacks.nvim",
    opts = {
      image = { enabled = false },
    },
  },
}
