import React, { useState, useEffect } from "react";
import { ShoppingCart, Users, Store, Activity, TrendingUp, Package, Trophy } from "lucide-react";
import { apiFetch } from "../utils/api";
import './Dashboard.css';

const baseUrl = import.meta.env.VITE_BASE_URL || "";

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState(null);

  useEffect(() => {
    fetchDashboardStats();
  }, []);

  const fetchDashboardStats = async () => {
    try {
      setLoading(true);
      const res = await apiFetch(`${baseUrl}/api/admin/dashboard`);
      const data = await res.json();

      if (res.ok) {
        setStats(data.data);
      } else {
        setErrorMsg(data.message || "Failed to load dashboard data.");
      }
    } catch (err) {
      setErrorMsg(`Network Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="p-8 text-center text-slate-500 font-medium animate-pulse">Loading Dashboard Metrics...</div>;
  }

  if (errorMsg) {
    return <div className="p-8 text-center text-red-500 font-medium bg-red-50 rounded-lg m-8 border border-red-100">{errorMsg}</div>;
  }

  if (!stats) return null;

  const { summary, monthlySales, topProducts, topVendors } = stats;

  // Find max sales to scale the chart dynamically
  const maxSales = Math.max(...monthlySales.map(m => m.sales), 1);

  return (
    <div className="p-6 md:p-8 max-w-7xl mx-auto w-full space-y-6">
      
      {/* Header */}
      <div className="mb-2">
        <h1 className="text-2xl font-bold text-slate-800 dark:text-gray-100">Overview</h1>
        <p className="text-slate-500 dark:text-gray-400 text-sm">Welcome back to the Nirvista E-Commerce Admin Dashboard.</p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <SummaryCard 
          icon={<ShoppingCart size={24} className="text-blue-600 dark:text-blue-400" />} 
          title="Total Orders" 
          value={summary.totalOrders} 
          bgClass="bg-blue-50 dark:bg-blue-900/20" 
        />
        <SummaryCard 
          icon={<TrendingUp size={24} className="text-emerald-600 dark:text-emerald-400" />} 
          title="Total Revenue" 
          value={`₹${summary.totalRevenue.toFixed(2)}`} 
          bgClass="bg-emerald-50 dark:bg-emerald-900/20" 
        />
        <SummaryCard 
          icon={<Users size={24} className="text-indigo-600 dark:text-indigo-400" />} 
          title="Total Customers" 
          value={summary.totalCustomers} 
          bgClass="bg-indigo-50 dark:bg-indigo-900/20" 
        />
        <SummaryCard 
          icon={<Store size={24} className="text-orange-600 dark:text-orange-400" />} 
          title="Total Vendors" 
          value={summary.totalVendors} 
          bgClass="bg-orange-50 dark:bg-orange-900/20" 
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Monthly Sales Chart (Spans 2 columns) */}
        <div className="lg:col-span-2 bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 p-6 flex flex-col">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-bold text-slate-800 dark:text-gray-100 flex items-center gap-2">
              <Activity size={20} className="text-teal-500" />
              Monthly Sales
            </h2>
            <span className="text-xs font-semibold text-slate-500 bg-slate-100 dark:bg-gray-800 px-2 py-1 rounded-full">Current Year</span>
          </div>
          
          <div className="custom-chart-container flex-1 flex items-end gap-2 sm:gap-4 h-64 mt-4 relative pt-6">
             {monthlySales.map((data, idx) => {
                const heightPercentage = data.sales > 0 ? (data.sales / maxSales) * 100 : 2; // min 2% for visibility
                return (
                  <div key={idx} className="chart-bar-group flex-1 flex flex-col items-center justify-end h-full group relative">
                    <div className="chart-tooltip opacity-0 group-hover:opacity-100 transition-opacity absolute -top-8 bg-slate-800 text-white text-xs py-1 px-2 rounded pointer-events-none z-10 whitespace-nowrap">
                       ₹{data.sales.toFixed(2)}
                    </div>
                    <div 
                      className="w-full bg-teal-500/80 hover:bg-teal-400 dark:bg-teal-600 dark:hover:bg-teal-500 rounded-t-sm transition-all duration-300"
                      style={{ height: `${heightPercentage}%` }}
                    ></div>
                    <span className="text-[10px] sm:text-xs text-slate-500 dark:text-gray-400 mt-2 font-medium">
                      {data.month}
                    </span>
                  </div>
                )
             })}
          </div>
        </div>

        {/* Active Users & Quick Stats */}
        <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 p-6 flex flex-col justify-center items-center text-center">
            <div className="h-24 w-24 rounded-full bg-teal-50 dark:bg-teal-900/20 flex items-center justify-center mb-4 border-4 border-teal-100 dark:border-teal-900/50">
               <Activity size={40} className="text-teal-600 dark:text-teal-400" />
            </div>
            <h3 className="text-3xl font-black text-slate-800 dark:text-gray-100">{summary.activeUsers}</h3>
            <p className="text-sm font-semibold text-slate-500 dark:text-gray-400 uppercase tracking-widest mt-1">Active Users</p>
            <div className="mt-8 pt-6 border-t border-slate-100 dark:border-gray-800 w-full">
               <p className="text-xs text-slate-400 dark:text-gray-500 leading-relaxed">
                 Active users represent accounts currently in good standing and not suspended.
               </p>
            </div>
        </div>

      </div>

      {/* Lists Row: Top Products & Top Vendors */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Top Products */}
        <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 p-6">
          <div className="flex items-center gap-2 mb-6 border-b border-slate-100 dark:border-gray-800 pb-3">
            <Package size={20} className="text-indigo-500" />
            <h2 className="text-lg font-bold text-slate-800 dark:text-gray-100">Top Selling Products</h2>
          </div>
          <div className="space-y-4">
             {topProducts.length === 0 ? (
               <p className="text-sm text-slate-500 italic">No sales data yet.</p>
             ) : (
               topProducts.map((prod, index) => (
                 <div key={prod.id} className="flex items-center justify-between p-3 bg-slate-50 dark:bg-gray-800/50 rounded-lg">
                    <div className="flex items-center gap-3">
                       <span className="flex items-center justify-center h-6 w-6 rounded-full bg-indigo-100 dark:bg-indigo-900/50 text-indigo-700 dark:text-indigo-300 text-xs font-bold">{index + 1}</span>
                       <p className="text-sm font-medium text-slate-800 dark:text-gray-200 truncate max-w-[200px] sm:max-w-xs">{prod.title}</p>
                    </div>
                    <div className="text-right">
                       <p className="text-xs font-semibold text-slate-500 dark:text-gray-400 uppercase tracking-wider">Sold</p>
                       <p className="text-sm font-bold text-slate-800 dark:text-gray-100">{prod.totalSold}</p>
                    </div>
                 </div>
               ))
             )}
          </div>
        </div>

        {/* Top Vendors */}
        <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 p-6">
          <div className="flex items-center gap-2 mb-6 border-b border-slate-100 dark:border-gray-800 pb-3">
            <Trophy size={20} className="text-orange-500" />
            <h2 className="text-lg font-bold text-slate-800 dark:text-gray-100">Top Revenue Vendors</h2>
          </div>
          <div className="space-y-4">
             {topVendors.length === 0 ? (
               <p className="text-sm text-slate-500 italic">No sales data yet.</p>
             ) : (
               topVendors.map((vendor, index) => (
                 <div key={vendor.id} className="flex items-center justify-between p-3 bg-slate-50 dark:bg-gray-800/50 rounded-lg">
                    <div className="flex items-center gap-3">
                       <span className="flex items-center justify-center h-6 w-6 rounded-full bg-orange-100 dark:bg-orange-900/50 text-orange-700 dark:text-orange-300 text-xs font-bold">{index + 1}</span>
                       <div>
                         <p className="text-sm font-medium text-slate-800 dark:text-gray-200">{vendor.storeName}</p>
                         <p className="text-[10px] text-slate-500 dark:text-gray-400">{vendor.email}</p>
                       </div>
                    </div>
                    <div className="text-right">
                       <p className="text-xs font-semibold text-slate-500 dark:text-gray-400 uppercase tracking-wider">Revenue</p>
                       <p className="text-sm font-bold text-slate-800 dark:text-gray-100">₹{vendor.revenue.toFixed(2)}</p>
                    </div>
                 </div>
               ))
             )}
          </div>
        </div>

      </div>
    </div>
  );
}

function SummaryCard({ title, value, icon, bgClass }) {
  return (
    <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 p-6 flex items-center gap-4 transition-transform hover:-translate-y-1 duration-200">
      <div className={`h-12 w-12 rounded-lg flex items-center justify-center shrink-0 ${bgClass}`}>
        {icon}
      </div>
      <div>
        <p className="text-xs font-semibold text-slate-500 dark:text-gray-400 uppercase tracking-wider mb-1">{title}</p>
        <h3 className="text-2xl font-black text-slate-800 dark:text-gray-100">{value}</h3>
      </div>
    </div>
  );
}