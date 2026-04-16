import React, { useState, useEffect } from "react";
import { Plus, Edit, Trash2, X } from "lucide-react";
import { getToken } from "../utils/auth";
import { apiFetch } from "../utils/api";

export default function Categories() {
  const [categories, setCategories] = useState([]);
  const [flatCategories, setFlatCategories] = useState([]);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState(null);
  
  const [modalType, setModalType] = useState(null); // 'create', 'edit'
  const [selectedCategory, setSelectedCategory] = useState(null);
  
  const [formData, setFormData] = useState({
    name: "",
    slug: "",
    description: "",
    parentId: "",
  });

  const baseUrl = import.meta.env.VITE_BASE_URL || "";

  useEffect(() => {
    fetchCategories();
  }, []);

  const flattenTree = (nodes, level = 0) => {
    let flat = [];
    nodes.forEach(node => {
      flat.push({ ...node, level });
      if (node.children && node.children.length > 0) {
        flat = flat.concat(flattenTree(node.children, level + 1));
      }
    });
    return flat;
  };

  const fetchCategories = async () => {
    setLoading(true);
    setErrorMsg(null);
    try {
      const res = await apiFetch(`${baseUrl}/api/categories`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });

      const contentType = res.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
        setErrorMsg("Backend crashed. Check server logs.");
        setCategories([]);
        return;
      }

      const data = await res.json();
      if (res.ok && data) {
        const treeData = data.data || data;
        setCategories(treeData);
        setFlatCategories(flattenTree(Array.isArray(treeData) ? treeData : []));
      } else {
        setErrorMsg(data.message || "Failed to fetch categories");
        setCategories([]);
      }
    } catch (err) {
      setErrorMsg(`Network Error: ${err.message}`);
      setCategories([]);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const openCreateModal = () => {
    setFormData({ name: "", slug: "", description: "", parentId: "" });
    setModalType("create");
  };

  const openEditModal = (category) => {
    setSelectedCategory(category);
    setFormData({
      name: category.name || "",
      slug: category.slug || "",
      description: category.description || "",
      parentId: category.parentId || "",
    });
    setModalType("edit");
  };

  const closeModal = () => {
    setModalType(null);
    setSelectedCategory(null);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const isEditing = modalType === "edit";
    const url = isEditing 
      ? `${baseUrl}/api/categories/${selectedCategory.id}` 
      : `${baseUrl}/api/categories`;
    const method = isEditing ? "PUT" : "POST";

    const payload = { ...formData };
    if (!payload.parentId) payload.parentId = null;

    try {
      const res = await apiFetch(url, {
        method,
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify(payload),
      });

      if (res.ok) {
        fetchCategories();
        closeModal();
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to save category"}`);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Are you sure you want to delete this category?")) return;
    try {
      const res = await apiFetch(`${baseUrl}/api/categories/${id}`, {
        method: "DELETE",
        headers: { Authorization: `Bearer ${getToken()}` },
      });
      if (res.ok) {
        fetchCategories();
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to delete"}`);
      }
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <div className="p-6 md:p-8 max-w-7xl mx-auto w-full">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-slate-800 dark:text-gray-100">Categories</h1>
        <button onClick={openCreateModal} className="flex items-center gap-2 bg-teal-600 hover:bg-teal-700 text-white px-4 py-2 rounded-lg transition font-medium">
          <Plus size={18} />
          Create Category
        </button>
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 dark:bg-gray-800 border-b border-slate-200 dark:border-gray-700">
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Name</th>
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Slug</th>
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Description</th>
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300 text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan="4" className="p-8 text-center text-slate-500">Loading categories...</td></tr>
              ) : errorMsg ? (
                <tr><td colSpan="4" className="p-8 text-center text-red-500 font-medium bg-red-50 dark:bg-red-900/20">{errorMsg}</td></tr>
              ) : flatCategories.length === 0 ? (
                <tr><td colSpan="4" className="p-8 text-center text-slate-500">No categories found.</td></tr>
              ) : (
                flatCategories.map((cat) => (
                  <tr key={cat.id} className="border-b border-slate-100 dark:border-gray-800 hover:bg-slate-50 dark:hover:bg-gray-800/50 transition">
                    <td className="p-4 text-slate-800 dark:text-gray-200 font-medium">
                      <span style={{ marginLeft: `${cat.level * 20}px` }}>
                        {cat.level > 0 ? "↳ " : ""}{cat.name}
                      </span>
                    </td>
                    <td className="p-4 text-slate-600 dark:text-gray-400 text-sm font-mono">{cat.slug}</td>
                    <td className="p-4 text-slate-600 dark:text-gray-400 text-sm truncate max-w-xs">{cat.description || "N/A"}</td>
                    <td className="p-4 flex items-center justify-center gap-3">
                      <button onClick={() => openEditModal(cat)} className="p-1.5 text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded transition" title="Edit">
                        <Edit size={18} />
                      </button>
                      <button onClick={() => handleDelete(cat.id)} className="p-1.5 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/30 rounded transition" title="Delete">
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
                {modalType === "create" ? "Create Category" : "Edit Category"}
              </h2>
              <button onClick={closeModal} className="text-slate-400 hover:text-slate-600 dark:hover:text-gray-300">
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleSubmit} className="p-6 space-y-4 overflow-y-auto">
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Category Name</label>
                <input required type="text" name="name" value={formData.name} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Slug (URL friendly)</label>
                <input required type="text" name="slug" value={formData.slug} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" placeholder="e.g., mens-clothing" />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Parent Category</label>
                <select name="parentId" value={formData.parentId} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white">
                  <option value="">None (Top Level)</option>
                  {flatCategories.map(c => (
                    <option key={c.id} value={c.id} disabled={modalType === 'edit' && c.id === selectedCategory?.id}>
                      {c.level > 0 ? "—".repeat(c.level) + " " : ""}{c.name}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Description</label>
                <textarea name="description" value={formData.description} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" rows="3" />
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