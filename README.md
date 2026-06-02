# Runkun

Runkun is a native macOS menu bar runner inspired by the spirit of RunCat. CPU usage controls how fast the runner moves, and the runner itself is editable through a small JSON pixel-art format.

## Features

- Native macOS menu bar app built with Swift and AppKit.
- Runner animation speed follows CPU usage.
- Default runner uses bundled Kun PNG frames.
- Menu shows CPU usage, memory usage, battery status, and network throughput.
- Customizable runner frames and colors through `runner.json`.
- GitHub Actions workflow builds and uploads a packaged `.app` zip.

## Build locally

```bash
swift build -c release
```

## Package as an app

```bash
bash scripts/package_app.sh release
open .build/Runkun.app
```

The package script creates:

- `.build/Runkun.app`
- `.build/Runkun.zip`

## Customize the runner

Launch Runkun once, then use the menu item `Open Runner Folder`. Edit:

```text
~/Library/Application Support/Runkun/runner.json
```

Each frame is a grid of characters. `.` and spaces are transparent. Every other character maps to a color in `palette`.

```json
{
  "name": "My Runner",
  "palette": {
    "K": "#222222",
    "S": "#F6C36B",
    "B": "#2F80ED"
  },
  "frames": [
    {
      "rows": [
        "....SSSS....",
        "...S....S...",
        "....BBBB...."
      ]
    }
  ]
}
```

After editing, choose `Reload Runner` from the menu.

## GitHub packaging

Push to `main` to build an artifact. Push a tag like this to create a GitHub release:

```bash
git tag v0.1.0
git push origin main --tags
```
