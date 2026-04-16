import React, { useState, useEffect } from "react";
import { Plus, Edit, List, Eye, X, ChevronLeft, Search, FilterX, CheckCircle, Trash2 } from "lucide-react";
import { getToken } from "../utils/auth";
import { apiFetch } from "../utils/api";

export default function Products() {
  const [view, setView] = useState("products"); // 'products' or 'variants'
  const [products, setProducts] = useState([]);
  const [variants, setVariants] = useState([]);
  
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState(null); 
  
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [selectedVariant, setSelectedVariant] = useState(null);
  const [modalType, setModalType] = useState(null); 
  
  const [filterForm, setFilterForm] = useState({ search: "", sort: "", categoryId: "", brandId: "" });
  const [activeFilters, setActiveFilters] = useState({});

  // Aux Data for Dropdowns and Lookups
  const [allCategories, setAllCategories] = useState([]);
  const [allBrands, setAllBrands] = useState([]);
  const [allVendors, setAllVendors] = useState([]);

  const baseUrl = import.meta.env.VITE_BASE_URL || "";
  const defaultProductForm = { title: "", description: "", categoryId: "", brandId: "", vendorId: "", listingStatus: "draft" };
  const defaultVariantForm = { sku: "", variantName: "", price: "", discountPrice: "", stock: 0, status: "in-stock" };
  const [formData, setFormData] = useState({});

  useEffect(() => {
    fetchAuxiliaryData();
  }, []);

  useEffect(() => {
    if (view === "products") {
      fetchProducts();
    } else if (view === "variants" && selectedProduct) {
      fetchVariants(selectedProduct.id);
    }
  }, [view, selectedProduct, activeFilters]);

  // --- API Calls ---

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

  const fetchAuxiliaryData = async () => {
    try {
      const headers = { Authorization: `Bearer ${getToken()}` };
      
      // Fetch Categories
      const catRes = await apiFetch(`${baseUrl}/api/categories`, { headers });
      if (catRes.ok) {
        const catData = await catRes.json();
        const treeData = catData.data || catData;
        setAllCategories(flattenTree(Array.isArray(treeData) ? treeData : []));
      }

      // Fetch Brands
      const brandRes = await apiFetch(`${baseUrl}/api/brands`, { headers });
      if (brandRes.ok) {
        const brandData = await brandRes.json();
        setAllBrands(brandData.data || brandData || []);
      }

      // Fetch Vendors
      const vendorRes = await apiFetch(`${baseUrl}/api/admin/vendors?limit=1000`, { headers });
      if (vendorRes.ok) {
        const vendorData = await vendorRes.json();
        const vData = vendorData.data || vendorData;
        const vList = vData.vendors || (Array.isArray(vData) ? vData : []);
        setAllVendors(vList);
      }
    } catch (err) {
      console.error("Error fetching auxiliary data:", err);
    }
  };

  const fetchProducts = async () => {
    setLoading(true);
    setErrorMsg(null); 
    try {
      const queryParams = new URLSearchParams();
      if (activeFilters.search) queryParams.append('search', activeFilters.search);
      if (activeFilters.sort) queryParams.append('sort', activeFilters.sort);
      if (activeFilters.categoryId) queryParams.append('categoryId', activeFilters.categoryId);
      if (activeFilters.brandId) queryParams.append('brandId', activeFilters.brandId);

      const queryString = queryParams.toString() ? `?${queryParams.toString()}` : '';

      const res = await apiFetch(`${baseUrl}/api/products/admin/all${queryString}`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });

      const contentType = res.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
        const text = await res.text();
        console.error("Received HTML instead of JSON:", text);
        setErrorMsg("Backend crashed and returned an HTML page. Check your Node.js terminal logs.");
        setProducts([]);
        setLoading(false);
        return;
      }

      const data = await res.json();
      
      if (res.ok && data) {
        if (Array.isArray(data.data)) {
          setProducts(data.data);
        } else if (data.data && Array.isArray(data.data.products)) {
          setProducts(data.data.products);
        } else if (Array.isArray(data.products)) {
          setProducts(data.products);
        } else if (Array.isArray(data)) {
          setProducts(data);
        } else {
          setProducts([]);
        }
      } else {
        console.error("API Error fetching products:", data);
        setErrorMsg(`API Error: ${data?.message || "Check your route/server"}`);
        setProducts([]);
      }
    } catch (err) {
      console.error("Network Error fetching products:", err);
      setErrorMsg(`Network Error: ${err.message}`);
      setProducts([]);
    } finally {
      setLoading(false);
    }
  };

  const fetchVariants = async (productId) => {
    setLoading(true);
    setErrorMsg(null);
    try {
      const res = await apiFetch(`${baseUrl}/api/products/${productId}/variants`, {
        headers: { Authorization: `Bearer ${getToken()}` },
      });

      const contentType = res.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
        setErrorMsg("Backend crashed and returned an HTML page. Check your Node.js terminal logs.");
        setVariants([]);
        setLoading(false);
        return;
      }

      const data = await res.json();
      
      if (res.ok && data) {
        if (Array.isArray(data.data)) {
          setVariants(data.data);
        } else if (Array.isArray(data)) {
          setVariants(data);
        } else {
          setVariants([]);
        }
      } else {
        setErrorMsg(`API Error: ${data?.message || "Check your route/server"}`);
        setVariants([]);
      }
    } catch (err) {
      setErrorMsg(`Network Error: ${err.message}`);
      setVariants([]);
    } finally {
      setLoading(false);
    }
  };

  // --- Actions & Handlers ---

  const handleProductStatusChange = async (productId, newStatus) => {
    try {
      const res = await apiFetch(`${baseUrl}/api/products/${productId}`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify({ listingStatus: newStatus }),
      });

      if (res.ok) {
        fetchProducts(); 
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to update product status"}`);
      }
    } catch (err) {
      console.error("Status update error:", err);
    }
  };

  const handleApproveVariant = async (variantId, approve) => {
    try {
      const res = await apiFetch(`${baseUrl}/api/products/${selectedProduct.id}/variants/${variantId}/approve`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify({ approve }),
      });
      if (res.ok) {
        fetchVariants(selectedProduct.id);
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to update approval status"}`);
      }
    } catch (err) {
      console.error("Approval error:", err);
    }
  };

  const handleApproveAll = async () => {
    try {
      const res = await apiFetch(`${baseUrl}/api/products/${selectedProduct.id}/variants/approve-all`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify({ approve: true }),
      });
      if (res.ok) {
        fetchVariants(selectedProduct.id);
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to approve all variants"}`);
      }
    } catch (err) {
      console.error("Approve all error:", err);
    }
  };

  const handleDeleteProduct = async (productId) => {
    if (!window.confirm("Are you sure you want to delete this product? All its variants will also be deleted automatically.")) return;
    try {
      const res = await apiFetch(`${baseUrl}/api/products/${productId}`, {
        method: "DELETE",
        headers: { Authorization: `Bearer ${getToken()}` },
      });

      if (res.ok) {
        fetchProducts();
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to delete product"}`);
      }
    } catch (err) {
      console.error("Delete product error:", err);
    }
  };

  const handleDeleteVariant = async (variantId) => {
    if (!window.confirm("Are you sure you want to delete this variant?")) return;
    try {
      const res = await apiFetch(`${baseUrl}/api/products/${selectedProduct.id}/variants/${variantId}`, {
        method: "DELETE",
        headers: { Authorization: `Bearer ${getToken()}` },
      });

      if (res.ok) {
        fetchVariants(selectedProduct.id);
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to delete variant"}`);
      }
    } catch (err) {
      console.error("Delete variant error:", err);
    }
  };

  // --- Lookup Helpers ---

  const getCategoryName = (id) => {
    const cat = allCategories.find(c => c.id === id);
    return cat ? cat.name : (id ? id.substring(0,8) + '...' : 'N/A');
  };

  const getBrandName = (id) => {
    const brand = allBrands.find(b => b.id === id);
    return brand ? brand.name : (id ? id.substring(0,8) + '...' : 'N/A');
  };

  // --- Modals & Forms ---

  const handleFilterChange = (e) => {
    setFilterForm({ ...filterForm, [e.target.name]: e.target.value });
  };

  const applyFilters = () => {
    setActiveFilters({ ...filterForm });
  };

  const clearFilters = () => {
    setFilterForm({ search: "", sort: "", categoryId: "", brandId: "" });
    setActiveFilters({});
  };

  const handleInputChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const closeModal = () => {
    setModalType(null);
  };

  const openCreateProductModal = () => {
    setFormData(defaultProductForm);
    setModalType("createProduct");
  };

  const openAddVariantModal = () => {
    setFormData(defaultVariantForm);
    setModalType("addVariant");
  };

  const openEditVariantModal = (variant) => {
    setSelectedVariant(variant);
    setFormData({
      sku: variant.sku || "",
      variantName: variant.variantName || "",
      price: variant.price || "",
      discountPrice: variant.discountPrice || "",
      stock: variant.stock || 0,
      status: variant.status || "in-stock"
    });
    setModalType("editVariant");
  };

  const openVariantDetails = (variant) => {
    setSelectedVariant(variant);
    setModalType("variantDetails");
  };

  const handleProductSubmit = async (e) => {
    e.preventDefault();
    try {
      const res = await apiFetch(`${baseUrl}/api/products`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${getToken()}`,
        },
        body: JSON.stringify(formData),
      });

      if (res.ok) {
        fetchProducts();
        closeModal();
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to create product"}`);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const handleVariantSubmit = async (e) => {
    e.preventDefault();
    const isEditing = modalType === "editVariant";
    const url = isEditing
      ? `${baseUrl}/api/products/${selectedProduct.id}/variants/${selectedVariant.id}`
      : `${baseUrl}/api/products/${selectedProduct.id}/variants`;
    const method = isEditing ? "PUT" : "POST";

    // Clean payload: empty strings should be sent as null to the backend for optional decimal fields
    const payload = { ...formData };
    if (payload.discountPrice === "") payload.discountPrice = null;

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
        fetchVariants(selectedProduct.id);
        closeModal();
      } else {
        const errData = await res.json();
        alert(`Error: ${errData.message || "Failed to save variant"}`);
      }
    } catch (err) {
      console.error(err);
    }
  };

  // --- Renderers ---

  return (
    <div className="p-6 md:p-8 max-w-7xl mx-auto w-full">
      
      {/* Header Area */}
      <div className="flex justify-between items-center mb-6">
        {view === "products" ? (
          <>
            <h1 className="text-2xl font-bold text-slate-800 dark:text-gray-100">Products</h1>
            <button
              onClick={openCreateProductModal}
              className="flex items-center gap-2 bg-teal-600 hover:bg-teal-700 text-white px-4 py-2 rounded-lg transition font-medium"
            >
              <Plus size={18} />
              Create Product
            </button>
          </>
        ) : (
          <>
            <div className="flex items-center gap-4">
              <button
                onClick={() => setView("products")}
                className="p-2 bg-slate-100 hover:bg-slate-200 dark:bg-gray-800 dark:hover:bg-gray-700 rounded-lg transition text-slate-600 dark:text-gray-300"
              >
                <ChevronLeft size={20} />
              </button>
              <h1 className="text-2xl font-bold text-slate-800 dark:text-gray-100">
                Variants for <span className="text-teal-600 dark:text-teal-400">{selectedProduct?.title}</span>
              </h1>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={handleApproveAll}
                className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg transition font-medium"
              >
                <CheckCircle size={18} />
                Approve All
              </button>
              <button
                onClick={openAddVariantModal}
                className="flex items-center gap-2 bg-teal-600 hover:bg-teal-700 text-white px-4 py-2 rounded-lg transition font-medium"
              >
                <Plus size={18} />
                Add Variant
              </button>
            </div>
          </>
        )}
      </div>

      {/* Filter Area - Only visible in products view */}
      {view === "products" && (
        <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 p-4 mb-6 flex flex-wrap items-end gap-4">
          <div className="flex-1 min-w-[200px]">
            <label className="block text-xs font-semibold text-slate-500 dark:text-gray-400 mb-1 uppercase tracking-wider">Search</label>
            <div className="relative">
              <span className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <Search size={16} className="text-slate-400" />
              </span>
              <input 
                type="text" 
                name="search" 
                value={filterForm.search} 
                onChange={handleFilterChange} 
                className="w-full pl-10 pr-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm" 
                placeholder="Search products..." 
              />
            </div>
          </div>
          
          <div className="w-full md:w-40">
            <label className="block text-xs font-semibold text-slate-500 dark:text-gray-400 mb-1 uppercase tracking-wider">Sort By</label>
            <select 
              name="sort" 
              value={filterForm.sort} 
              onChange={handleFilterChange} 
              className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm"
            >
              <option value="">Newest</option>
              <option value="price_asc">Price: Low to High</option>
              <option value="price_desc">Price: High to Low</option>
              <option value="rating_desc">Highest Rated</option>
              <option value="discount_desc">Biggest Discount</option>
            </select>
          </div>

          <div className="w-full md:w-48">
            <label className="block text-xs font-semibold text-slate-500 dark:text-gray-400 mb-1 uppercase tracking-wider">Category</label>
            <select 
              name="categoryId" 
              value={filterForm.categoryId} 
              onChange={handleFilterChange} 
              className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm"
            >
              <option value="">All Categories</option>
              {allCategories.map(c => (
                <option key={c.id} value={c.id}>{c.level > 0 ? "—".repeat(c.level) + " " : ""}{c.name}</option>
              ))}
            </select>
          </div>

          <div className="w-full md:w-48">
            <label className="block text-xs font-semibold text-slate-500 dark:text-gray-400 mb-1 uppercase tracking-wider">Brand</label>
            <select 
              name="brandId" 
              value={filterForm.brandId} 
              onChange={handleFilterChange} 
              className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white text-sm"
            >
              <option value="">All Brands</option>
              {allBrands.map(b => (
                <option key={b.id} value={b.id}>{b.name}</option>
              ))}
            </select>
          </div>

          <div className="flex gap-2 w-full md:w-auto">
            <button 
              onClick={applyFilters} 
              className="flex-1 md:flex-none px-4 py-2 bg-teal-50 text-teal-700 hover:bg-teal-100 dark:bg-teal-900/30 dark:text-teal-400 dark:hover:bg-teal-900/50 rounded-lg transition font-medium text-sm"
            >
              Apply
            </button>
            <button 
              onClick={clearFilters} 
              className="px-3 py-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-gray-800 rounded-lg transition"
              title="Clear Filters"
            >
              <FilterX size={18} />
            </button>
          </div>
        </div>
      )}

      {/* Tables Container */}
      <div className="bg-white dark:bg-gray-900 rounded-xl shadow-sm border border-slate-100 dark:border-gray-800 overflow-hidden">
        <div className="overflow-x-auto">
          
          {/* Products Table */}
          {view === "products" && (
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 dark:bg-gray-800 border-b border-slate-200 dark:border-gray-700">
                  <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Title</th>
                  <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Category / Brand</th>
                  <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Vendor</th>
                  <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Listing Status</th>
                  <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300 text-center">Actions</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan="5" className="p-8 text-center text-slate-500">Loading products...</td>
                  </tr>
                ) : errorMsg ? (
                  <tr>
                    <td colSpan="5" className="p-8 text-center text-red-500 font-medium bg-red-50 dark:bg-red-900/20">{errorMsg}</td>
                  </tr>
                ) : products.length === 0 ? (
                  <tr>
                    <td colSpan="5" className="p-8 text-center text-slate-500">No products found.</td>
                  </tr>
                ) : (
                  products.map((product) => (
                    <tr key={product.id} className="border-b border-slate-100 dark:border-gray-800 hover:bg-slate-50 dark:hover:bg-gray-800/50 transition">
                      <td className="p-4">
                        <p className="font-medium text-slate-800 dark:text-gray-200">{product.title}</p>
                        <p className="text-xs text-slate-500 dark:text-gray-400 truncate max-w-xs">{product.description}</p>
                      </td>
                      <td className="p-4 text-slate-600 dark:text-gray-400 text-sm">
                        <span className="block font-medium text-slate-700 dark:text-gray-300">{getCategoryName(product.categoryId)}</span>
                        <span className="block text-xs mt-0.5">{getBrandName(product.brandId)}</span>
                      </td>
                      <td className="p-4 text-slate-600 dark:text-gray-400">
                        {product.vendor?.name || (product.vendorId ? product.vendorId.substring(0,8) + '...' : "No Vendor")}
                      </td>
                      <td className="p-4">
                        <select
                          value={product.listingStatus}
                          onChange={(e) => handleProductStatusChange(product.id, e.target.value)}
                          className={`px-2 py-1.5 text-xs rounded-full font-semibold outline-none cursor-pointer border border-transparent hover:border-slate-300 dark:hover:border-gray-600 appearance-none text-center ${
                            product.listingStatus === 'active' ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400' :
                            product.listingStatus === 'archived' ? 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400' : 
                            'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400'
                          }`}
                        >
                          <option value="draft" className="bg-white text-slate-800 dark:bg-gray-800 dark:text-gray-100">Draft</option>
                          <option value="active" className="bg-white text-slate-800 dark:bg-gray-800 dark:text-gray-100">Active</option>
                          <option value="archived" className="bg-white text-slate-800 dark:bg-gray-800 dark:text-gray-100">Archived</option>
                        </select>
                      </td>
                      <td className="p-4 flex items-center justify-center gap-2">
                        <button
                          onClick={() => {
                            setSelectedProduct(product);
                            setView("variants");
                          }}
                          className="flex items-center gap-1.5 px-3 py-1.5 text-sm bg-indigo-50 hover:bg-indigo-100 text-indigo-600 dark:bg-indigo-900/30 dark:hover:bg-indigo-900/50 dark:text-indigo-400 rounded-lg transition"
                        >
                          <List size={16} /> Show Variants
                        </button>
                        <button
                          onClick={() => handleDeleteProduct(product.id)}
                          className="p-1.5 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/30 rounded transition"
                          title="Delete Product"
                        >
                          <Trash2 size={18} />
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          )}

          {/* Variants Table */}
          {view === "variants" && (
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 dark:bg-gray-800 border-b border-slate-200 dark:border-gray-700">
                  <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Variant Name</th>
                  <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">SKU</th>
                  <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Pricing</th>
                  <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Stock</th>
                  <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300">Status</th>
                  <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300 text-center">Approval Actions</th>
                  <th className="p-4 text-sm font-semibold text-slate-600 dark:text-gray-300 text-center">Manage</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan="7" className="p-8 text-center text-slate-500">Loading variants...</td>
                  </tr>
                ) : errorMsg ? (
                  <tr>
                    <td colSpan="7" className="p-8 text-center text-red-500 font-medium bg-red-50 dark:bg-red-900/20">{errorMsg}</td>
                  </tr>
                ) : variants.length === 0 ? (
                  <tr>
                    <td colSpan="7" className="p-8 text-center text-slate-500">No variants found for this product.</td>
                  </tr>
                ) : (
                  variants.map((variant) => (
                    <tr key={variant.id} className="border-b border-slate-100 dark:border-gray-800 hover:bg-slate-50 dark:hover:bg-gray-800/50 transition">
                      <td className="p-4 text-slate-800 dark:text-gray-200 font-medium">{variant.variantName || "N/A"}</td>
                      <td className="p-4 text-slate-600 dark:text-gray-400 font-mono text-sm">{variant.sku}</td>
                      <td className="p-4 text-slate-600 dark:text-gray-400">
                        <span className="block">${Number(variant.price).toFixed(2)}</span>
                        {variant.discountPrice && (
                          <span className="block text-xs text-green-600 dark:text-green-400 font-medium">Sale: ${Number(variant.discountPrice).toFixed(2)}</span>
                        )}
                      </td>
                      <td className="p-4 text-slate-600 dark:text-gray-400">{variant.stock}</td>
                      <td className="p-4">
                        <div className="flex flex-col gap-1.5 items-start">
                          <span className={`px-2 py-0.5 text-[10px] uppercase tracking-wider rounded font-medium ${
                            variant.status === 'in-stock' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                          }`}>
                            {variant.status}
                          </span>
                          <span className={`px-2 py-0.5 text-[10px] uppercase tracking-wider rounded font-medium ${
                            variant.approvalStatus === 'approved' ? 'bg-blue-100 text-blue-700' : 'bg-orange-100 text-orange-700'
                          }`}>
                            {variant.approvalStatus}
                          </span>
                        </div>
                      </td>
                      <td className="p-4">
                         <div className="flex justify-center gap-2">
                           {variant.approvalStatus !== 'approved' && (
                             <button
                               onClick={() => handleApproveVariant(variant.id, true)}
                               className="px-2.5 py-1 text-xs font-semibold bg-green-50 text-green-700 hover:bg-green-100 dark:bg-green-900/30 dark:text-green-400 border border-green-200 dark:border-green-800 rounded transition"
                             >
                               Approve
                             </button>
                           )}
                           {variant.approvalStatus !== 'rejected' && (
                             <button
                               onClick={() => handleApproveVariant(variant.id, false)}
                               className="px-2.5 py-1 text-xs font-semibold bg-red-50 text-red-700 hover:bg-red-100 dark:bg-red-900/30 dark:text-red-400 border border-red-200 dark:border-red-800 rounded transition"
                             >
                               Reject
                             </button>
                           )}
                         </div>
                      </td>
                      <td className="p-4 flex items-center justify-center gap-2">
                        <button
                          onClick={() => openVariantDetails(variant)}
                          className="p-1.5 text-teal-600 hover:bg-teal-50 dark:hover:bg-teal-900/30 rounded transition"
                          title="Show Details"
                        >
                          <Eye size={18} />
                        </button>
                        <button
                          onClick={() => openEditVariantModal(variant)}
                          className="p-1.5 text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/30 rounded transition"
                          title="Edit Variant"
                        >
                          <Edit size={18} />
                        </button>
                        <button
                          onClick={() => handleDeleteVariant(variant.id)}
                          className="p-1.5 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/30 rounded transition"
                          title="Delete Variant"
                        >
                          <Trash2 size={18} />
                        </button>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* --- Modals --- */}
      {modalType && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white dark:bg-gray-900 rounded-xl shadow-xl w-full max-w-lg overflow-hidden animate-in fade-in zoom-in duration-200 flex flex-col max-h-[90vh]">
            
            <div className="flex justify-between items-center p-5 border-b border-slate-100 dark:border-gray-800 shrink-0">
              <h2 className="text-lg font-semibold text-slate-800 dark:text-white">
                {modalType === "createProduct" ? "Create Product" : 
                 modalType === "addVariant" ? "Add Variant" : 
                 modalType === "editVariant" ? "Edit Variant" : 
                 "Variant Details"}
              </h2>
              <button onClick={closeModal} className="text-slate-400 hover:text-slate-600 dark:hover:text-gray-300">
                <X size={20} />
              </button>
            </div>

            {/* Create Product Form */}
            {modalType === "createProduct" && (
              <form onSubmit={handleProductSubmit} className="p-6 space-y-4 overflow-y-auto">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Title</label>
                  <input required type="text" name="title" value={formData.title} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Description</label>
                  <textarea name="description" value={formData.description} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" rows="3" />
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  {/* Category Selection */}
                  <div>
                    <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Category</label>
                    <select required name="categoryId" value={formData.categoryId} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white">
                      <option value="" disabled>Select Category</option>
                      {allCategories.map(c => (
                        <option key={c.id} value={c.id}>
                          {c.level > 0 ? "—".repeat(c.level) + " " : ""}{c.name}
                        </option>
                      ))}
                    </select>
                  </div>
                  
                  {/* Brand Selection */}
                  <div>
                    <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Brand</label>
                    <select required name="brandId" value={formData.brandId} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white">
                      <option value="" disabled>Select Brand</option>
                      {allBrands.map(b => (
                        <option key={b.id} value={b.id}>{b.name}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  {/* Vendor Selection */}
                  <div>
                    <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Vendor</label>
                    <select required name="vendorId" value={formData.vendorId} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white">
                      <option value="" disabled>Select Vendor</option>
                      {allVendors.map(v => (
                        <option key={v.id} value={v.id}>{v.name} ({v.email})</option>
                      ))}
                    </select>
                  </div>

                  {/* Listing Status */}
                  <div>
                    <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Listing Status</label>
                    <select name="listingStatus" value={formData.listingStatus} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white">
                      <option value="draft">Draft</option>
                      <option value="active">Active</option>
                      <option value="archived">Archived</option>
                    </select>
                  </div>
                </div>

                <div className="pt-4 flex gap-3 justify-end">
                  <button type="button" onClick={closeModal} className="px-4 py-2 text-slate-600 dark:text-gray-300 hover:bg-slate-100 dark:hover:bg-gray-800 rounded-lg transition">Cancel</button>
                  <button type="submit" className="px-4 py-2 bg-teal-600 hover:bg-teal-700 text-white rounded-lg transition font-medium">Create Product</button>
                </div>
              </form>
            )}

            {/* Add / Edit Variant Form */}
            {(modalType === "addVariant" || modalType === "editVariant") && (
              <form onSubmit={handleVariantSubmit} className="p-6 space-y-4 overflow-y-auto">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">SKU</label>
                    <input required type="text" name="sku" value={formData.sku} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Variant Name</label>
                    <input type="text" name="variantName" value={formData.variantName} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" placeholder="e.g., Red / XL" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Price</label>
                    <input required type="number" step="0.01" name="price" value={formData.price} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Discount Price</label>
                    <input type="number" step="0.01" name="discountPrice" value={formData.discountPrice} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" placeholder="Optional" />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Stock Quantity</label>
                    <input required type="number" name="stock" value={formData.stock} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 dark:text-gray-300 mb-1">Status</label>
                    <select name="status" value={formData.status} onChange={handleInputChange} className="w-full px-3 py-2 border border-slate-300 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-teal-500 dark:bg-gray-800 dark:text-white">
                      <option value="in-stock">In Stock</option>
                      <option value="out-of-stock">Out of Stock</option>
                      <option value="discontinued">Discontinued</option>
                    </select>
                  </div>
                </div>
                <div className="pt-4 flex gap-3 justify-end">
                  <button type="button" onClick={closeModal} className="px-4 py-2 text-slate-600 dark:text-gray-300 hover:bg-slate-100 dark:hover:bg-gray-800 rounded-lg transition">Cancel</button>
                  <button type="submit" className="px-4 py-2 bg-teal-600 hover:bg-teal-700 text-white rounded-lg transition font-medium">
                    {modalType === "addVariant" ? "Add Variant" : "Save Changes"}
                  </button>
                </div>
              </form>
            )}

            {/* Variant Details View */}
            {modalType === "variantDetails" && selectedVariant && (
              <div className="p-6 space-y-4 text-slate-700 dark:text-gray-300 overflow-y-auto">
                <div className="grid grid-cols-2 gap-y-4 gap-x-6">
                  <DetailItem label="Variant ID" value={selectedVariant.id} />
                  <DetailItem label="SKU" value={selectedVariant.sku} />
                  <DetailItem label="Variant Name" value={selectedVariant.variantName} />
                  <DetailItem label="Price" value={`$${Number(selectedVariant.price).toFixed(2)}`} />
                  <DetailItem label="Discount Price" value={selectedVariant.discountPrice ? `$${Number(selectedVariant.discountPrice).toFixed(2)}` : "None"} />
                  <DetailItem label="Color" value={selectedVariant.color} />
                  <DetailItem label="Size" value={selectedVariant.size} />
                  <DetailItem label="Status" value={selectedVariant.status} />
                  <DetailItem label="Total Stock" value={selectedVariant.stock} />
                  <DetailItem label="Reserved Stock" value={selectedVariant.reservedStock} />
                  <DetailItem label="Available Stock" value={selectedVariant.availableStock} />
                  <DetailItem label="Low Stock Threshold" value={selectedVariant.lowStockThreshold} />
                  <DetailItem label="Approval Status" value={selectedVariant.approvalStatus} />
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

function DetailItem({ label, value }) {
  return (
    <div>
      <span className="block text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1">{label}</span>
      <p className="font-medium text-slate-900 dark:text-white break-words">{value || "N/A"}</p>
    </div>
  );
}