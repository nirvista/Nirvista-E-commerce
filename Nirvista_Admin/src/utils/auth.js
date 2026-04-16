// src/utils/auth.js

export function setToken(token) {
  localStorage.setItem("authToken", token);
}

export function getToken() {
  return localStorage.getItem("authToken");
}

export function removeToken() {
  localStorage.removeItem("authToken");
}

// NEW: Helper function to decode and check if the token is expired
export function isTokenExpired(token) {
  if (!token) return true;
  try {
    // JWTs are split into 3 parts by dots. The payload is the 2nd part.
    const payloadBase64 = token.split('.')[1];
    const decodedJson = atob(payloadBase64); // Decode base64
    const payload = JSON.parse(decodedJson);
    
    // The 'exp' claim is in seconds. Date.now() is in milliseconds.
    const expirationTime = payload.exp * 1000;
    
    // Return true if the current time is past the expiration time
    return Date.now() >= expirationTime;
  } catch (error) {
    // If the token is malformed and cannot be parsed, treat it as expired
    console.error("Invalid token format:", error);
    return true; 
  }
}

// UPDATED: Now checks for both existence AND expiration
export function isAuthenticated() {
  const token = getToken();
  
  if (!token || isTokenExpired(token)) {
    removeToken(); // Clean up invalid/expired token
    return false;
  }
  
  return true;
}