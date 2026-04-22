import React, { useState, useEffect } from "react";
import { Plus, Edit, Trash2, X, Search } from "lucide-react";
import { getToken } from "../utils/auth";
import { apiFetch } from "../utils/api";

export default function Brands() {
  const [brands, setBrands] = useState([]);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState(null);
  
  const [searchTerm, setSearchTerm] = useState("");
  const [modalType, setModalType] = useState(null); // 'create', 'edit'
  const [selectedBrand, setSelectedBrand] = useState(null);
  
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    logoUrl: "",
  });

  const baseUrl = import.meta.env.VITE_BASE_URL || "";

  useEffect(() => {
    fetchBrands();
  }, []);

  const fetchBrands = async () => {
    setLoading(true);
    setErrorMsg(null);
    try {
      const res = await apiFetch(`${baseUrl}/api/brands`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });

      const contentType = res.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
        setErrorMsg("Backend crashed. Check server logs.");
        setBrands([]);
        return;
      }

      const data = await res.json();
      if (res.ok && data) {
        setBrands(data.data || data);
      } else {
        setErrorMsg(data.message || "Failed to fetch brands");
        setBrands([]);
      }
    } catch (err) {
      setErrorMsg(`Network Error: ${err.message}`);
      setBrands([]);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const openCreateModal = () => {
    setFormData({ name: "", description: "", logoUrl: "" });
    setModalType("create");
  };

  const openEditModal = (brand) => {
    setSelectedBrand(brand);
    setFormData({
      name: brand.name || "",
      description: brand.description || "",
      logoUrl: brand.logoUrl || "",
    });
    setModalType("edit");
  };

  const closeModal = () => {
    setModalType(null);
    setSelectedBrand(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const isEditing = modalType === "edit";
    const url = isEditing 
      ? `${baseUrl}/api/brands/${selectedBrand.id}` 
      : `${baseUrl}/api/brands`;
    const method = isEditing ? "PUT" : "POST";

    try {
      const res = await apiFetch(url, {
        method,
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify(formData),
      });

      if (res.ok) {
        fetchBrands();
        closeModal();
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to save brand"}`);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Are you sure you want to delete this brand?")) return;
    try {
      const res = await apiFetch(`${baseUrl}/api/brands/${id}`, {
        method: "DELETE",
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      if (res.ok) {
        fetchBrands();
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to delete"}`);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const filteredBrands = brands.filter(brand => 
    brand.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (brand.description && brand.description.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  return (
    <div className="p-6 md:p-8 max-w-7xl mx-auto w-full">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-slate-800 dark:text-gray-100">Brands</h1>
        <button onClick={openCreateModal} className="flex items-center gap-2 bg-teal-600 hover:bg-teal-700 text-white px-4 py-2 rounded-lg transition font-medium">
          <Plus size={18} />
          Create Brand
        </button>
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 p-4 mb-6">
        <div className="relative max-w-md">
          <span className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search size={16} className="text-slate-400" />
          </span>
          <input 
            type="text" 
            value={searchTerm} 
            onChange={(e) => setSearchTerm(e.target.value)} 
            className="w-full pl-10 pr-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" 
            placeholder="Search brands by name or description..." 
          />
        </div>
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 dark:bg-gray-800 border-b border-slate-200 dark:border-gray-700">
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Logo</th>
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Name</th>
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Description</th>
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300 text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan="4" className="p-8 text-center text-slate-500">Loading brands...</td></tr>
              ) : errorMsg ? (
                <tr><td colSpan="4" className="p-8 text-center text-red-500 font-medium bg-red-50 dark:bg-red-900/20">{errorMsg}</td></tr>
              ) : filteredBrands.length === 0 ? (
                <tr><td colSpan="4" className="p-8 text-center text-slate-500">No brands found.</td></tr>
              ) : (
                filteredBrands.map((brand) => (
                  <tr key={brand.id} className="border-b border-slate-100 dark:border-gray-800 hover:bg-slate-50 dark:hover:bg-gray-800/50 transition">
                    <td className="p-4">
                      {brand.logoUrl ? (
                        <img src={brand.logoUrl} alt={brand.name} className="h-10 w-10 object-contain rounded-md border border-slate-200 dark:border-gray-700 bg-white" />
                      ) : (
                        <div className="h-10 w-10 bg-slate-100 dark:bg-gray-800 flex items-center justify-center rounded-md border border-slate-200 dark:border-gray-700 text-xs text-slate-400">N/A</div>
                      )}
                    </td>
                    <td className="p-4 text-slate-800 dark:text-gray-200 font-medium">{brand.name}</td>
                    <td className="p-4 text-slate-600 dark:text-gray-400 text-sm truncate max-w-sm">{brand.description || "No description"}</td>
                    <td className="p-4 flex items-center justify-center gap-3">
                      <button onClick={() => openEditModal(brand)} className="p-1.5 text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded transition" title="Edit">
                        <Edit size={18} />
                      </button>
                      <button onClick={() => handleDelete(brand.id)} className="p-1.5 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/30 rounded transition" title="Delete">
                        <Trash2 size={18} />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {modalType && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white dark:bg-gray-900 rounded-xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in duration-200 flex flex-col">
            <div className="flex justify-between items-center p-5 border-b border-slate-100 dark:border-gray-800 shrink-0">
              <h2 className="text-lg font-semibold text-slate-800 dark:text-white">
                {modalType === "create" ? "Create Brand" : "Edit Brand"}
              </h2>
              <button onClick={closeModal} className="text-slate-400 hover:text-slate-600 dark:hover:text-gray-300">
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleSubmit} className="p-6 space-y-4 overflow-y-auto">
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Brand Name</label>
                <input required type="text" name="name" value={formData.name} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Logo URL</label>
                <input type="url" name="logoUrl" value={formData.logoUrl} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" placeholder="https://example.com/logo.png" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Description</label>
                <textarea name="description" value={formData.description} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" rows="4" />
              </div>
              <div className="pt-4 flex gap-3 justify-end shrink-0">
                <button type="button" onClick={closeModal} className="px-4 py-2 text-slate-600 dark:text-gray-300 hover:bg-slate-100 dark:hover:bg-gray-800 rounded-lg transition">Cancel</button>
                <button type="submit" className="px-4 py-2 bg-teal-600 hover:bg-teal-700 text-white rounded-lg transition font-medium">
                  {modalType === "create" ? "Create" : "Save Changes"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}