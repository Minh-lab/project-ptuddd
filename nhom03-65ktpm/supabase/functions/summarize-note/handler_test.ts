import assert from "node:assert/strict";
import { createHandler, RequestError } from "./handler.ts";

const dependencies = {
  verifyUser: (token: string) =>
    Promise.resolve(token === "firebase" ? "uid" : null),
  consumeQuota: () => Promise.resolve(true),
  generate: (instruction: string) => Promise.resolve(instruction),
  model: "test-model",
};
const request = (
  mode = "short",
  token = "firebase",
  text = "Định luật Faraday.",
) =>
  new Request("https://example.test", {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` },
    body: JSON.stringify({ mode, text }),
  });

Deno.test("supports three separate instructions and the app response contract", async () => {
  const handle = createHandler(dependencies);
  for (
    const [mode, expected] of [["short", "2–4 câu"], ["long", "2–4 đoạn"], [
      "bullets",
      "gạch đầu dòng",
    ]]
  ) {
    const response = await handle(request(mode));
    assert.equal(response.status, 200);
    const payload = await response.json();
    assert.match(payload.summary, new RegExp(expected));
    assert.equal(payload.model, "test-model");
  }
});

Deno.test("rejects unauthorized, invalid mode and oversized content before calling Gemini", async () => {
  const handle = createHandler({
    ...dependencies,
    generate: () => Promise.reject(new Error("Must not call Gemini")),
  });
  assert.equal((await handle(request("short", "bad-token"))).status, 401);
  assert.equal((await handle(request("__proto__"))).status, 400);
  assert.equal(
    (await handle(request("long", "firebase", "x".repeat(30_001)))).status,
    413,
  );
  assert.equal(
    (await handle(request("long", "firebase", "x".repeat(200_001)))).status,
    413,
  );
});

Deno.test("returns HTTP 429 for both user and Gemini quota", async () => {
  assert.equal(
    (await createHandler({
      ...dependencies,
      consumeQuota: () => Promise.resolve(false),
    })(request())).status,
    429,
  );
  assert.equal(
    (await createHandler({
      ...dependencies,
      generate: () => Promise.reject(new RequestError(429, "quota_exceeded")),
    })(request())).status,
    429,
  );
});

Deno.test("maps timeout and an empty Gemini result", async () => {
  const slow = createHandler({
    ...dependencies,
    timeoutMs: 1,
    generate: (_instruction, _note, signal) =>
      new Promise((_resolve, reject) =>
        signal.addEventListener("abort", () => reject(signal.reason), {
          once: true,
        })
      ),
  });
  assert.equal((await slow(request())).status, 504);
  assert.equal(
    (await createHandler({
      ...dependencies,
      generate: () => Promise.resolve(" "),
    })(request())).status,
    502,
  );
});
