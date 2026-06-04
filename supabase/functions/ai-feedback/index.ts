import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY") || "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

const SYSTEM_PROMPTS = {
  "Digital": {
    "1": "Identify a problem that people are willing to pay to solve. Describe the problem and why it matters.",
    "2": "Draft a landing page copy that clearly communicates your value proposition. Who is it for and what does it do?",
    "3": "Reach out to 5 potential customers and get them to commit to a pre-order or a beta test. Document the conversations.",
    "4": "Analyze the feedback from your first users. What is the one thing you must change to make them love the product?",
  },
  "Physical": {
    "1": "Find a physical product that is underserved in your market. How can you improve it by 10x?",
    "2": "Create a prototype or a visual mockup of your product. List the materials and the estimated cost per unit.",
    "3": "Set up a simple pre-order page. Get 3 people to pay a small deposit to validate interest.",
    "4": "Calculate your unit economics. What is your margin after shipping and production?",
  },
  "Local": {
    "1": "Identify a local business service that is currently inefficient in your city. How would you fix it?",
    "2": "Map out your first 10 potential clients in a specific neighborhood. Why them?",
    "3": "Walk into 3 local businesses or call 5 locals. Pitch your service and get your first 'yes'.",
    "4": "Deliver your service to the first customer and get a video testimonial. What went wrong?",
  },
  "No-Code": {
    "1": "Find a manual process that takes more than 2 hours a week for a specific group of people.",
    "2": "Build a MVP using Notion, Glide, or Webflow that automates at least 50% of that process.",
    "3": "Share your tool on a community forum (Reddit, IndieHackers, etc.) and get 10 signups.",
    "4": "Iterate based on the usage data. Which feature is being used the most and why?",
  }
};

const MENTOR_PERSONA = "You are Karun's AI Mentor for the Sprova Cohort. Your goal is to push students to stop overthinking and start shipping. Be direct, honest, and high-impact. Do not be generic. Focus on validation, revenue, and real-world execution. If a student is playing it safe, call them out. If they are making progress, push them to the next level.";


serve(async (req) => {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  // 1. Authentication and Params
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return new Response("Unauthorized", { status: 401 });

  const { student_email, lesson_id, response_text } = await req.json();

  // 2. Rate Limiting: Max 3 per day
  const { count, error: countError } = await supabase
    .from("submissions")
    .select("*", { count: "exact", head: true })
    .eq("student_email", student_email)
    .gte("submitted_at", new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

  if (countError || (count !== null && count >= 3)) {
    return new Response("Rate limit exceeded. Max 3 requests per day.", { status: 429 });
  }

  // 3. Fetch Track and Week
  const { data: lesson, error: lessonError } = await supabase
    .from("lessons")
    .select("track, week")
    .eq("id", lesson_id)
    .single();

  if (lessonError || !lesson) {
    return new Response("Lesson not found", { status: 404 });
  }

  const prompt = SYSTEM_PROMPTS[lesson.track]?.[lesson.week];
  const systemPrompt = `${MENTOR_PERSONA}\n\nCURRENT TASK: ${prompt || "Provide general high-impact execution feedback."}`;

  // 4. Claude API Call (Streaming)
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-3-5-sonnet-20240620",
      max_tokens: 600,
      system: systemPrompt,
      messages: [{ role: "user", content: response_text }],
      stream: true,
    }),
  });

  if (!response.ok) {
    return new Response("Claude API Error", { status: 500 });
  }

  // Return the stream directly to the client
  return new Response(response.body, {
    headers: { "Content-Type": "text/event-stream" },
  });
});
