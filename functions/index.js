const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

// The Anthropic API key is stored as a Cloud secret (Google Secret Manager),
// NEVER in the app or in source control.
const ANTHROPIC_API_KEY = defineSecret("ANTHROPIC_API_KEY");

const MODEL = "claude-sonnet-4-6";

/**
 * Callable function: generates a story-chapter proposal with Claude.
 * Only signed-in Firebase users can call it. The Anthropic key stays
 * server-side, so it never ships inside the iOS app.
 */
exports.generateProposal = onCall(
  {
    secrets: [ANTHROPIC_API_KEY],
    region: "europe-west3",
    // Light throttling to protect your Anthropic credits from abuse.
    maxInstances: 10,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "You must be signed in to use the AI co-author.");
    }

    const data = request.data || {};
    const storyTitle = String(data.storyTitle || "Untitled");
    const synopsis = String(data.synopsis || "");
    const canonSoFar = String(data.canonSoFar || "");
    const chapterTitle = String(data.chapterTitle || "");
    const userInstruction = String(data.userInstruction || "");

    const systemPrompt =
      `You are a creative co-author collaborating on a story titled "${storyTitle}".\n` +
      `Synopsis: ${synopsis}\n\n` +
      `Your role is to propose the next chapter continuation based on the story so far.\n` +
      `Write in a compelling narrative style. Keep proposals between 200-400 words.\n` +
      `Match the tone and voice already established in the story.`;

    const userMessage =
      `Story so far:\n${canonSoFar.length ? canonSoFar : "(Story is just beginning)"}\n\n` +
      `Chapter to continue: ${chapterTitle}\n\n` +
      `Additional direction from collaborator: ${userInstruction.length ? userInstruction : "Surprise us!"}\n\n` +
      `Write the next chapter proposal:`;

    let resp;
    try {
      resp = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          "x-api-key": ANTHROPIC_API_KEY.value(),
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: MODEL,
          max_tokens: 600,
          system: systemPrompt,
          messages: [{ role: "user", content: userMessage }],
        }),
      });
    } catch (e) {
      throw new HttpsError("unavailable", "Could not reach the AI service. Please try again.");
    }

    if (!resp.ok) {
      const body = await resp.text();
      let message = `AI request failed (HTTP ${resp.status}).`;
      try {
        const parsed = JSON.parse(body);
        if (parsed && parsed.error && parsed.error.message) message = parsed.error.message;
      } catch (_) {}
      console.error("Anthropic API error:", resp.status, message);
      // "failed-precondition" reliably surfaces the message to the client
      // (unlike "internal", which Firebase scrubs to a generic "INTERNAL").
      throw new HttpsError("failed-precondition", message);
    }

    let json;
    try {
      json = await resp.json();
    } catch (e) {
      throw new HttpsError("internal", "The AI returned a malformed response.");
    }
    const text = (json.content && json.content[0] && json.content[0].text) || "";
    if (!text) {
      throw new HttpsError("internal", "The AI returned an empty response.");
    }
    return { text };
  }
);
