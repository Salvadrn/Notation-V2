import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// In-memory rate limiter (per Edge Function instance)
const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
const RATE_LIMIT_MAX = 10; // max requests per window
const RATE_LIMIT_WINDOW_MS = 60_000; // 1 minute

function isRateLimited(userId: string): boolean {
  const now = Date.now();
  const entry = rateLimitMap.get(userId);

  if (!entry || now > entry.resetAt) {
    rateLimitMap.set(userId, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
    return false;
  }

  entry.count += 1;
  return entry.count > RATE_LIMIT_MAX;
}

// Allowed MIME types
const ALLOWED_MEDIA_TYPES = new Set([
  "image/png",
  "image/jpeg",
  "image/jpg",
  "image/webp",
  "image/gif",
]);

// Max base64 payload size (~5MB decoded)
const MAX_BASE64_LENGTH = 7_000_000;

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // --- 1. Authenticate with SERVICE_ROLE for server-side verification ---
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Use SERVICE_ROLE key for secure server-side JWT verification
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // --- 2. Rate limiting per user ---
    if (isRateLimited(user.id)) {
      return new Response(
        JSON.stringify({ error: "Rate limit exceeded. Please wait before trying again." }),
        { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // --- 3. Parse and validate request body ---
    const body = await req.json();
    const { image_base64, media_type = "image/png" } = body;

    if (!image_base64 || typeof image_base64 !== "string") {
      return new Response(
        JSON.stringify({ error: "Missing or invalid image_base64 field" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validate base64 size (prevent DoS with huge payloads)
    if (image_base64.length > MAX_BASE64_LENGTH) {
      return new Response(
        JSON.stringify({ error: "Image too large. Maximum size is 5MB." }),
        { status: 413, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validate base64 format
    if (!/^[A-Za-z0-9+/=]+$/.test(image_base64)) {
      return new Response(
        JSON.stringify({ error: "Invalid base64 format" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Validate MIME type
    if (!ALLOWED_MEDIA_TYPES.has(media_type)) {
      return new Response(
        JSON.stringify({ error: `Unsupported media type: ${media_type}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // --- 4. Get Claude API secrets ---
    const claudeApiKey = Deno.env.get("CLAUDE_API_KEY");
    if (!claudeApiKey) {
      return new Response(
        JSON.stringify({ error: "Claude API key not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
    const claudeModel = Deno.env.get("CLAUDE_MODEL") ?? "claude-sonnet-4-5-20250929";

    // --- 5. Call Claude API ---
    const claudeResponse = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": claudeApiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: claudeModel,
        max_tokens: 4096,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: {
                  type: "base64",
                  media_type: media_type,
                  data: image_base64,
                },
              },
              {
                type: "text",
                text: `Analyze this slide or image and create structured study notes. Return a JSON object with this exact structure:
{
  "title": "Main title or topic",
  "summary": "Brief 2-3 sentence summary",
  "sections": [
    {
      "heading": "Section heading",
      "bullets": ["Key point 1", "Key point 2"]
    }
  ],
  "keyDefinitions": [
    {
      "term": "Important term",
      "definition": "Clear definition"
    }
  ]
}
Return ONLY valid JSON, no other text.`,
              },
            ],
          },
        ],
      }),
    });

    if (!claudeResponse.ok) {
      const errorBody = await claudeResponse.text();
      console.error("Claude API error:", claudeResponse.status, errorBody);
      return new Response(
        JSON.stringify({ error: `Claude API error: ${claudeResponse.status}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const claudeData = await claudeResponse.json();
    const textBlock = claudeData.content?.find(
      (block: { type: string }) => block.type === "text"
    );

    if (!textBlock?.text) {
      return new Response(
        JSON.stringify({ error: "No text in Claude response" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // --- 6. Parse and validate the JSON from Claude ---
    let notes;
    try {
      notes = JSON.parse(textBlock.text);
    } catch {
      // Claude sometimes wraps JSON in markdown code fences
      const cleaned = textBlock.text.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
      notes = JSON.parse(cleaned);
    }

    // Validate required fields
    if (!notes.title || !notes.summary) {
      return new Response(
        JSON.stringify({ error: "Invalid response structure from AI" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify(notes),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(
      JSON.stringify({ error: error.message ?? "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
