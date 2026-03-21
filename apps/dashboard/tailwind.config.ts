import type { Config } from "tailwindcss";

export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        ink: "#152033",
        paper: "#f6f7fb",
        accent: "#0f766e",
        accentSoft: "#d8f3ef",
      },
      boxShadow: {
        panel: "0 12px 30px rgba(21, 32, 51, 0.08)",
      },
    },
  },
  plugins: [],
} satisfies Config;
