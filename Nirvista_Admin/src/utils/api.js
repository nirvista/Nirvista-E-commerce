// src/utils/api.js
import { getToken, removeToken } from "./auth";

/**
 * A custom wrapper around the native fetch API.
 * Automatically attaches the token and handles 401 Expiration redirects.
 */
export const apiFetch = async (url, options = {}) => {
  const token = getToken();
  
  // Automatically inject the Authorization header if a token exists
  const headers = {
    ...options.headers,
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };

  const response = await fetch(url, { ...options, headers });

  // Automatically detect token expiration from the backend
  if (response.status === 401) {
    console.warn("Session expired. Redirecting to login...");
    removeToken(); // Clear the expired token
    window.location.href = "/login"; // Force redirect to login page
    
    return new Promise(() => {}); 
  }

  return response;
};