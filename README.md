# mdutils.nvim
Small personal plugin with utilities for working with Markdown in Neovim. 
Built for my own workflow, not meant to be general-purpose.

- `:Mdutils opener`: Opens the Markdown link (`[text](path)`) under the cursor, dispatches the link by type. If a timestamp (media) or page number (PDF) follows the link, jumps to it.

  | Type | Example | Action |
  |---|---|---|
  | Text | `[x](notes.md)`, `.txt`, other text files | opens in Neovim |
  | PDF | `[doc](file.pdf) 5` | opens at page 5 |
  | Media | `[video](video.mp4) 00:01:23` | opens at that timestamp |
  | Header | `[x](#header)` | jumps to that header in the current file |
  | File + header | `[x](file.md#header)` | opens the file at that header |
  | URL | `[x](https://...)` | opens in the browser |
  | Anything else | `[x](image.png)` | opens with xdg-open |

  It combines two narrower commands:
  - `:Mdutils openLink`: headers, URLs and text files; everything else goes to xdg-open.
  - `:Mdutils openAt`: opens PDFs at specified page, media at timestamp.

- `:Mdutils todo`: Toggles checklist items status: `[ ] → [-] → [X] → [ ]`.

<details>
<summary>More info</summary>

- **Linux only**: non-text files and URLs are opened with `xdg-open`.
- **PDF viewers** (first one found): `zathura`, `papers`, `evince`, `okular`. Otherwise `xdg-open`, without jumping to the page.
- **Media players** (first one found): `mpv`, `vlc`. Otherwise `xdg-open`, without jumping to the timestamp.
- **Paths** are relative to the current file; `~` and `$VARS` are expanded, `%20` is decoded as a space.
- `\#` escapes a literal `#` in a path: `[x](notes\#1.md#header)`.

</details>
