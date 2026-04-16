import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import logo from "../assets/logo.png";
import { setToken } from "../utils/auth";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const navigate = useNavigate();

  const baseUrl = import.meta.env.VITE_BASE_URL || "";
  const handleLogin = async (e) => {
    e.preventDefault();
    setError("");
    try {
      const res = await fetch(`${baseUrl}/api/auth/adminlogin`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = await res.json();
      if (res.ok && data.data && data.data.token) {
        setToken(data.data.token);
        navigate("/");
      } else {
        setError(data.message || "Login failed");
      }
    } catch (err) {
      setError(err.message ||"Network error");
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-white to-gray-100 dark:from-gray-900 dark:to-gray-800">
      <div className="w-full max-w-md p-8 rounded-lg shadow-lg bg-white dark:bg-gray-900">
        <div className="flex flex-col items-center mb-8">
          <img src={logo} alt="Nirvista Logo" className="h-12 mb-2" />
          <h2 className="text-2xl font-bold text-teal-700 dark:text-teal-400">Login to Nirvista</h2>
        </div>
        <form onSubmit={handleLogin} className="space-y-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-200">Email</label>
            <input
              type="email"
              required
              value={email}
              onChange={e => setEmail(e.target.value)}
              className="mt-1 w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white"
              autoComplete="email"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-200">Password</label>
            <input
              type="password"
              required
              value={password}
              onChange={e => setPassword(e.target.value)}
              className="mt-1 w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white"
              autoComplete="current-password"
            />
          </div>
          <div className="flex justify-between items-center">
            <button
              type="button"
              className="text-sm text-teal-600 hover:underline dark:text-teal-400"
              onClick={() => {/* TODO: Add forgot password logic */}}
            >
              Forgot password?
            </button>
          </div>
          {error && <div className="text-red-600 text-sm">{error}</div>}
          <button
            type="submit"
            className="w-full py-2 px-4 bg-teal-600 hover:bg-teal-700 text-white font-semibold rounded transition"
          >
            Login
          </button>
        </form>
      </div>
    </div>
  );
}