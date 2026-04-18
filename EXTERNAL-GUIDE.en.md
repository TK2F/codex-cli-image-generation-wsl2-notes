# External Guide

This guide is the external-facing summary of what was validated, what the package is meant to solve, and what the receiver should realistically expect.

Validated by:

- TK2LAB
- Codex

Tested on:

- 2026-04-19
- `codex-cli 0.121.0`

## Purpose

The package exists to make Codex image-generation and image-edit batch work usable in a real WSL2 Ubuntu environment without forcing users to understand the original author's machine layout.

## What Was Kept

- the runner script
- working sample JSON files
- beginner-focused setup and operation instructions
- the practical lessons learned from testing the workflow

## What Was Verified

- the runner parses and prints help successfully
- the runner supports preview mode
- the runner supports doctor mode
- the runner can detect `codex` via `PATH`, nvm fallback, or explicit `CODEX_BIN`
- the runner accepts Linux paths, Windows drive paths, and common WSL UNC paths
- preview mode still works even if output files already exist
- summary and log references prefer relative paths when possible

## Practical Operating Model

Recommended order:

1. Run `--doctor`
2. Run `--preview`
3. Run a sample batch
4. Adapt or replace the sample JSON
5. Use manual mode only when one-off work is faster than editing JSON

## Safe Defaults

- real runs require confirmation unless `--no-prompt` is used
- existing output files are skipped unless `--overwrite` is used
- failed jobs can retry
- failed jobs do not stop the whole batch unless `--stop-on-job-error` is used

## Known Limits

- this package is for the WSL2 Ubuntu shell workflow that was actually validated, not native Windows PowerShell execution
- it does not install Codex or system dependencies for the user
- actual image quality and generation behavior still depend on the Codex CLI and model behavior at runtime
- fallback recovery from `~/.codex/generated_images` is best effort, not a guaranteed substitute for a clean Codex copy-out

## When to Extend the Package

Consider custom additions when you need:

- team-specific JSON templates
- stronger naming conventions
- additional style presets
- wrapper scripts for CI or automation
- a zipped release process with checksums or signed artifacts
