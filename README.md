# mdutils.nvim
Small personal plugin with utilities for working with Markdown in Neovim. 

- `:Mdutils opener`: Opens the Markdown link (`[text](path)`) under the cursor, dispatches the link by type. If a timestamp (media) or page number (PDF) follows the link, jumps to it.

  | Type | Example | Action |
  |---|---|---|
  | Text | `[x](notes.md)`, `.txt`, other text files | opens in Neovim |
  | PDF | `[doc](file.pdf) 5` | opens at page 5 |
  | Media | `[video](video.mp4) 00:01:23` | opens at that timestamp |
  | Header | `[x](#header)` | jumps to that header in the current file |
  | File + header | `[x](file.md#header)` | opens the file at that header |
  | URL | `[x](https://...)` | opens in the browser |
  | Anything else | `[x](image.png)` | opens with system default app |

- `:Mdutils todo`: Toggles checklist items status: `[ ] → [-] → [X] → [ ]`.

- `:Mdutils headers`: Lists the buffer's Markdown headers in the quickfix list.

<details>
<summary>More info</summary>

- **PDF viewers** (first one found): `zathura`, `papers`, `evince`, `atril`, `xreader`, `okular`, `sioyek`. Otherwise the system default app, without jumping to the page.
- **Media players** (first one found): `mpv`, `iina`, `vlc`. Otherwise the system default app, without jumping to the timestamp.
- **Paths** are relative to the current file; `~` and `$VARS` are expanded, `%XX` escapes are decoded (`%20` → space).
- `\#` escapes a literal `#` in a path: `[x](notes\#1.md#header)`.

</details>
