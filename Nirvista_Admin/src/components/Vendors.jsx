import React, { useState, useEffect } from "react";
import { Plus, Edit, User as UserIcon, X, Check } from "lucide-react";
import { apiFetch } from "../utils/api";

export default function Vendors() {
  const [vendors, setVendors] = useState([]);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState(null);
  const [modalType, setModalType] = useState(null); // 'create', 'edit', 'profile', null
  const [selectedVendor, setSelectedVendor] = useState(null);
  
  const defaultFormData = {
    name: "", email: "", phone: "", userStatus: "active",
    storeName: "", storeDescription: "", businessEmail: "", businessPhone: "",
    businessAddress: "", businessRegistrationNumber: "", taxId: "",
    bankAccountName: "", bankAccountNumber: "", bankName: "", bankIFSC: "", statusReason: ""
  };
  
  const [formData, setFormData] = useState(defaultFormData);

  const baseUrl = import.meta.env.VITE_BASE_URL || "";

  useEffect(() => {
    fetchVendors();
  }, []);

  const fetchVendors = async () => {
    setLoading(true);
    setErrorMsg(null);
    try {
      const res = await apiFetch(`${baseUrl}/api/admin/vendors`);
      
      const contentType = res.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
         setErrorMsg("Backend Route Missing: The server returned a 404 HTML page instead of JSON data. Check your adminRoutes.js.");
         setVendors([]);
         setLoading(false);
         return;
      }

      const data = await res.json();
      
      if (res.ok && data) {
        if (Array.isArray(data.data)) {
           setVendors(data.data);
        } else if (data.data && Array.isArray(data.data.vendors)) {
           setVendors(data.data.vendors); 
        } else if (Array.isArray(data.vendors)) {
           setVendors(data.vendors);
        } else if (Array.isArray(data)) {
           setVendors(data);
        } else {
           setVendors([]); 
        }
      } else {
        setErrorMsg(data?.message || "Failed to fetch vendors.");
        setVendors([]);
      }
    } catch (err) {
      setErrorMsg(`Network Error: ${err.message}`);
      setVendors([]); 
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (vendorId, newStatus) => {
    try {
      const res = await apiFetch(`${baseUrl}/api/admin/vendors/${vendorId}/status`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: newStatus }),
      });

      if (res.ok) {
        fetchVendors(); // Refresh to show dynamic updates
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to update vendor status"}`);
      }
    } catch (error) {
      console.error("Status update error:", error);
    }
  };

  const handleInputChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const openCreateModal = () => {
    setFormData(defaultFormData);
    setModalType("create");
  };

  const openEditModal = (vendor) => {
    setSelectedVendor(vendor);
    setFormData({
      name: vendor.name || "",
      email: vendor.email || "",
      phone: vendor.phone || "",
      userStatus: vendor.userStatus || "active",
      // Pull existing profile data if available
      storeName: vendor.vendorProfile?.storeName || "",
      storeDescription: vendor.vendorProfile?.storeDescription || "",
      businessEmail: vendor.vendorProfile?.businessEmail || "",
      businessPhone: vendor.vendorProfile?.businessPhone || "",
      businessAddress: vendor.vendorProfile?.businessAddress || "",
      businessRegistrationNumber: vendor.vendorProfile?.businessRegistrationNumber || "",
      taxId: vendor.vendorProfile?.taxId || "",
      bankAccountName: vendor.vendorProfile?.bankAccountName || "",
      bankAccountNumber: vendor.vendorProfile?.bankAccountNumber || "",
      bankName: vendor.vendorProfile?.bankName || "",
      bankIFSC: vendor.vendorProfile?.bankIFSC || "",
      statusReason: vendor.vendorProfile?.statusReason || ""
    });
    setModalType("edit");
  };

  const openProfileModal = (vendor) => {
    setSelectedVendor(vendor);
    setModalType("profile");
  };

  const closeModal = () => {
    setModalType(null);
    setSelectedVendor(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const isEditing = modalType === "edit";
    // Pointing to the distinct endpoints defined in your updated routes
    const url = isEditing 
        ? `${baseUrl}/api/admin/vendors/${selectedVendor.id || selectedVendor._id}/details`
        : `${baseUrl}/api/admin/vendors`;
    const method = isEditing ? "PUT" : "POST"; 

    try {
      const res = await apiFetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });

      const contentType = res.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
        const errorText = await res.text();
        console.error("Expected JSON but received HTML:", errorText);
        alert("Error: Backend route missing (404) or Server Crashed.");
        return;
      }

      if (res.ok) {
        fetchVendors();
        closeModal();
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Something went wrong"}`);
      }
    } catch (err) {
      console.error("Error saving vendor:", err);
      alert(`Request failed: ${err.message}`);
    }
  };

  return (
    <div className="p-6 md:p-8 max-w-7xl mx-auto w-full">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-slate-800 dark:text-gray-100">Vendors</h1>
        <button
          onClick={openCreateModal}
          className="flex items-center gap-2 bg-teal-600 hover:bg-teal-700 text-white px-4 py-2 rounded-lg transition font-medium"
        >
          <Plus size={18} />
          Create Vendor
        </button>
      </div>

      {errorMsg && (
         <div className="p-4 mb-6 bg-red-50 text-red-600 rounded-lg font-medium border border-red-100">
             {errorMsg}
         </div>
      )}

      <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 dark:bg-gray-800 border-b border-slate-200 dark:border-gray-700">
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Name</th>
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Email</th>
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Phone</th>
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Status</th>
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300 text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="5" className="p-8 text-center text-slate-500">Loading vendors...</td>
                </tr>
              ) : vendors.length === 0 ? (
                <tr>
                  <td colSpan="5" className="p-8 text-center text-slate-500">No vendors found.</td>
                </tr>
              ) : (
                vendors.map((vendor, idx) => (
                  <tr key={idx} className="border-b border-slate-100 dark:border-gray-800 hover:bg-slate-50 dark:hover:bg-gray-800/50 transition">
                    <td className="p-4 text-slate-800 dark:text-gray-200 font-medium">{vendor.vendorProfile?.storeName || vendor.name}</td>
                    <td className="p-4 text-slate-600 dark:text-gray-400">{vendor.email}</td>
                    <td className="p-4 text-slate-600 dark:text-gray-400">{vendor.phone}</td>
                    <td className="p-4">
                      <select
                          value={vendor.userStatus?.toLowerCase()}
                          onChange={(e) => handleStatusChange(vendor.id || vendor._id, e.target.value)}
                          className={`px-2 py-1.5 text-xs rounded-full font-semibold outline-none cursor-pointer border border-transparent hover:border-slate-300 dark:hover:border-gray-600 appearance-none text-center ${
                            (vendor.userStatus?.toLowerCase() === 'active' || vendor.userStatus?.toLowerCase() === 'approved') ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400' :
                            (vendor.userStatus?.toLowerCase() === 'suspended' || vendor.userStatus?.toLowerCase() === 'deleted' || vendor.userStatus?.toLowerCase() === 'rejected') ? 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400' : 
                            'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400'
                          }`}
                        >
                          <option value="approved" className="bg-white text-slate-800 dark:bg-gray-800 dark:text-gray-100">Approved</option>
                          <option value="pending" className="bg-white text-slate-800 dark:bg-gray-800 dark:text-gray-100">Pending</option>
                          <option value="suspended" className="bg-white text-slate-800 dark:bg-gray-800 dark:text-gray-100">Suspended</option>
                          <option value="rejected" className="bg-white text-slate-800 dark:bg-gray-800 dark:text-gray-100">Rejected</option>
                      </select>
                    </td>
                    <td className="p-4 flex items-center justify-center gap-3">
                      <button
                        onClick={() => openProfileModal(vendor)}
                        className="p-1.5 text-teal-600 hover:bg-teal-50 dark:hover:bg-teal-900/30 rounded transition"
                        title="Show Profile"
                      >
                        <UserIcon size={18} />
                      </button>
                      <button
                        onClick={() => openEditModal(vendor)}
                        className="p-1.5 text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded transition"
                        title="Edit Vendor Details"
                      >
                        <Edit size={18} />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modals Container */}
      {modalType && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className={`bg-white dark:bg-gray-900 rounded-xl shadow-xl w-full ${modalType === 'profile' ? 'max-w-2xl' : 'max-w-3xl'} overflow-hidden animate-in fade-in zoom-in duration-200 flex flex-col max-h-[90vh]`}>
            <div className="flex justify-between items-center p-5 border-b border-slate-100 dark:border-gray-800 shrink-0">
              <h2 className="text-lg font-semibold text-slate-800 dark:text-white">
                {modalType === "create" ? "Create Vendor" : modalType === "edit" ? "Edit Vendor Details" : "Vendor Profile"}
              </h2>
              <button onClick={closeModal} className="text-slate-400 hover:text-slate-600 dark:hover:text-gray-300">
                <X size={20} />
              </button>
            </div>

            {/* Profile View */}
            {modalType === "profile" && selectedVendor && (
              <div className="p-6 space-y-6 text-slate-700 dark:text-gray-300 overflow-y-auto">
                {/* User Information */}
                <div>
                  <h3 className="text-sm font-bold text-teal-600 dark:text-teal-400 mb-3 border-b border-slate-100 dark:border-gray-800 pb-1">User Information</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Name</span>
                      <p className="font-medium text-slate-900 dark:text-white">{selectedVendor.name}</p>
                    </div>
                    <div>
                      <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Email</span>
                      <p>{selectedVendor.email}</p>
                    </div>
                    <div>
                      <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Phone</span>
                      <p>{selectedVendor.phone}</p>
                    </div>
                    <div>
                      <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Account Status</span>
                      <span className={`inline-block mt-1 px-2 py-1 text-xs rounded-full font-medium ${
                            selectedVendor.userStatus?.toLowerCase() === 'active' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                          }`}>
                        {selectedVendor.userStatus}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Business Information */}
                {selectedVendor.vendorProfile ? (
                  <>
                    <div>
                      <h3 className="text-sm font-bold text-teal-600 dark:text-teal-400 mb-3 border-b border-slate-100 dark:border-gray-800 pb-1">Business Information</h3>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Store Name</span>
                          <p className="font-medium text-slate-900 dark:text-white">{selectedVendor.vendorProfile.storeName || "N/A"}</p>
                        </div>
                        <div>
                          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Vendor Status</span>
                          <span className="capitalize">{selectedVendor.vendorProfile.vendorStatus || "N/A"}</span>
                        </div>
                        <div className="col-span-1 md:col-span-2">
                          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Store Description</span>
                          <p className="text-sm mt-1">{selectedVendor.vendorProfile.storeDescription || "N/A"}</p>
                        </div>
                        <div>
                          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Business Email</span>
                          <p>{selectedVendor.vendorProfile.businessEmail || "N/A"}</p>
                        </div>
                        <div>
                          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Business Phone</span>
                          <p>{selectedVendor.vendorProfile.businessPhone || "N/A"}</p>
                        </div>
                        <div className="col-span-1 md:col-span-2">
                          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Business Address</span>
                          <p className="text-sm mt-1">{selectedVendor.vendorProfile.businessAddress || "N/A"}</p>
                        </div>
                        <div>
                          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Reg. Number</span>
                          <p>{selectedVendor.vendorProfile.businessRegistrationNumber || "N/A"}</p>
                        </div>
                        <div>
                          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Tax ID</span>
                          <p>{selectedVendor.vendorProfile.taxId || "N/A"}</p>
                        </div>
                      </div>
                    </div>

                    {/* Bank Details */}
                    <div>
                      <h3 className="text-sm font-bold text-teal-600 dark:text-teal-400 mb-3 border-b border-slate-100 dark:border-gray-800 pb-1">Bank Details</h3>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Bank Name</span>
                          <p>{selectedVendor.vendorProfile.bankName || "N/A"}</p>
                        </div>
                        <div>
                          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Account Name</span>
                          <p>{selectedVendor.vendorProfile.bankAccountName || "N/A"}</p>
                        </div>
                        <div>
                          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Account Number</span>
                          <p>{selectedVendor.vendorProfile.bankAccountNumber || "N/A"}</p>
                        </div>
                        <div>
                          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">IFSC Code</span>
                          <p>{selectedVendor.vendorProfile.bankIFSC || "N/A"}</p>
                        </div>
                      </div>
                    </div>
                    
                    {/* Admin Status Details */}
                    {selectedVendor.vendorProfile.statusReason && (
                      <div>
                        <h3 className="text-sm font-bold text-teal-600 dark:text-teal-400 mb-3 border-b border-slate-100 dark:border-gray-800 pb-1">Admin Notes</h3>
                        <div>
                          <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider">Status Reason</span>
                          <p className="text-red-600 dark:text-red-400 text-sm mt-1">{selectedVendor.vendorProfile.statusReason}</p>
                        </div>
                      </div>
                    )}
                  </>
                ) : (
                  <div className="p-4 bg-slate-50 dark:bg-gray-800 rounded-lg text-center text-sm border border-slate-100 dark:border-gray-700">
                    No business profile information available for this vendor.
                  </div>
                )}
              </div>
            )}

            {/* Form View (Create/Edit) */}
            {(modalType === "create" || modalType === "edit") && (
              <form onSubmit={handleSubmit} className="p-6 space-y-6 overflow-y-auto">
                
                {/* 1. User Information */}
                <div>
                  <h3 className="text-sm font-bold text-teal-600 dark:text-teal-400 mb-3 border-b border-slate-100 dark:border-gray-800 pb-1">User Information</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Full Name</label>
                      <input required type="text" name="name" value={formData.name} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Email</label>
                      <input required type="email" name="email" value={formData.email} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Phone</label>
                      <input required type="tel" name="phone" value={formData.phone} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                    {/* Only show User Status select during creation; editing is handled inline in the table */}
                    {modalType === "create" && (
                      <div>
                        <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Initial Status</label>
                        <select name="userStatus" value={formData.userStatus} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm">
                          <option value="active">Active</option>
                          <option value="pending">Pending</option>
                        </select>
                      </div>
                    )}
                  </div>
                </div>

                {/* 2. Business Information */}
                <div>
                  <h3 className="text-sm font-bold text-teal-600 dark:text-teal-400 mb-3 border-b border-slate-100 dark:border-gray-800 pb-1">Business Profile</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Store Name</label>
                      <input type="text" name="storeName" value={formData.storeName} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Business Email</label>
                      <input type="email" name="businessEmail" value={formData.businessEmail} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                    <div className="md:col-span-2">
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Store Description</label>
                      <textarea name="storeDescription" value={formData.storeDescription} onChange={handleInputChange} rows="2" className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                    <div className="md:col-span-2">
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Business Address</label>
                      <input type="text" name="businessAddress" value={formData.businessAddress} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Business Phone</label>
                      <input type="tel" name="businessPhone" value={formData.businessPhone} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Registration Number</label>
                      <input type="text" name="businessRegistrationNumber" value={formData.businessRegistrationNumber} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Tax ID</label>
                      <input type="text" name="taxId" value={formData.taxId} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                  </div>
                </div>

                {/* 3. Bank Details */}
                <div>
                  <h3 className="text-sm font-bold text-teal-600 dark:text-teal-400 mb-3 border-b border-slate-100 dark:border-gray-800 pb-1">Bank Details</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Bank Name</label>
                      <input type="text" name="bankName" value={formData.bankName} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Account Name</label>
                      <input type="text" name="bankAccountName" value={formData.bankAccountName} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Account Number</label>
                      <input type="text" name="bankAccountNumber" value={formData.bankAccountNumber} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                    <div>
                      <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">IFSC Code</label>
                      <input type="text" name="bankIFSC" value={formData.bankIFSC} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" />
                    </div>
                  </div>
                </div>

                {/* 4. Admin Notes */}
                <div>
                  <h3 className="text-sm font-bold text-teal-600 dark:text-teal-400 mb-3 border-b border-slate-100 dark:border-gray-800 pb-1">Admin Notes</h3>
                  <div>
                    <label className="block text-xs font-medium text-slate-700 dark:text-gray-300 mb-1">Status Reason (Internal tracking)</label>
                    <textarea name="statusReason" value={formData.statusReason} onChange={handleInputChange} rows="2" className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" placeholder="Reason for approval, suspension, or manual changes..." />
                  </div>
                </div>

                {/* Footer Controls */}
                <div className="pt-6 border-t border-slate-100 dark:border-gray-800 flex gap-3 justify-end shrink-0">
                  <button
                    type="button"
                    onClick={closeModal}
                    className="px-4 py-2 text-slate-600 dark:text-gray-300 hover:bg-slate-100 dark:hover:bg-gray-800 rounded-lg transition"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="px-4 py-2 bg-teal-600 hover:bg-teal-700 text-white rounded-lg transition font-medium"
                  >
                    {modalType === "create" ? "Create Vendor" : "Save Details"}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
}