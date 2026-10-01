# mdutils.nvim
Small personal plugin with utilities for working with Markdown in Neovim. 
Built for my own workflow, not meant to be general-purpose.

- `:Mdutils openLink` - Opens Markdown-style links (`[text](path)`) under the cursor. Uses Neovim for text files, xdg-open for other mimetypes.
- `:Mdutils todo` - Toggles checklist items status: `[ ] → [-] → [X] → [ ]`.
- `:Mdutils openAt` - Opens a Markdown link at a specific position:
  - **Media** `[video](path/to/video.mp4) 00:01:23` — opens at timestamp.
  - **PDF** `[doc](path/to/file.pdf) 5` — opens at specific page.
- `:Mdutils opener` - `openLink` + `openAt` in one: dispatches the link by type. If a timestamp (media) or page number (PDF) follows the link, jumps to it.
