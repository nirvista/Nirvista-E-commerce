import React, { useState, useEffect } from "react";
import ProtectedRoute from "./components/ProtectedRoute";
import { BrowserRouter as Router, Routes, Route, Navigate, Outlet } from "react-router-dom";
import Sidebar from "./components/Sidebar";
import Header from "./components/Header";
import Dashboard from "./components/Dashboard";
import Login from "./components/Login";
import Signup from "./components/Signup";
import ForgotPassword from "./components/ForgotPassword";
import ResetPassword from "./components/ResetPassword";
import Vendors from "./components/Vendors";
import Products from "./components/Products";
import Categories from "./components/Categories";
import Brands from "./components/Brands";
import Orders from "./components/Orders";

function ProtectedLayout({ sidebarOpen, setSidebarOpen, theme, setTheme }) {
  return (
    <ProtectedRoute>
      <div className="flex h-screen overflow-hidden font-sans transition-all duration-200">
        <Sidebar sidebarOpen={sidebarOpen} setSidebarOpen={setSidebarOpen} />
        <div className="relative flex flex-1 flex-col overflow-y-auto overflow-x-hidden lg:ml-64 transition-all duration-200">
          <Header
            sidebarOpen={sidebarOpen}
            setSidebarOpen={setSidebarOpen}
            theme={theme}
            setTheme={setTheme}
          />
          <main className="p-4 md:p-6 2xl:p-10">
            <Outlet />
          </main>
        </div>
      </div>
    </ProtectedRoute>
  );
}

export default function App() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [theme, setTheme] = useState(
    () => localStorage.getItem("theme") || "light"
  );

  useEffect(() => {
    document.documentElement.classList.remove("light", "dark");
    document.documentElement.classList.add(theme);
    localStorage.setItem("theme", theme);
  }, [theme]);

  return (
    <Router>
      <Routes>
        {/* Public routes */}
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<Signup />} />
        <Route path="/forgot-password" element={<ForgotPassword />} />
        <Route path="/reset-password/:token" element={<ResetPassword />} />

        {/* Protected Admin Routes */}
        <Route
          element={
            <ProtectedLayout
              sidebarOpen={sidebarOpen}
              setSidebarOpen={setSidebarOpen}
              theme={theme}
              setTheme={setTheme}
            />
          }
        >
          <Route path="/" element={<Dashboard />} />
          <Route path="/orders" element={<Orders />} />
          <Route path="/vendors" element={<Vendors />} />
          <Route path="/products" element={<Products />} />
          <Route path="/categories" element={<Categories />} />
          <Route path="/brands" element={<Brands />} />
          {/* Add more protected routes here */}
        </Route>
        <Route path="*" element={<Navigate to="/" />} />
      </Routes>
    </Router>
  );
}