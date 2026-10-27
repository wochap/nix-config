import { describe, expect, test } from "bun:test";
import {
  buildToolInstructions,
  flatten,
  fp,
  parseToolCalls,
  plan,
  type Message,
  type ToolDef,
} from "../src/serve";

describe("fp (fingerprinting)", () => {
  test("hashes role and text", () => {
    const m1: Message[] = [{ role: "user", content: "hello" }];
    const m2: Message[] = [{ role: "user", content: "hello" }];
    expect(fp("model1", m1)).toBe(fp("model1", m2));
  });

  test("does not collide for assistant messages with different tool_calls", () => {
    const m1: Message[] = [
      {
        role: "assistant",
        content: null,
        tool_calls: [
          {
            id: "call_1",
            type: "function",
            function: { name: "get_weather", arguments: '{"location":"SF"}' },
          },
        ],
      },
    ];
    const m2: Message[] = [
      {
        role: "assistant",
        content: null,
        tool_calls: [
          {
            id: "call_2",
            type: "function",
            function: { name: "get_weather", arguments: '{"location":"NYC"}' },
          },
        ],
      },
    ];
    expect(fp("model1", m1)).not.toBe(fp("model1", m2));
  });
});

describe("flatten", () => {
  test("flattens user and assistant messages", () => {
    const messages: Message[] = [
      { role: "user", content: "What is 2+2?" },
      { role: "assistant", content: "4" },
    ];
    const res = flatten(messages);
    expect(res).toBe("user: What is 2+2?\n\nassistant: 4");
  });

  test("formats assistant tool_calls and tool results with xml tags", () => {
    const messages: Message[] = [
      { role: "user", content: "What is the weather in SF?" },
      {
        role: "assistant",
        content: "Checking weather...",
        tool_calls: [
          {
            id: "call_123",
            type: "function",
            function: { name: "get_weather", arguments: '{"location":"SF"}' },
          },
        ],
      },
      {
        role: "tool",
        tool_call_id: "call_123",
        content: '{"temp": 68}',
      },
    ];
    const res = flatten(messages);
    expect(res).toContain("user: What is the weather in SF?");
    expect(res).toContain(
      'assistant: Checking weather...\n<tool_call>{"name":"get_weather","arguments":{"location":"SF"}}</tool_call>',
    );
    expect(res).toContain('<tool_result name="get_weather" id="call_123">\n{"temp": 68}\n</tool_result>');
  });
});

describe("parseToolCalls", () => {
  const tools: ToolDef[] = [
    {
      type: "function",
      function: {
        name: "get_weather",
        description: "Get weather",
        parameters: {
          type: "object",
          properties: { location: { type: "string" } },
          required: ["location"],
        },
      },
    },
    {
      type: "function",
      function: {
        name: "calculate",
        description: "Math",
      },
    },
  ];

  test("parses single tool call", () => {
    const raw =
      'I will check the weather.\n<tool_call>{"name": "get_weather", "arguments": {"location": "San Francisco"}}</tool_call>';
    const parsed = parseToolCalls(raw, tools);
    expect(parsed.content).toBe("I will check the weather.");
    expect(parsed.toolCalls.length).toBe(1);
    expect(parsed.toolCalls[0].function.name).toBe("get_weather");
    expect(JSON.parse(parsed.toolCalls[0].function.arguments)).toEqual({ location: "San Francisco" });
    expect(parsed.toolCalls[0].id).toMatch(/^call_[a-f0-9]{24}$/);
  });

  test("handles missing closing tag at end of string", () => {
    const raw =
      '<tool_call>{"name": "get_weather", "arguments": {"location": "San Francisco"}}';
    const parsed = parseToolCalls(raw, tools);
    expect(parsed.content).toBeNull();
    expect(parsed.toolCalls.length).toBe(1);
    expect(parsed.toolCalls[0].function.name).toBe("get_weather");
  });

  test("handles fenced json inside tag", () => {
    const raw =
      '<tool_call>\n```json\n{"name": "get_weather", "arguments": {"location": "Tokyo"}}\n```\n</tool_call>';
    const parsed = parseToolCalls(raw, tools);
    expect(parsed.toolCalls.length).toBe(1);
    expect(parsed.toolCalls[0].function.name).toBe("get_weather");
    expect(JSON.parse(parsed.toolCalls[0].function.arguments)).toEqual({ location: "Tokyo" });
  });

  test("filters out unknown tools", () => {
    const raw =
      '<tool_call>{"name": "unknown_function", "arguments": {}}</tool_call>';
    const parsed = parseToolCalls(raw, tools);
    expect(parsed.toolCalls.length).toBe(0);
    expect(parsed.content).toBe(raw);
  });

  test("validates required parameters", () => {
    // get_weather requires location
    const raw = '<tool_call>{"name": "get_weather", "arguments": {}}</tool_call>';
    const parsed = parseToolCalls(raw, tools);
    expect(parsed.toolCalls.length).toBe(0);
    expect(parsed.content).toBe(raw);
  });

  test("handles parallel tool calls and parallel: false", () => {
    const raw =
      '<tool_call>{"name": "calculate", "arguments": {"x": 1}}</tool_call>\n<tool_call>{"name": "calculate", "arguments": {"x": 2}}</tool_call>';
    const parsedParallel = parseToolCalls(raw, tools, true);
    expect(parsedParallel.toolCalls.length).toBe(2);

    const parsedSerial = parseToolCalls(raw, tools, false);
    expect(parsedSerial.toolCalls.length).toBe(1);
    expect(JSON.parse(parsedSerial.toolCalls[0].function.arguments)).toEqual({ x: 1 });
  });

  test("falls back to full text if no valid tool calls found", () => {
    const raw = "Just normal conversational text without tool calls.";
    const parsed = parseToolCalls(raw, tools);
    expect(parsed.content).toBe(raw);
    expect(parsed.toolCalls.length).toBe(0);
  });
});

