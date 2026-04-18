Put your own edit-source images in this folder if you want to try the edit sample JSON as-is.

Expected example filenames:

- `product.png`
- `portrait.png`
- `base.png`
- `reference.png`
- `character-main.png`
- `character-detail.png`

You can also change the JSON to point to any other files you want.

Notes:

- `codex-image-batch.sample.json` includes a multi-reference character example
  that uses `reference_images`.
- In this helper, `reference_images` is an alias for "additional images to pass
  after any `input_image` / `input_images` entries". The base/reference meaning
  still needs to be written into the prompt itself.
