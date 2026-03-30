import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { supabase } from "../lib/supabase";

export function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();

  async function handleLogin() {
    if (!email || !password) { setError("Please enter email and password."); return; }
    setLoading(true);
    setError(null);
    try {
      const { error: authError } = await supabase.auth.signInWithPassword({ email, password });
      if (authError) { setError(authError.message); return; }
      navigate("/leads");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-[#f4f5f9]">
      <div className="w-full max-w-sm">
        {/* Brand */}
        <div className="mb-8 text-center">
          <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-2xl bg-[#152033]">
            <span className="text-[14px] font-bold text-white">TW</span>
          </div>
          <h1 className="text-xl font-bold text-ink">Techwheels Dashboard</h1>
          <p className="mt-1 text-[12px] text-slate-400">AI Sales Platform · Tata Motors Jaipur</p>
        </div>

        {/* Card */}
        <div className="panel p-7">
          <p className="mb-5 text-[14px] font-semibold text-ink">Sign in to your account</p>

          <div className="flex flex-col gap-4">
            <div>
              <label className="field-label">Email address</label>
              <input
                className="field-input"
                type="email"
                placeholder="you@techwheels.in"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                onKeyDown={(e) => { if (e.key === "Enter") void handleLogin(); }}
              />
            </div>
            <div>
              <label className="field-label">Password</label>
              <input
                className="field-input"
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                onKeyDown={(e) => { if (e.key === "Enter") void handleLogin(); }}
              />
            </div>

            {error && (
              <div className="rounded-xl border border-red-100 bg-red-50 px-4 py-3 text-[12px] text-red-700">
                {error}
              </div>
            )}

            <button
              type="button"
              className="action-button w-full py-2.5 text-[13px]"
              disabled={loading}
              onClick={() => void handleLogin()}
            >
              {loading ? "Signing in…" : "Sign in"}
            </button>
          </div>
        </div>

        <p className="mt-4 text-center text-[11px] text-slate-400">
          Techwheels Tata Motors · Jaipur · Phase 1
        </p>
      </div>
    </div>
  );
}
