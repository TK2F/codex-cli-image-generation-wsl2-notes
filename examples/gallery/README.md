# Public example images from the re-test

This folder contains a small, public-safe subset of the 2026-04-19 re-test
outputs.

These files were not created directly in this folder by Codex. They were
manually copied here after the runs from
`~/.codex/generated_images/<session-id>/...` so readers can compare prompts and
results confirmed in this test environment side by side.

The full raw evidence bundle remains local/private. Only the image files and the
minimum metadata needed for comparison are included here.

## Images

| File | Source test | Prompt summary | Notes |
| --- | --- | --- | --- |
| `blue-sphere-no-enable.png` | 04 | Generate a square blue sphere on a white background. No text, logo, or watermark. | Worked with persisted `image_generation=true` and no `--enable` flag. |
| `blue-sphere-with-enable.png` | 05 | Same blue sphere prompt, but with `--enable image_generation`. | No material behavior difference vs. test 04 in this environment. |
| `edit-black-and-white.png` | 08 | Make the source image black and white while preserving composition and subject. | Edit succeeded, but the printed output path was still not reliable. |
| `blue-sphere-full-auto.png` | 09 | Same blue sphere prompt under `--full-auto -c sandbox_workspace_write.network_access=true`. | `network_access=true` did not change the storage behavior. |
| `cat-portrait-short-prompt.png` | 2026-04-20 short cat prompt | Draw a cat portrait. | Generated from `codex exec --enable image_generation "猫の肖像画を描いて"` and copied from the session-specific generated-images directory. |
| `cat-portrait-codex.png` | 2026-04-18/19 long cat photo prompt | Create a realistic 16:9 cat photo with soft light and natural fur texture. | This is the longer, photo-oriented cat example shown in the top-level README. |

## Prompt records

### `blue-sphere-no-enable.png`

```text
Use the built-in image generation capability only. Generate a square 1:1 image of a blue sphere on a white background. No text, no logo, no watermark. Copy the final image into the current directory as 04-no-enable.png and explicitly state the output path.
```

### `blue-sphere-with-enable.png`

```text
Use the built-in image generation capability only. Generate a square 1:1 image of a blue sphere on a white background. No text, no logo, no watermark. Copy the final image into the current directory as 05-with-enable.png and explicitly state the output path.
```

### `edit-black-and-white.png`

```text
Use the built-in image editing capability only. Make the image black and white while preserving composition and subject. Copy the final image into the current directory as 08-edit-bw.png and explicitly state the output path.
```

### `blue-sphere-full-auto.png`

```text
Use the built-in image generation capability only. Generate a square 1:1 image of a blue sphere on a white background. No text, no logo, no watermark. Copy the final image into the current directory as 09-fullauto.png and explicitly state the output path.
```

### `cat-portrait-short-prompt.png`

```text
猫の肖像画を描いて
```

Session:

```text
019da73e-b8ba-7541-afd3-8ecb6552899d
```

### `cat-portrait-codex.png`

```text
横長 16:9 の写真として、プロのカメラマンがレフ板を使って丁寧に撮影した猫の写真を出力してください。自然な毛並み、やわらかい光、写実的な質感で、文字・ロゴ・透かしは入れないでください。
```

## Reading guide

- Use these images as example outputs confirmed in this test environment, not as normative product behavior.
- The helper script and docs in this repository now assume that the printed
  output path may be wrong and that internal-storage recovery may be required.
- Multi-image and character-reference examples are described in the sample JSON
  files, but those larger reference assets are not bundled into this gallery.
