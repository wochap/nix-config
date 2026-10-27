import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { wrapCommand } from "../src/sandbox";

describe("sandbox hardening", () => {
  test("strict mode masks ~/.ssh", () => {
    const cmd = wrapCommand(["ls", "-la", `${process.env.HOME}/.ssh`], {
      mode: "strict",
      cwd: "/tmp",
    });
    const proc = Bun.spawnSync(cmd);
    expect(proc.exitCode).toBe(0);
    // Should be an empty tmpfs directory, only showing . and ..
    const out = proc.stdout.toString().trim();
    const lines = out.split("\n").filter(Boolean);
    // total 4, ., ..
    expect(lines.length).toBeLessThanOrEqual(3);
  });

  test("strict mode throws when bwrap is missing", () => {
    const origWhich = Bun.which;
    Bun.which = ((bin: string) => (bin === "bwrap" ? null : origWhich(bin))) as any;
    try {
      expect(() => {
        wrapCommand(["echo", "hi"], { mode: "strict", cwd: "/tmp" });
      }).toThrow(/strict mode requires bubblewrap/);
    } finally {
      Bun.which = origWhich;
    }
  });
});

describe("end-to-end serve tool calling", () => {
  let serverProc: any;
  const port = 21955;
  const baseUrl = `http://127.0.0.1:${port}`;

  beforeAll(async () => {
    serverProc = Bun.spawn(
      [
        process.execPath,
        "packages/agents/src/main.ts",
        "serve",
        "--port",
        String(port),
        "--no-auth",
        "--sandbox",
        "strict",
      ],
      {
        stdout: "pipe",
        stderr: "pipe",
      },
    );

    // Wait for server /health
    let ready = false;
    for (let i = 0; i < 30; i++) {
      try {
        const res = await fetch(`${baseUrl}/health`);
        if (res.ok) {
          ready = true;
          break;
        }
      } catch {}
      await Bun.sleep(200);
    }
    if (!ready) {
      throw new Error("Server failed to start on port " + port);
    }
  });

  afterAll(() => {
    serverProc?.kill();
  });

  test("two-turn tool loop with pi (omniroute/desktop-free)", async () => {
    const tools = [
      {
        type: "function",
        function: {
          name: "calculate_sum",
          description: "Calculate sum of two numbers",
          parameters: {
            type: "object",
            properties: {
              a: { type: "number" },
              b: { type: "number" },
            },
            required: ["a", "b"],
          },
        },
      },
    ];

    // Turn 1: user asks for a calculation with the tool
    const res1 = await fetch(`${baseUrl}/v1/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "pi/omniroute/desktop-free",
        messages: [{ role: "user", content: "What is 17 plus 25? Use calculate_sum." }],
        tools,
        tool_choice: { type: "function", function: { name: "calculate_sum" } },
      }),
    });

    expect(res1.status).toBe(200);
    const body1 = (await res1.json()) as any;
    expect(body1.choices).toBeDefined();
    expect(body1.choices[0].finish_reason).toBe("tool_calls");
    const toolCalls = body1.choices[0].message.tool_calls;
    expect(toolCalls.length).toBeGreaterThan(0);
    expect(toolCalls[0].function.name).toBe("calculate_sum");

    const callId = toolCalls[0].id;

    // Turn 2: harness responds with tool result
    const res2 = await fetch(`${baseUrl}/v1/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "pi/omniroute/desktop-free",
        messages: [
          { role: "user", content: "What is 17 plus 25? Use calculate_sum." },
          body1.choices[0].message,
          {
            role: "tool",
            tool_call_id: callId,
            content: JSON.stringify({ result: 42 }),
          },
        ],
        tools,
      }),
    });

    expect(res2.status).toBe(200);
    const body2 = (await res2.json()) as any;
    expect(body2.choices).toBeDefined();
    expect(body2.choices[0].finish_reason).toBe("stop");
    expect(body2.choices[0].message.content).toContain("42");
  }, 60000);

  test("streaming tool calling", async () => {
    const tools = [
      {
        type: "function",
        function: {
          name: "get_city_time",
          description: "Get current time in a city",
          parameters: {
            type: "object",
            properties: { city: { type: "string" } },
            required: ["city"],
          },
        },
      },
    ];

    const res = await fetch(`${baseUrl}/v1/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "pi/omniroute/desktop-free",
        stream: true,
        messages: [{ role: "user", content: "What time is it in Tokyo? Use get_city_time." }],
        tools,
        tool_choice: "required",
      }),
    });

    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toContain("text/event-stream");
    const text = await res.text();
    expect(text).toContain('"finish_reason":"tool_calls"');
    expect(text).toContain('"name":"get_city_time"');
    expect(text).toContain("data: [DONE]");
  }, 60000);

  test("tool call with agy (gemini-3.8-flash)", async () => {
    const tools = [
      {
        type: "function",
        function: {
          name: "get_weather",
          description: "Get weather for a location",
          parameters: {
            type: "object",
            properties: { location: { type: "string" } },
            required: ["location"],
          },
        },
      },
    ];

    const res = await fetch(`${baseUrl}/v1/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "agy/gemini-3.8-flash",
        messages: [{ role: "user", content: "What is the weather in Miami? Use get_weather." }],
        tools,
        tool_choice: "required",
      }),
    });

    expect(res.status).toBe(200);
    const body = (await res.json()) as any;
    expect(body.choices[0].finish_reason).toBe("tool_calls");
    const toolCalls = body.choices[0].message.tool_calls;
    expect(toolCalls.length).toBeGreaterThan(0);
    expect(toolCalls[0].function.name).toBe("get_weather");
    expect(JSON.parse(toolCalls[0].function.arguments).location).toMatch(/miami/i);
  }, 60000);
});
