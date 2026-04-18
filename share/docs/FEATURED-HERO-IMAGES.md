# Featured Hero Images Plan

This file defines the two top-page landscape images that are intended to appear
 near the top of the shared package once they are generated and manually
 reviewed.

These images are **not bundled yet** in this repository snapshot because they
 have not been re-generated and checked in this session. The goal is to avoid
 claiming "observed output" for files that were not actually re-tested.

## Target files

- `share/examples/gallery/hero-sci-fi-landscape.png`
- `share/examples/gallery/hero-emotive-photo-landscape.png`

## Recommended prompts

### 1. Sci-fi landscape

```text
Use the built-in image generation capability only. Create a wide cinematic sci-fi landscape image of a futuristic desert city at dusk, with layered architecture, atmospheric haze, glowing transit lines, and a strong sense of scale. No text, no logo, no watermark.
```

Suggested command:

```bash
printf '%s\n' 'Use the built-in image generation capability only. Create a wide cinematic sci-fi landscape image of a futuristic desert city at dusk, with layered architecture, atmospheric haze, glowing transit lines, and a strong sense of scale. No text, no logo, no watermark.' | codex exec --skip-git-repo-check -
```

### 2. Emotive photoreal landscape

```text
Use the built-in image generation capability only. Create a wide photoreal cinematic image of an emotional quiet roadside moment after rain at blue hour, with natural reflections, soft practical lights, documentary-like realism, and no text, no logo, no watermark.
```

Suggested command:

```bash
printf '%s\n' 'Use the built-in image generation capability only. Create a wide photoreal cinematic image of an emotional quiet roadside moment after rain at blue hour, with natural reflections, soft practical lights, documentary-like realism, and no text, no logo, no watermark.' | codex exec --skip-git-repo-check -
```

## Placement workflow

1. Run one prompt at a time.
2. Copy the resulting PNG from `~/.codex/generated_images/<session-id>/`.
3. Strip metadata before committing.
4. Save the files at the exact target paths above.
5. Add the exact prompt text and the observation date to
   `share/examples/gallery/README.md`.

## Metadata note

If you regenerate these images locally, strip metadata before replacing the
 files in `share/examples/gallery/`.

On this machine, `mogrify -strip <file>.png` works.
