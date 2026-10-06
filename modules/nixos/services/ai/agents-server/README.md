# agents-server

OpenAI-compatible API (`/v1/chat/completions`, `/v1/models`) over the
`agents` CLI (`packages/agents`), so chat GUIs can talk to the local coding
agents (`claude`, `pi`). Runs `agents serve` as the user service
`agents-server`, behind the lazy web proxy `https://agents.wochap.local`.

```nix
_custom.services.ai.agentsServer.enable = true;
# optional
_custom.services.ai.agentsServer.cwd = "/home/gean/work";   # where runs happen
_custom.services.ai.agentsServer.models = [ "claude/claude-sonnet-5" "pi/omniroute/desktop-free" ];
_custom.services.ai.agentsServer.noTools = false;   # let the agents use tools
_custom.services.ai.agentsServer.toolEvents = false;
```

## Use

- Base URL `https://agents.wochap.local/v1`, any API key. In open-webui:
  Settings, Connections, OpenAI API, add the URL with a dummy key.
- Model ids are `<agent>/<model>`, split at the first `/`; any model the
  agent accepts works, not only the listed ones. A bare `claude` or `pi`
  uses the agent's default model.
- `reasoning_effort` `low`, `medium`, `high`, `xhigh`, `max` maps to
  `agents run -e`; `none`, `minimal` or unset keep the agent's setting.
- Streaming sends whole agent messages as they land, plus tool calls as
  `_> label_` lines when `toolEvents` is on.

## Sessions

Each chat is a normal `agents` session in `cwd`. A follow-up resumes the
same session (matched on the chat history), so `agents ls`, `agents watch
<id>` and `agents attach <id>` work on chats from the GUI. The completion
id is `chatcmpl-<session id>`. Editing or regenerating an earlier message
starts a new session with the history flattened into the prompt.

By default the runs get no tools (`noTools`, `agents run --no-tools`): the
agents only answer, nothing runs in `cwd`. With `noTools = false` they run
with the same permissions as in a terminal (`CLAUDE_FLAGS` default
`--permission-mode auto`; pi has no permission prompts) and never wait for
approval, so treat the endpoint like a shell: it listens on the local
address only.

```sh
systemctl --user status agents-server
journalctl --user -u agents-server -f
curl https://agents.wochap.local/v1/models
```