describe("buildToolInstructions", () => {
  const tools: ToolDef[] = [
    {
      type: "function",
      function: { name: "search", description: "Search web" },
    },
    {
      type: "function",
      function: { name: "calc", description: "Calculate" },
    },
  ];

  test("builds auto instructions", () => {
    const prompt = buildToolInstructions(tools, "auto", true, "claude");
    expect(prompt).toContain("<functions>");
    expect(prompt).toContain('"name": "search"');
    expect(prompt).toContain('"name": "calc"');
    expect(prompt).toContain("<tool_call>");
  });

  test("adds required notice for required choice", () => {
    const prompt = buildToolInstructions(tools, "required", true, "claude");
    expect(prompt).toContain("You MUST call at least one function.");
  });

  test("restricts to named function for named choice", () => {
    const prompt = buildToolInstructions(
      tools,
      { type: "function", function: { name: "calc" } },
      true,
      "claude",
    );
    expect(prompt).toContain("You MUST call function 'calc'.");
    expect(prompt).toContain('"name": "calc"');
    expect(prompt).not.toContain('"name": "search"');
  });

  test("adds agy specific tool disable prefix", () => {
    const prompt = buildToolInstructions(tools, "auto", true, "agy");
    expect(prompt).toContain("Your built-in tools are disabled; use only the functions listed below.");
  });
});

describe("plan", () => {
  test("accepts trailing user message", () => {
    const body = {
      model: "claude/claude-opus-5-5",
      messages: [{ role: "user", content: "hello" }],
    };
    const p = plan(body, false);
    expect(p.prompt).toBe("hello");
    expect(p.tools).toEqual([]);
  });

  test("validates tools schema and rejects invalid tool name", () => {
    const body = {
      model: "claude/claude-opus-5-5",
      messages: [{ role: "user", content: "hello" }],
      tools: [{ type: "function", function: { name: "invalid name with space" } }],
    };
    expect(() => plan(body, false)).toThrow(/invalid tool name/);
  });

  test("accepts trailing tool message when preceded by assistant with matching tool_calls", () => {
    const body = {
      model: "claude/claude-opus-5-5",
      messages: [
        { role: "user", content: "What is weather in SF?" },
        {
          role: "assistant",
          content: null,
          tool_calls: [
            {
              id: "call_abc",
              type: "function",
              function: { name: "get_weather", arguments: '{"location":"SF"}' },
            },
          ],
        },
        {
          role: "tool",
          tool_call_id: "call_abc",
          content: '{"temp": 70}',
        },
      ],
    };
    const p = plan(body, false);
    expect(p.prompt).toContain('<tool_result name="get_weather" id="call_abc">');
  });

  test("rejects trailing tool message without preceding assistant tool_calls", () => {
    const body = {
      model: "claude/claude-opus-5-5",
      messages: [
        { role: "user", content: "hello" },
        { role: "tool", tool_call_id: "call_unknown", content: "res" },
      ],
    };
    expect(() => plan(body, false)).toThrow(/must be preceded by an assistant message with tool_calls/);
  });

  test("rejects trailing tool message with mismatched tool_call_id", () => {
    const body = {
      model: "claude/claude-opus-5-5",
      messages: [
        { role: "user", content: "hello" },
        {
          role: "assistant",
          tool_calls: [{ id: "call_1", type: "function", function: { name: "f", arguments: "{}" } }],
        },
        { role: "tool", tool_call_id: "call_wrong", content: "res" },
      ],
    };
    expect(() => plan(body, false)).toThrow(/does not match any preceding assistant tool_calls/);
  });

  test("agy rejects --no-tools when sandbox is permissive", () => {
    const body = {
      model: "agy/gemini-3.8-flash",
      messages: [{ role: "user", content: "hello" }],
      tools: [
        {
          type: "function",
          function: { name: "test_tool" },
        },
      ],
    };
    expect(() => plan(body, false, "permissive")).toThrow(/cannot run without tools/);
  });
});
