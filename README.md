# <img title="Icon" width=50 height=50 src="https://github.com/Patitotective/ImThemes/blob/main/assets/icon.png"></img> ImThemes
Dear ImGui theme designer and browser written in Nim

![Browse](https://user-images.githubusercontent.com/79225325/173915188-d17f8246-9ded-4188-a6fc-b8ebce811f07.png)

## Features
- Theme editor.
- Real time theme preview.
- Export to Nim, C++, C# or TOML for [ImStyle](https://github.com/Patitotective/ImStyle).
- Browse and preview themes from the internet.
- Filter by tags.
- Filter by author.
- Star your favorite themes.
- Sort themes alphabetically and by publish date.
- Fork themes.

![Edit](https://user-images.githubusercontent.com/79225325/173915196-7f493bb9-4aa6-4929-8e81-1037ccd8f3aa.png)

## Installation
Go to the [releases page](https://github.com/Patitotective/ImThemes/releases/latest) and download:
- [ImThemes-0.1.2-amd64.AppImage](https://github.com/Patitotective/ImThemes/releases/latest/download/ImThemes-0.1.2-amd64.AppImage) for Linux.
- [ImThemes-0.1.2.zip](https://github.com/Patitotective/ImThemes/releases/latest/download/ImThemes-0.1.2.zip) for Windows.

### Nimble
You can also install it through nimble as a binary package.
```sh
nimble install https://github.com/Patitotective/ImThemes
```

## Publish Your Theme
- Click the _Publish_ button, fill the name and description, add tags, click _Next_ and copy the TOML entry.  
- Paste the copied text at the end of [themes.toml](https://github.com/Patitotective/ImThemes/edit/main/themes.toml) (GitHub should fork it automatically for you).
- [Create a PR](https://github.com/Patitotective/ImThemes/compare/main..main?quick_pull=1&title=Add+Theme:+My+Theme&labels=theme) proposing your changes.
- Automatically `validate_themes.nim` is ran to check whether the themes are valid or not. 

Notes:
- `author` corresponds to the GitHub username of the user making the PR.
- `author` and `date` will be added manually when merging the PR (you can add the `author` yourself as well).

## About
- GitHub: https://github.com/Patitotective/ImThemes.
- Discord: https://discord.gg/as85Q4GnR6.
- Icon Font: https://forkaweso.me (MIT).

Contact me:
- Discord: **Patitotective#0127**.
- Twitter: [@patitotective](https://twitter.com/patitotective).
- Email: **cristobalriaga@gmail.com**.
