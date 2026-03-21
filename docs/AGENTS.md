# Project Instructions

Always read `/docs/system_design.md` before making changes.

Rules:
- do not invent architecture outside system_design.md
- keep pricing deterministic, never use AI for final price
- use Supabase Edge Functions for backend endpoints
- use React + Vite + Tailwind + Zustand for dashboard
- keep code modular and production-structured
- return exact file changes
- return SQL migrations separately
- explain env variables required
- add basic error handling and logging
- do not refactor unrelated files
- after each task, provide:
  1. files created/updated
  2. migration SQL
  3. setup steps
  4. test steps