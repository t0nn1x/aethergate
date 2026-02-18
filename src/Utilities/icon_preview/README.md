# Icon Preview Tool

This small tool helps preview all PNGs under `Assets/Icons`.

Usage
- Generate the manifest (requires Node.js):

```bash
node tools/icon_preview/generate_manifest.js
```

The script writes `tools/icon_preview/images.json`.

- Open the preview page in your browser:

Open [icon_preview.html](icon_preview.html) (double-click or use your browser to open the file). The page will load the manifest and show thumbnails grouped by top-level folder.

Notes
- If you add or remove icons, re-run the generator and click "Reload manifest" on the page.
- The page loads images directly from the workspace file paths (`Assets/Icons/...`).
