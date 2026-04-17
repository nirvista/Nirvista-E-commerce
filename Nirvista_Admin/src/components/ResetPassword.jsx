import React, { useState } from "react";
import { useParams, Link } from "react-router-dom";
import logo from "../assets/logo.png";

export default function ResetPassword() {
  const { token } = useParams(); // Grabs the 32-byte token from the URL
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [message, setMessage] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const baseUrl = import.meta.env.VITE_BASE_URL || "";

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setMessage("");

    if (password !== confirmPassword) {
      return setError("Passwords do not match.");
    }
    if (password.length < 6) {
      return setError("Password must be at least 6 characters long.");
    }

    setLoading(true);

    try {
      const res = await fetch(`${baseUrl}/api/auth/reset-password/${token}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ password }),
      });
      const data = await res.json();
      
      if (res.ok) {
        setMessage("Password has been reset successfully! You can now log in.");
        setPassword("");
        setConfirmPassword("");
      } else {
        setError(data.message || "Failed to reset password. Token may be invalid or expired.");
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
        <div className="flex justify-center mb-6">
          <img src={logo} alt="Nirvista Logo" className="h-10 w-auto" />
        </div>
        <h2 className="text-2xl font-bold text-center text-gray-800 dark:text-white mb-6">Create New Password</h2>
        
        {message ? (
          <div className="text-center space-y-6">
             <div className="text-green-700 text-sm bg-green-50 p-4 rounded border border-green-100">{message}</div>
             <Link to="/login" className="inline-block w-full py-2 px-4 bg-teal-600 hover:bg-teal-700 text-white rounded font-medium transition duration-200">
                Go to Login
             </Link>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-200">New Password</label>
              <input
                type="password"
                required
                value={password}
                onChange={e => setPassword(e.target.value)}
                className="mt-1 w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:border-gray-700 dark:text-white"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-200">Confirm New Password</label>
              <input
                type="password"
                required
                value={confirmPassword}
                onChange={e => setConfirmPassword(e.target.value)}
                className="mt-1 w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:border-gray-700 dark:text-white"
              />
            </div>
            
            {error && <div className="text-red-600 text-sm bg-red-50 p-2 rounded border border-red-100">{error}</div>}
            
            <button
              type="submit"
              disabled={loading}
              className="w-full py-2 px-4 bg-teal-600 hover:bg-teal-700 disabled:opacity-50 text-white rounded font-medium transition duration-200"
            >
              {loading ? "Resetting..." : "Reset Password"}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}