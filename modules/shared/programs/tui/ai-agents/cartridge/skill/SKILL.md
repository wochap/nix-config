---
name: cartridge
description: Load language context cartridges (gotchas, correct APIs, idioms) before a coding task. Usage /cartridge <name> [name...].
disable-model-invocation: true
---

# cartridge

A cartridge is a short markdown file with rules for one language or tool.
The user gave cartridge names as arguments (text after the command, maybe as `User: ...`).

Available: bash, cpp, go, javascript, lua, nix, nixos-options, nodejs, nvim-lua, python, rust, typescript, zig

Follow these steps exactly:

1. Take each word of the arguments that is in the Available list. Other words are the task.
2. For each name, use the read tool on `cartridges/<name>.md` in this skill directory.
   Example: `nix` means read `cartridges/nix.md`.
3. Read ALL listed cartridges before you do anything else. Do not skip any.
4. If a name is not in the Available list, or there are no names, show the Available list and stop.
5. After reading, reply with one line: `Loaded: <names>`.
6. If there is task text, do the task now. If not, wait for the user's task.
7. For the rest of the session, cartridge rules win over your own habits.
