# AGENTS.md

## Before coding

Always read these files first:

1. `skills/`
   - Understand project-specific coding rules, conventions, and requirements.
   - Follow the instructions inside relevant skill files before making changes.

2. `.codegraph/`
   - Check `codegraph.db` if available.
   - Use it to understand module relationships, dependencies, and possible impact before editing code.

3. `CLAUDE.md`

## Coding rules

- Do not start coding before reviewing the relevant skill instructions.
- Prefer existing project structure and naming conventions.
- Keep changes small, focused, and consistent with the current codebase.
- Reuse existing widgets, services, models, and utilities when possible.
- Avoid duplicating logic.
- Do not introduce unnecessary dependencies.
- After coding, review affected files for:
  - compile errors
  - broken imports
  - inconsistent naming
  - duplicated code
  - unused code

## Flutter-specific rules

- Keep UI code clean and componentized.
- Put reusable widgets in appropriate folders.
- Keep business logic out of widgets when possible.
- Use existing state management style already used in the project.
- Do not hardcode secrets, API keys, or Supabase credentials directly in code.

## Lesson audio rules

- For lesson auto-read flows on iOS web, do not autoplay multiple separate voice files in sequence (question, card A, card B). iOS Safari may mute later clips even when the UI highlight advances.
- When a lesson needs automatic narration across the question and choice cards, create one combined narration asset per lesson in M4A/AAC format (44.1 kHz stereo) and use it for the iOS web autoplay path.
- Keep individual voice files available for manual tap-to-replay on each question/card.
- Combined narration should include the question, a short pause, choice A, a short pause, and choice B. Keep UI highlight timing in sync with cue durations.
- Use the `audio/mp4` MIME type for `.m4a` narration assets and `audio/mpeg` for `.mp3` assets.

## Supabase rules

- Store uploaded files in Supabase Storage.
- Store only public URL or storage path in database.
- Do not expose service role keys in Flutter.
- Use authenticated policies for upload/update/delete.
- Use public read policy only when files are meant to be public.

## Final check

Before finishing, summarize:
- files changed
- reason for changes
- anything the developer must configure manually
