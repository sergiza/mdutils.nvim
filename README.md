# mdutils.nvim
Small personal plugin with utilities for working with Markdown in Neovim. 
Built for my own workflow, not meant to be general-purpose.

- `:Mdutils opener` - Opens Markdown-style links (`[text](path)`) under the cursor. Uses Neovim for text files, xdg-open for other mimetypes.
- `:Mdutils todo` - Toggles checklist items status: `[ ] → [-] → [X] → [ ]`.
- `:Mdutils mediaplayer` - Opens video at a specific timestamp `(path/to/video.mp4) 00:01:23`. Uses mpv.
