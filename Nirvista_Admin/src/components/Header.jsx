import React, { useState, useRef, useEffect } from "react";
import { Menu, Bell, Sun, Moon, User } from "lucide-react";
import { removeToken } from "../utils/auth";
import { useNavigate } from "react-router-dom";

export default function Header({ sidebarOpen, setSidebarOpen, theme, setTheme }) {
  const [showNotifications, setShowNotifications] = useState(false);
  const [showProfile, setShowProfile] = useState(false);
  const notifRef = useRef(null);
  const profileRef = useRef(null);
  const navigate = useNavigate();

  useEffect(() => {
    function handleClickOutside(event) {
      if (notifRef.current && !notifRef.current.contains(event.target)) {
        setShowNotifications(false);
      }
      if (profileRef.current && !profileRef.current.contains(event.target)) {
        setShowProfile(false);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const toggleTheme = () => {
    setTheme((prev) => (prev === "light" ? "dark" : "light"));
  };

  return (
    <header className="flex items-center justify-between bg-white dark:bg-dark-bg px-6 py-4 shadow-sm sticky top-0 z-10">
      <button
        className="lg:hidden p-2 rounded-md hover:bg-slate-100 dark:hover:bg-dark-card"
        onClick={() => setSidebarOpen(true)}
      >
        <Menu size={24} className="text-slate-800 dark:text-dark-text" />
      </button>

      <div className="flex-1 mx-4 max-w-xl">
        {/* Search Bar Can Be Integrated Here */}
      </div>

      <div className="flex items-center gap-8 relative">
        <div className="relative" ref={notifRef}>
          <button
            className="relative p-2 rounded-full hover:bg-slate-100 dark:hover:bg-dark-card"
            onClick={() => setShowNotifications((v) => !v)}
          >
            <Bell size={28} className="text-slate-800 dark:text-dark-text" />
          </button>
          {showNotifications && (
            <div className="absolute right-0 mt-2 w-72 bg-white dark:bg-dark-card rounded-lg shadow-lg border border-slate-100 dark:border-dark-border z-50">
              <div className="p-4 border-b font-semibold text-primary dark:text-dark-primary">Notifications</div>
              <div className="p-4 text-slate-400 dark:text-dark-text text-sm">No new notifications</div>
            </div>
          )}
        </div>

        <button
          className="p-2 rounded-full hover:bg-slate-100 dark:hover:bg-dark-card"
          onClick={toggleTheme}
        >
          {theme === "light" ? <Sun size={28} className="text-slate-800" /> : <Moon size={28} className="text-dark-text" />}
        </button>

        <div className="relative" ref={profileRef}>
          <button
            className="p-2 rounded-full hover:bg-slate-100 dark:hover:bg-dark-card"
            onClick={() => setShowProfile((v) => !v)}
          >
            <User size={28} className="text-slate-800 dark:text-dark-text" />
          </button>
          {showProfile && (
            <div className="absolute right-0 mt-2 w-64 bg-white dark:bg-dark-card rounded-lg shadow-lg border border-slate-100 dark:border-dark-border z-50">
              <div className="p-4 border-b font-semibold text-primary dark:text-dark-primary">Account</div>
              <div className="p-4 space-y-2 text-slate-700 dark:text-dark-text">
                <button
                    className="w-full mt-2 py-2 px-4 bg-red-600 hover:bg-red-700 text-white font-semibold rounded transition"
                    onClick={() => {
                      removeToken();
                      navigate("/login", { replace: true });
                    }}
                  >
                    Logout
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}