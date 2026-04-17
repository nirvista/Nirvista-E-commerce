import React, { useState, useEffect } from "react";
import { Eye, ChevronLeft, Search, FilterX, Edit2, Check, X } from "lucide-react";
import { apiFetch } from "../utils/api";

const baseUrl = import.meta.env.VITE_BASE_URL || "";

export default function Orders() {
  const [view, setView] = useState("list"); // 'list' | 'details'
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState(null);

  // Filters & Search
  const [searchTerm, setSearchTerm] = useState("");
  const [filterForm, setFilterForm] = useState({ status: "", paymentStatus: "", sort: "" });

  // Details State
  const [selectedOrder, setSelectedOrder] = useState(null);
  
  // Edit State inline
  const [editingField, setEditingField] = useState(null);
  const [editValue, setEditValue] = useState("");

  useEffect(() => {
    if (view === "list") {
      fetchOrders();
    }
  }, [view, filterForm]);

  const fetchOrders = async () => {
    setLoading(true);
    setErrorMsg(null);
    try {
      const queryParams = new URLSearchParams();
      if (filterForm.status) queryParams.append('status', filterForm.status);
      if (filterForm.paymentStatus) queryParams.append('paymentStatus', filterForm.paymentStatus);
      if (filterForm.sort) queryParams.append('sort', filterForm.sort);

      const queryString = queryParams.toString() ? `?${queryParams.toString()}` : '';
      const res = await apiFetch(`${baseUrl}/api/orders/admin/all${queryString}`);
      
      const contentType = res.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
          setErrorMsg("Backend crashed. Check server logs.");
          setOrders([]);
          setLoading(false);
          return;
      }

      const data = await res.json();
      
      if (res.ok && data) {
        // Robust array extraction to prevent undefined crashes
        let extractedOrders = [];
        if (data.data && Array.isArray(data.data.orders)) {
            extractedOrders = data.data.orders;
        } else if (Array.isArray(data.orders)) {
            extractedOrders = data.orders;
        } else if (Array.isArray(data.data)) {
            extractedOrders = data.data;
        } else if (Array.isArray(data)) {
            extractedOrders = data;
        }
        setOrders(extractedOrders);
      } else {
        setErrorMsg(data?.message || "Failed to fetch orders");
        setOrders([]);
      }
    } catch (err) {
      setErrorMsg(`Network Error: ${err.message}`);
      setOrders([]);
    } finally {
      setLoading(false);
    }
  };

  const fetchOrderDetails = async (id) => {
    setLoading(true);
    setErrorMsg(null);
    try {
      const res = await apiFetch(`${baseUrl}/api/orders/admin/${id}`);
      
      const contentType = res.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
          setErrorMsg("Backend crashed. Check server logs.");
          setLoading(false);
          return;
      }

      const data = await res.json();
      
      if (res.ok && data) {
        const orderData = data.data || data;
        setSelectedOrder(orderData);
        setView("details");
      } else {
        setErrorMsg(data?.message || "Failed to fetch details");
      }
    } catch (err) {
      setErrorMsg(`Network Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  // Safe Frontend Search Check (Postgres crashes on non-UUID searching, so we filter visually here)
  const filteredOrders = orders.filter(o => 
    (o.id && String(o.id).toLowerCase().includes(searchTerm.toLowerCase())) || 
    (o.user?.name && o.user.name.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  const handleEditClick = (field, currentValue) => {
    setEditingField(field);
    setEditValue(currentValue);
  };

  const handleSaveEdit = async () => {
    try {
      const payload = { [editingField]: editValue };
      const res = await apiFetch(`${baseUrl}/api/orders/admin/${selectedOrder.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        // Refresh details after successful edit
        fetchOrderDetails(selectedOrder.id);
        setEditingField(null);
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to update order"}`);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const getStatusColor = (status) => {
    const s = status?.toLowerCase();
    if (['delivered', 'confirmed'].includes(s)) return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400';
    if (['cancelled', 'returned'].includes(s)) return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400';
    if (['shipped', 'processing'].includes(s)) return 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400';
    return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400';
  };

  const getPaymentStatusColor = (status) => {
    const s = status?.toLowerCase();
    if (s === 'paid') return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400';
    if (s === 'failed') return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400';
    return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400';
  };

  return (
    <div className="p-6 md:p-8 max-w-7xl mx-auto w-full">
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        {view === "list" ? (
          <h1 className="text-2xl font-bold text-slate-800 dark:text-gray-100">Orders</h1>
        ) : (
          <div className="flex items-center gap-4">
            <button
              onClick={() => { setView("list"); setEditingField(null); }}
              className="p-2 bg-slate-100 hover:bg-slate-200 dark:bg-gray-800 dark:hover:bg-gray-700 rounded-lg transition text-slate-600 dark:text-gray-300"
            >
              <ChevronLeft size={20} />
            </button>
            <h1 className="text-2xl font-bold text-slate-800 dark:text-gray-100">
              Order Details <span className="text-sm font-normal text-slate-500 ml-2">Order ID: {selectedOrder?.id}</span>
            </h1>
          </div>
        )}
      </div>

      {errorMsg && (
         <div className="p-4 mb-6 bg-red-50 text-red-600 rounded-lg font-medium border border-red-100">
             {errorMsg}
         </div>
      )}

      {/* ListView Content */}
      {view === "list" && (
        <>
          <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 p-4 mb-6 flex flex-wrap items-end gap-4">
            <div className="flex-1 min-w-[200px]">
              <label className="block text-xs font-semibold text-slate-500 dark:text-gray-400 mb-1 uppercase tracking-wider">Search</label>
              <div className="relative">
                <span className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <Search size={16} className="text-slate-400" />
                </span>
                <input 
                  type="text" 
                  value={searchTerm} 
                  onChange={(e) => setSearchTerm(e.target.value)} 
                  className="w-full pl-10 pr-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" 
                  placeholder="Search by ID or Customer Name..." 
                />
              </div>
            </div>
            <div className="w-full md:w-40">
              <label className="block text-xs font-semibold text-slate-500 dark:text-gray-400 mb-1 uppercase tracking-wider">Status</label>
              <select name="status" value={filterForm.status} onChange={(e) => setFilterForm({ ...filterForm, status: e.target.value })} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm">
                <option value="">All</option>
                <option value="reserved">Reserved</option>
                <option value="processing">Processing</option>
                <option value="shipped">Shipped</option>
                <option value="delivered">Delivered</option>
                <option value="cancelled">Cancelled</option>
              </select>
            </div>
            <div className="w-full md:w-40">
              <label className="block text-xs font-semibold text-slate-500 dark:text-gray-400 mb-1 uppercase tracking-wider">Payment</label>
              <select name="paymentStatus" value={filterForm.paymentStatus} onChange={(e) => setFilterForm({ ...filterForm, paymentStatus: e.target.value })} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm">
                <option value="">All</option>
                <option value="paid">Paid</option>
                <option value="pending">Pending</option>
                <option value="failed">Failed</option>
                <option value="refund_initiated">Refund Initiated</option>
                <option value="refunded">Refunded</option>
              </select>
            </div>
            <div className="w-full md:w-40">
              <label className="block text-xs font-semibold text-slate-500 dark:text-gray-400 mb-1 uppercase tracking-wider">Sort</label>
              <select name="sort" value={filterForm.sort} onChange={(e) => setFilterForm({ ...filterForm, sort: e.target.value })} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm">
                <option value="">Newest</option>
                <option value="oldest">Oldest</option>
                <option value="amount_desc">Amount (High-Low)</option>
                <option value="amount_asc">Amount (Low-High)</option>
              </select>
            </div>
            <button onClick={() => { setFilterForm({ status: "", paymentStatus: "", sort: "" }); setSearchTerm(""); }} className="px-3 py-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-gray-800 rounded-lg transition" title="Clear Filters">
              <FilterX size={18} />
            </button>
          </div>

          <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50 dark:bg-gray-800 border-b border-slate-200 dark:border-gray-700">
                    <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Assigned Vendor</th>
                    <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Customer</th>
                    <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Status</th>
                    <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Payment</th>
                    <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Items / Total</th>
                    <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300 text-center">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {loading ? (
                    <tr><td colSpan="6" className="p-8 text-center text-slate-500">Loading orders...</td></tr>
                  ) : filteredOrders.length === 0 ? (
                    <tr><td colSpan="6" className="p-8 text-center text-slate-500">No orders found.</td></tr>
                  ) : (
                    filteredOrders.map((order) => {
                      const itemCount = order.items?.reduce((sum, item) => sum + item.quantity, 0) || 0;
                      // Determine the unique vendor(s) involved in this order
                      const uniqueVendors = Array.from(new Set(order.items?.map(i => i.vendor?.vendorProfile?.storeName || i.vendor?.name).filter(Boolean)));
                      
                      return (
                        <tr key={order.id} className="border-b border-slate-100 dark:border-gray-800 hover:bg-slate-50 dark:hover:bg-gray-800/50 transition">
                          <td className="p-4 text-sm font-medium text-slate-700 dark:text-gray-300">
                            {uniqueVendors.length > 0 ? uniqueVendors.join(', ') : "N/A"}
                          </td>
                          <td className="p-4">
                            <span className="block font-medium text-slate-800 dark:text-gray-200">{order.user?.name || "N/A"}</span>
                          </td>
                          <td className="p-4">
                            <span className={`px-2 py-1 text-[10px] uppercase tracking-wider rounded font-medium ${getStatusColor(order.orderStatus)}`}>
                              {order.orderStatus}
                            </span>
                          </td>
                          <td className="p-4">
                            <span className="block text-xs font-semibold mb-1 uppercase tracking-widest text-slate-400">{order.paymentMethod}</span>
                            <span className={`px-2 py-0.5 text-[10px] uppercase tracking-wider rounded font-medium ${getPaymentStatusColor(order.paymentStatus)}`}>
                              {order.paymentStatus}
                            </span>
                          </td>
                          <td className="p-4">
                            <span className="block text-sm text-slate-500 mb-0.5">{itemCount} items</span>
                            <span className="block font-medium text-slate-800 dark:text-gray-200">${Number(order.totalAmount).toFixed(2)}</span>
                          </td>
                          <td className="p-4 flex items-center justify-center">
                            <button
                              onClick={() => fetchOrderDetails(order.id)}
                              className="flex items-center gap-1.5 px-3 py-1.5 text-sm bg-teal-50 hover:bg-teal-100 text-teal-600 dark:bg-teal-900/30 dark:hover:bg-teal-900/50 dark:text-teal-400 rounded-lg transition"
                            >
                              <Eye size={16} /> View
                            </button>
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}

      {/* Details View Content */}
      {view === "details" && selectedOrder && (
        <div className="space-y-6">
          
          {/* Top Row - Summary Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            
            {/* Status Card */}
            <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 p-5 flex flex-col h-full">
              <h3 className="text-sm font-bold text-slate-800 dark:text-gray-100 mb-4 border-b border-slate-100 dark:border-gray-800 pb-2">Order Status</h3>
              
              <div className="space-y-4 flex-1">
                {/* Order Status Editable */}
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Fulfillment</span>
                  {editingField === 'orderStatus' ? (
                    <div className="flex items-center gap-2">
                      <select value={editValue} onChange={e => setEditValue(e.target.value)} className="text-xs p-1 border rounded bg-white dark:bg-gray-800 dark:text-white dark:border-gray-700">
                        <option value="reserved">Reserved</option>
                        <option value="processing">Processing</option>
                        <option value="shipped">Shipped</option>
                        <option value="delivered">Delivered</option>
                        <option value="return_requested">Return Req.</option>
                        <option value="returned">Returned</option>
                        <option value="cancelled">Cancelled</option>
                      </select>
                      <button onClick={handleSaveEdit} className="text-green-600 hover:bg-green-50 p-1 rounded"><Check size={16}/></button>
                      <button onClick={() => setEditingField(null)} className="text-slate-400 hover:bg-slate-50 p-1 rounded"><X size={16}/></button>
                    </div>
                  ) : (
                    <div className="flex items-center gap-2">
                      <span className={`px-2 py-1 text-[10px] uppercase tracking-wider rounded font-medium ${getStatusColor(selectedOrder.orderStatus)}`}>
                        {selectedOrder.orderStatus}
                      </span>
                      <button onClick={() => handleEditClick('orderStatus', selectedOrder.orderStatus)} className="text-slate-400 hover:text-blue-600 transition"><Edit2 size={14}/></button>
                    </div>
                  )}
                </div>

                {/* Payment Status Editable */}
                <div className="flex items-center justify-between">
                  <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Payment ({selectedOrder.paymentMethod})</span>
                  {editingField === 'paymentStatus' ? (
                    <div className="flex items-center gap-2">
                      <select value={editValue} onChange={e => setEditValue(e.target.value)} className="text-xs p-1 border rounded bg-white dark:bg-gray-800 dark:text-white dark:border-gray-700">
                        <option value="reserved">Reserved</option>
                        <option value="pending">Pending</option>
                        <option value="paid">Paid</option>
                        <option value="failed">Failed</option>
                        <option value="refund_initiated">Refund Init.</option>
                      </select>
                      <button onClick={handleSaveEdit} className="text-green-600 hover:bg-green-50 p-1 rounded"><Check size={16}/></button>
                      <button onClick={() => setEditingField(null)} className="text-slate-400 hover:bg-slate-50 p-1 rounded"><X size={16}/></button>
                    </div>
                  ) : (
                    <div className="flex items-center gap-2">
                      <span className={`px-2 py-1 text-[10px] uppercase tracking-wider rounded font-medium ${getPaymentStatusColor(selectedOrder.paymentStatus)}`}>
                        {selectedOrder.paymentStatus}
                      </span>
                      <button onClick={() => handleEditClick('paymentStatus', selectedOrder.paymentStatus)} className="text-slate-400 hover:text-blue-600 transition"><Edit2 size={14}/></button>
                    </div>
                  )}
                </div>

                <div className="flex items-center justify-between mt-4 pt-4 border-t border-slate-100 dark:border-gray-800">
                  <span className="text-xs font-semibold text-slate-500 uppercase tracking-wider">Total</span>
                  <span className="font-bold text-lg text-slate-800 dark:text-gray-100">${Number(selectedOrder.totalAmount).toFixed(2)}</span>
                </div>
              </div>
            </div>

            {/* Customer Details Card */}
            <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 p-5 flex flex-col h-full">
              <h3 className="text-sm font-bold text-slate-800 dark:text-gray-100 mb-4 border-b border-slate-100 dark:border-gray-800 pb-2">Customer & Shipping</h3>
              <div className="space-y-3 text-sm text-slate-700 dark:text-gray-300 flex-1 overflow-y-auto">
                <div>
                  <span className="block text-[10px] font-semibold text-slate-400 uppercase tracking-wider">Name</span>
                  <p className="font-medium text-slate-800 dark:text-gray-200">{selectedOrder.user?.name || "N/A"}</p>
                </div>
                <div>
                  <span className="block text-[10px] font-semibold text-slate-400 uppercase tracking-wider">Contact</span>
                  <p>{selectedOrder.user?.email || "N/A"}</p>
                  <p>{selectedOrder.user?.phone || "N/A"}</p>
                </div>
                {selectedOrder.shippingAddress && (
                  <div>
                    <span className="block text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Shipping Address</span>
                    <p className="bg-slate-50 dark:bg-gray-800 p-2 rounded border border-slate-100 dark:border-gray-700 text-xs">
                      {selectedOrder.shippingAddress.addressLine1}, {selectedOrder.shippingAddress.addressLine2 && `${selectedOrder.shippingAddress.addressLine2}, `}
                      {selectedOrder.shippingAddress.city}, {selectedOrder.shippingAddress.state} - {selectedOrder.shippingAddress.postal_code}, {selectedOrder.shippingAddress.country}
                    </p>
                  </div>
                )}
              </div>
            </div>

            {/* Assigned Vendor Details Card */}
            <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 p-5 flex flex-col h-full">
              <h3 className="text-sm font-bold text-slate-800 dark:text-gray-100 mb-4 border-b border-slate-100 dark:border-gray-800 pb-2">Assigned Vendor(s)</h3>
              <div className="space-y-4 text-sm text-slate-700 dark:text-gray-300 flex-1 overflow-y-auto">
                {selectedOrder.items && selectedOrder.items.some(i => i.vendor) ? (
                  Array.from(new Map(selectedOrder.items.filter(i => i.vendor).map(i => [i.vendor.id, i.vendor])).values()).map(vendor => (
                    <div key={vendor.id} className="pb-3 border-b border-slate-50 dark:border-gray-800 last:border-0 last:pb-0">
                      <div>
                        <span className="block text-[10px] font-semibold text-slate-400 uppercase tracking-wider">Store Name</span>
                        <p className="font-medium text-slate-800 dark:text-gray-200">{vendor.vendorProfile?.storeName || "N/A"}</p>
                      </div>
                      <div className="mt-2">
                        <span className="block text-[10px] font-semibold text-slate-400 uppercase tracking-wider">Vendor Name</span>
                        <p className="font-medium text-slate-800 dark:text-gray-200">{vendor.name}</p>
                      </div>
                      <div className="mt-2">
                        <span className="block text-[10px] font-semibold text-slate-400 uppercase tracking-wider">Contact</span>
                        <p>{vendor.email}</p>
                        <p>{vendor.vendorProfile?.businessPhone || vendor.phone}</p>
                      </div>
                    </div>
                  ))
                ) : (
                  <p className="text-xs text-slate-500 italic">No vendor details available.</p>
                )}
              </div>
            </div>

          </div>

          {/* Bottom Row - Items List */}
          <div className="w-full">
            <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 overflow-hidden">
              <div className="p-5 border-b border-slate-100 dark:border-gray-800 flex justify-between items-center">
                 <h3 className="text-sm font-bold text-slate-800 dark:text-gray-100">Order Items ({selectedOrder.items?.length || 0})</h3>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-slate-50 dark:bg-gray-800 border-b border-slate-200 dark:border-gray-700">
                      <th className="p-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">Item Details</th>
                      <th className="p-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">Vendor Info</th>
                      <th className="p-4 text-xs font-semibold text-slate-500 uppercase tracking-wider text-right">Price</th>
                      <th className="p-4 text-xs font-semibold text-slate-500 uppercase tracking-wider text-right">Qty</th>
                      <th className="p-4 text-xs font-semibold text-slate-500 uppercase tracking-wider text-right">Subtotal</th>
                    </tr>
                  </thead>
                  <tbody>
                    {selectedOrder.items?.map((item) => (
                      <tr key={item.id} className="border-b border-slate-100 dark:border-gray-800 last:border-0 hover:bg-slate-50 dark:hover:bg-gray-800/50 transition">
                        <td className="p-4">
                          <p className="font-medium text-slate-800 dark:text-gray-200 text-sm max-w-[200px] truncate" title={item.product?.title}>
                            {item.product?.title || "Unknown Product"}
                          </p>
                          <p className="text-xs text-slate-500 dark:text-gray-400 mt-0.5">
                            {item.variant?.variantName || "Standard"} • <span className="font-mono">{item.variant?.sku}</span>
                          </p>
                        </td>
                        <td className="p-4 text-sm text-slate-600 dark:text-gray-300">
                          {item.vendor ? (
                            <>
                              <p className="font-medium text-xs">{item.vendor.vendorProfile?.storeName || item.vendor.name}</p>
                              <p className="text-[10px] text-slate-400">{item.vendor.email}</p>
                            </>
                          ) : <span className="text-slate-400 text-xs italic">Deleted Vendor</span>}
                        </td>
                        <td className="p-4 text-right text-sm text-slate-700 dark:text-gray-300">${Number(item.priceAtPurchase).toFixed(2)}</td>
                        <td className="p-4 text-right text-sm font-semibold text-slate-800 dark:text-gray-200">x{item.quantity}</td>
                        <td className="p-4 text-right text-sm font-bold text-slate-800 dark:text-gray-100">${(Number(item.priceAtPurchase) * item.quantity).toFixed(2)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </div>

        </div>
      )}
    </div>
  );
}