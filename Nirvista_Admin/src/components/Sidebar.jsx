import React from "react";
import {
  LayoutDashboard,
  Users,
  MessageCircle,
  HelpCircle,
  Mail,
  ChevronDown,
  ChevronRight,
  ChevronLeft,
  Package,
  Tag,
  FolderTree,
  ShoppingCart,
  Hash
} from "lucide-react";
import { useNavigate, useLocation } from "react-router-dom";
import './Sidebar.css';

const menu = [
  {
    label: "Dashboard",
    icon: <LayoutDashboard size={20} />,
    path: "/",
  },
  { 
    label: "Orders", 
    icon: <ShoppingCart size={20} />, 
    path: "/orders" 
  },
  {
    label: "Vendors",
    icon: <Users size={20} />,
    path: "/vendors",
  },
  {
    label: "Products",
    icon: <Package size={20} />,
    path: "/products",
  },
  {
    label: "Categories",
    icon: <FolderTree size={20} />,
    path: "/categories",
  },
  {
    label: "Brands",
    icon: <Tag size={20} />,
    path: "/brands",
  },
  {
    label: "Tags",
    icon: <Hash size={20} />,
    path: "/tags",
  }
];

const support = [
  { label: "Chat", icon: <MessageCircle size={18} /> },
  { label: "Support", icon: <HelpCircle size={18} /> },
  { label: "Email", icon: <Mail size={18} /> },
];

export default function Sidebar({ sidebarOpen, setSidebarOpen }) {
  return (
    <>
      <div
        className={`fixed inset-0 bg-black bg-opacity-30 z-20 transition-opacity duration-200 lg:hidden ${
          sidebarOpen ? "block" : "hidden"
        }`}
        onClick={() => setSidebarOpen(false)}
        aria-label="Close sidebar overlay"
      />
      <aside
        className={`sidebar fixed inset-y-0 left-0 z-30 w-64 bg-white border-r border-slate-200 flex flex-col transition-transform duration-200
        ${sidebarOpen ? "translate-x-0" : "-translate-x-full"}
        lg:translate-x-0 lg:static lg:flex`}
        style={{ width: 256 }}
      >
        <div className="logo">
          <img
            src="/logo.png"
            alt="Nirvista Logo"
            style={{ height: 36, width: "auto", marginLeft: 8 }}
          />
          <button
            className="close-btn lg:hidden"
            type="button"
            onClick={() => setSidebarOpen(false)}
            aria-label="Close sidebar"
          >
            <ChevronLeft size={20} />
          </button>
        </div>
        <nav>
          <div className="section-title">MENU</div>
          {menu.map((item) => (
            <SidebarItem item={item} key={item.label} setSidebarOpen={setSidebarOpen} />
          ))}
          <div className="section-title">SUPPORT</div>
          {support.map((item) => (
            <SidebarItem item={item} key={item.label} setSidebarOpen={setSidebarOpen} />
          ))}
        </nav>
      </aside>
    </>
  );
}

function SidebarItem({ item, setSidebarOpen }) {
  const [open, setOpen] = React.useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const isActive = location.pathname === item.path;

  const handleClick = () => {
    if (item.children) {
      setOpen((o) => !o);
    } else if (item.path) {
      navigate(item.path);
      if (window.innerWidth < 1024) setSidebarOpen(false);
    }
  };

  return (
    <div>
      <button
        className={`sidebar-item ${isActive ? "active" : ""}`}
        type="button"
        onClick={handleClick}
      >
        {item.icon}
        <span className="sidebar-label-flex">{item.label}</span>
        {item.badge && <span className="badge">{item.badge}</span>}
        {item.children && (
          <span className="chevron">
            {open ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
          </span>
        )}
      </button>
      {item.children && open && (
        <div className="sidebar-submenu">
          {item.children.map((child) => (
            <SidebarItem item={child} key={child.label} setSidebarOpen={setSidebarOpen} />
          ))}
        </div>
      )}
    </div>
  );
}