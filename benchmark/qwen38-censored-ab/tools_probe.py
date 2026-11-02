#!/usr/bin/env python3
# One-file tool-call sanity probe for any OpenAI-compatible endpoint.
# Checks that tool_calls come back as valid JSON with required keys, and
# reports the prompt-token cost of attaching a one-function schema.
# No dependencies. Decisions + counts only; nothing from the answer is stored.
import json, os, urllib.request

URL = os.environ.get("BK_ENDPOINT", "http://127.0.0.1:5001/v1/chat/completions")
MODEL = os.environ.get("BK_MODEL", "qwen3.8-flash-next-ud-q4_k_xl")
TRIALS = int(os.environ.get("BK_TRIALS", "5"))

TOOLS = [{"type": "function", "function": {
    "name": "get_weather", "description": "Get current weather for a city",
    "parameters": {"type": "object", "properties": {
        "city": {"type": "string"},
        "unit": {"type": "string", "enum": ["c", "f"]}},
        "required": ["city"]}}}]


def call(msgs, tools=None):
    body = {"model": MODEL, "messages": msgs, "temperature": 0.7,
            "top_p": 0.8, "max_tokens": 200,
            "chat_template_kwargs": {"enable_thinking": False}}
    if tools:
        body["tools"] = tools
        body["tool_choice"] = "auto"
    req = urllib.request.Request(
        URL, data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"})
    return json.load(urllib.request.urlopen(req, timeout=180))


ok = broken = 0
for _ in range(TRIALS):
    r = call([{"role": "user",
               "content": "What is the weather in Moscow right now? Use the weather tool."}],
             TOOLS)
    msg = r["choices"][0]["message"]
    tc = msg.get("tool_calls")
    try:
        args = json.loads(tc[0]["function"]["arguments"])
        good = tc[0]["function"]["name"] == "get_weather" and "city" in args
    except Exception:
        good = False
    if good:
        ok += 1
    else:
        broken += 1
r = call([{"role": "user", "content": "What is the weather in Moscow right now?"}])
print(f"tool_calls clean: {ok}/{TRIALS}, broken: {broken}/{TRIALS}")
print(f"prompt_tokens: without tools={r['usage']['prompt_tokens']}, "
      f"with one-function schema={call([{'role':'user','content':'What is the weather in Moscow right now? Use the weather tool.'}], TOOLS)['usage']['prompt_tokens']}")
raise SystemExit(0 if broken == 0 else 1)
