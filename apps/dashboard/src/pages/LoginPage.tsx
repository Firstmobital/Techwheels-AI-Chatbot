import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "../lib/supabase";

export function LoginPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitting(true);
    setErrorMessage(null);

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      console.error("[dashboard-auth] Failed to sign in", {
        email,
        error,
      });
      setErrorMessage(error.message);
      setSubmitting(false);
      return;
    }

    navigate("/leads");
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-paper px-4 py-10 text-ink">
      <div className="w-full max-w-md rounded-3xl border border-slate-200 bg-white p-8 shadow-panel">
        <div className="mb-8">
          <p className="text-xs uppercase tracking-[0.24em] text-slate-500">
            Techwheels
          </p>
          <h1 className="mt-3 text-3xl font-semibold">Dashboard Login</h1>
          <p className="mt-2 text-sm text-slate-600">
            Sign in to access leads, conversations, pricing inputs, and
            campaigns.
          </p>
        </div>

        <form className="space-y-5" onSubmit={handleSubmit}>
          <div>
            <label className="field-label" htmlFor="email">
              Email
            </label>
            <input
              id="email"
              className="field-input"
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="you@example.com"
              autoComplete="email"
              required
            />
          </div>

          <div>
            <label className="field-label" htmlFor="password">
              Password
            </label>
            <input
              id="password"
              className="field-input"
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="Enter your password"
              autoComplete="current-password"
              required
            />
          </div>

          {errorMessage
            ? (
              <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                {errorMessage}
              </div>
            )
            : null}

          <button
            className="action-button w-full"
            disabled={submitting}
            type="submit"
          >
            {submitting ? "Logging in..." : "Login"}
          </button>
        </form>
      </div>
    </div>
  );
}
