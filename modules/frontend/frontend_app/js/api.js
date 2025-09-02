const API_BASE = "/";

function getToken() {
    return localStorage.getItem("access_token");
}

function setToken(token) {
    localStorage.setItem("access_token",token);
}

function logout() {
    localStorage.removeItem("access_token");
    window.location.href = "index.html";
}


async function apiRequest(path, method = "GET", body = null) {
    const headers = { "Content-Type": "application/json" };
    const token = getToken();
    if (token) headers["Authorization"] = "Bearer " + token;
    
    const url = API_BASE + path;
    console.log( url); 
    console.log( method); 
    console.log( body); 
    
    const res = await fetch(url, {
        method,
        headers,
        body: body ? JSON.stringify(body) : null
    });

    if (!res.ok) throw new Error(await res.text());
    return res.json();
}