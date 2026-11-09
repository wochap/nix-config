- never add co-authored message commits
- when asking a question, ideally provide options and state your recommendation.

- **No mock-only verification**: Never rely solely on unit tests that mock subprocesses, external tools (FFmpeg, DB, APIs), or only assert generated command strings. String assertions verify syntax formatting, not external tool execution.
- **Mandatory unmocked smoke tests**: When integrating with external tools/engines (e.g. FFmpeg), always write at least one unmocked integration test using fast synthetic fixtures (e.g. 1-second synthetic video) to prove the external tool accepts the command and exits 0.
- **Manual CLI verification before closing tasks**: Before declaring any feature or bugfix done, run the actual CLI command in the terminal with sample or real data and verify that it executes without errors. Passing pytest alone is not sufficient.
