import React, { useState, useEffect } from "react";
import { Plus, Edit, Trash2, X, Search } from "lucide-react";
import { apiFetch } from "../utils/api";

const baseUrl = import.meta.env.VITE_BASE_URL || "";

export default function Tags() {
  const [tags, setTags] = useState([]);
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState(null);
  
  const [searchTerm, setSearchTerm] = useState("");
  const [modalType, setModalType] = useState(null); // 'create' or 'edit'
  const [selectedTag, setSelectedTag] = useState(null);
  
  const [formData, setFormData] = useState({
    name: "",
    slug: ""
  });

  useEffect(() => {
    fetchTags();
  }, []);

  // Fetch all tags from the API
  const fetchTags = async () => {
    setLoading(true);
    setErrorMsg(null);
    try {
      const res = await apiFetch(`${baseUrl}/api/tags`);
      
      const contentType = res.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
        setErrorMsg("Backend crashed or returned HTML. Check server logs.");
        setTags([]);
        return;
      }

      const data = await res.json();
      if (res.ok && data) {
        // Handle varying API response structures safely
        const fetchedTags = data.data || data.tags || data || [];
        setTags(Array.isArray(fetchedTags) ? fetchedTags : []);
      } else {
        setErrorMsg(data.message || "Failed to fetch tags");
        setTags([]);
      }
    } catch (err) {
      setErrorMsg(`Network Error: ${err.message}`);
      setTags([]);
    } finally {
      setLoading(false);
    }
  };

  // Filter tags based on the search term dynamically
  const filteredTags = tags.filter(tag => 
    (tag.name && tag.name.toLowerCase().includes(searchTerm.toLowerCase())) || 
    (tag.slug && tag.slug.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  // Auto-generate URL-friendly slug based on the tag name while typing
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    if (name === 'name' && modalType === 'create') {
      const autoSlug = value.toLowerCase()
        .replace(/[^a-z0-9]+/g, '-') // Replace non-alphanumeric with hyphens
        .replace(/(^-|-$)/g, '');    // Remove leading or trailing hyphens
      setFormData({ name: value, slug: autoSlug });
    } else {
      setFormData({ ...formData, [name]: value });
    }
  };

  const openCreateModal = () => {
    setFormData({ name: "", slug: "" });
    setModalType("create");
  };

  const openEditModal = (tag) => {
    setSelectedTag(tag);
    setFormData({
      name: tag.name || "",
      slug: tag.slug || ""
    });
    setModalType("edit");
  };

  const closeModal = () => {
    setModalType(null);
    setSelectedTag(null);
    setFormData({ name: "", slug: "" });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const isEditing = modalType === "edit";
    const url = isEditing 
      ? `${baseUrl}/api/tags/${selectedTag.id}` 
      : `${baseUrl}/api/tags`;
    const method = isEditing ? "PUT" : "POST";

    try {
      const res = await apiFetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });

      if (res.ok) {
        fetchTags(); // Refresh dynamically
        closeModal();
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to save tag"}`);
      }
    } catch (err) {
      console.error(err);
      alert(`Request failed: ${err.message}`);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Are you sure you want to delete this tag?")) return;
    try {
      const res = await apiFetch(`${baseUrl}/api/tags/${id}`, {
        method: "DELETE"
      });
      
      if (res.ok) {
        fetchTags(); // Refresh dynamically
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to delete tag"}`);
      }
    } catch (err) {
      console.error(err);
      alert(`Request failed: ${err.message}`);
    }
  };

  return (
    <div className="p-6 md:p-8 max-w-7xl mx-auto w-full">
      {/* Header */}
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold text-slate-800 dark:text-gray-100">Tags</h1>
        <button 
          onClick={openCreateModal} 
          className="flex items-center gap-2 bg-teal-600 hover:bg-teal-700 text-white px-4 py-2 rounded-lg transition font-medium"
        >
          <Plus size={18} />
          Create Tag
        </button>
      </div>

      {/* Error Message Display */}
      {errorMsg && (
         <div className="p-4 mb-6 bg-red-50 text-red-600 rounded-lg font-medium border border-red-100">
             {errorMsg}
         </div>
      )}

      {/* Search Bar */}
      <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 p-4 mb-6">
        <div className="max-w-md relative">
          <span className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <Search size={18} className="text-slate-400" />
          </span>
          <input 
            type="text" 
            value={searchTerm} 
            onChange={(e) => setSearchTerm(e.target.value)} 
            className="w-full pl-10 pr-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" 
            placeholder="Search tags by name or slug..." 
          />
        </div>
      </div>

      {/* Tags Data Table */}
      <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 dark:bg-gray-800 border-b border-slate-200 dark:border-gray-700">
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Name</th>
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Slug</th>
                <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300 text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr><td colSpan="3" className="p-8 text-center text-slate-500">Loading tags...</td></tr>
              ) : filteredTags.length === 0 ? (
                <tr><td colSpan="3" className="p-8 text-center text-slate-500">No tags found.</td></tr>
              ) : (
                filteredTags.map((tag) => (
                  <tr key={tag.id} className="border-b border-slate-100 dark:border-gray-800 hover:bg-slate-50 dark:hover:bg-gray-800/50 transition">
                    <td className="p-4 text-slate-800 dark:text-gray-200 font-medium">{tag.name}</td>
                    <td className="p-4 text-slate-600 dark:text-gray-400 font-mono text-sm">{tag.slug}</td>
                    <td className="p-4 flex items-center justify-center gap-3">
                      <button 
                        onClick={() => openEditModal(tag)} 
                        className="p-1.5 text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded transition" 
                        title="Edit Tag"
                      >
                        <Edit size={18} />
                      </button>
                      <button 
                        onClick={() => handleDelete(tag.id)} 
                        className="p-1.5 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/30 rounded transition" 
                        title="Delete Tag"
                      >
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

      {/* Create / Edit Modal */}
      {modalType && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white dark:bg-gray-900 rounded-xl shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in duration-200 flex flex-col">
            
            {/* Modal Header */}
            <div className="flex justify-between items-center p-5 border-b border-slate-100 dark:border-gray-800 shrink-0">
              <h2 className="text-lg font-semibold text-slate-800 dark:text-white">
                {modalType === "create" ? "Create Tag" : "Edit Tag"}
              </h2>
              <button onClick={closeModal} className="text-slate-400 hover:text-slate-600 dark:hover:text-gray-300">
                <X size={20} />
              </button>
            </div>
            
            {/* Modal Form */}
            <form onSubmit={handleSubmit} className="p-6 space-y-4 overflow-y-auto">
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Tag Name</label>
                <input 
                  required 
                  type="text" 
                  name="name" 
                  value={formData.name} 
                  onChange={handleInputChange} 
                  className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" 
                  placeholder="e.g. Summer Collection"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Slug (URL friendly)</label>
                <input 
                  required 
                  type="text" 
                  name="slug" 
                  value={formData.slug} 
                  onChange={handleInputChange} 
                  className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" 
                  placeholder="e.g. summer-collection" 
                />
              </div>
              
              <div className="pt-4 flex gap-3 justify-end shrink-0">
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