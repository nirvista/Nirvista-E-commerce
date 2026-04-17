import React, { useState } from "react";
import { Link } from "react-router-dom";
import logo from "../assets/logo.png";

export default function ForgotPassword() {
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const baseUrl = import.meta.env.VITE_BASE_URL || "";

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setMessage("");
    setLoading(true);

    try {
      const res = await fetch(`${baseUrl}/api/auth/forgot-password`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email }),
      });
      const data = await res.json();
      
      if (res.ok) {
        setMessage(data.message);
      } else {
        setError(data.message || "Failed to send reset link.");
      }
    } catch (err) {
      setError(err.message || "Network error. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-white to-gray-100 dark:from-gray-900 dark:to-gray-800">
      <div className="bg-white dark:bg-gray-900 p-8 rounded-xl shadow-lg w-full max-w-md border border-gray-100 dark:border-gray-800">
        <div className="flex justify-center mb-8">
          <img src={logo} alt="Nirvista Logo" className="h-10 w-auto" />
        </div>
        <h2 className="text-2xl font-bold text-center text-gray-800 dark:text-white mb-2">Reset Password</h2>
        <p className="text-sm text-center text-gray-500 dark:text-gray-400 mb-6">
          Enter your email address and we'll send you a link to reset your password.
        </p>
        
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-200">Email Address</label>
            <input
              type="email"
              required
              value={email}
              onChange={e => setEmail(e.target.value)}
              className="mt-1 w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:border-gray-700 dark:text-white"
            />
          </div>
          
          {error && <div className="text-red-600 text-sm bg-red-50 p-2 rounded border border-red-100">{error}</div>}
          {message && <div className="text-green-700 text-sm bg-green-50 p-3 rounded border border-green-100">{message}</div>}
          
          <button
            type="submit"
            disabled={loading}
            className="w-full py-2 px-4 bg-teal-600 hover:bg-teal-700 disabled:opacity-50 text-white rounded font-medium transition duration-200"
          >
            {loading ? "Sending..." : "Send Reset Link"}
          </button>
        </form>
        
        <div className="mt-6 text-center">
          <Link to="/login" className="text-sm text-teal-600 hover:underline dark:text-teal-400">
            &larr; Back to Login
          </Link>
        </div>
      </div>
    </div>
  );
}