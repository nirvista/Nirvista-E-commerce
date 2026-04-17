import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import logo from "../assets/logo.png";
import { setToken } from "../utils/auth";

export default function Signup() {
  const [form, setForm] = useState({
    name: "",
    email: "",
    phone: "",
    password: "",
    confirmPassword: "",
  });
  const [error, setError] = useState("");
  const navigate = useNavigate();

  const handleChange = (e) => {
    setForm({ ...form, [e.target.name]: e.target.value });
  };

  const handleSignup = async (e) => {
    e.preventDefault();
    setError("");
    if (form.password !== form.confirmPassword) {
      setError("Passwords do not match");
      return;
    }
    try {
      const baseUrl = import.meta.env.VITE_BASE_URL || "";
      const res = await fetch(`${baseUrl}/api/auth/adminSignUp`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: form.name,
          email: form.email,
          phone: form.phone,
          password: form.password,
          confirmPassword: form.confirmPassword,
        }),
      });
      const data = await res.json();
      if (res.ok && data.data && data.data.token) {
        setToken(data.data.token);
        navigate("/");
      } else {
        setError(data.message || "Signup failed");
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
          <h2 className="text-2xl font-bold text-teal-700 dark:text-teal-400">Create your Nirvista account</h2>
        </div>
        <form onSubmit={handleSignup} className="space-y-5">
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-200">Name</label>
            <input
              type="text"
              name="name"
              required
              value={form.name}
              onChange={handleChange}
              className="mt-1 w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-200">Email</label>
            <input
              type="email"
              name="email"
              required
              value={form.email}
              onChange={handleChange}
              className="mt-1 w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white"
              autoComplete="email"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-200">Phone</label>
            <input
              type="tel"
              name="phone"
              required
              value={form.phone}
              onChange={handleChange}
              className="mt-1 w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-200">Password</label>
            <input
              type="password"
              name="password"
              required
              value={form.password}
              onChange={handleChange}
              className="mt-1 w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white"
              autoComplete="new-password"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-200">Confirm Password</label>
            <input
              type="password"
              name="confirmPassword"
              required
              value={form.confirmPassword}
              onChange={handleChange}
              className="mt-1 w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white"
              autoComplete="new-password"
            />
          </div>
          {error && <div className="text-red-600 text-sm">{error}</div>}
          <button
            type="submit"
            className="w-full py-2 px-4 bg-teal-600 hover:bg-teal-700 text-white font-semibold rounded transition"
          >
            Sign Up
          </button>
        </form>
        <div className="mt-6 text-center">
          <span className="text-gray-600 dark:text-gray-300">Already have an account? </span>
          <button
            className="text-teal-600 hover:underline dark:text-teal-400 font-semibold"
            onClick={() => navigate("/login")}
          >
            Login Now
          </button>
        </div>
      </div>
    </div>
  );
}