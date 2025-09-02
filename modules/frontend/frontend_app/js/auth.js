
// LOGIN
async function login(event) {
  event.preventDefault();
  const username = document.getElementById("login-username").value;
  const password = document.getElementById("login-password").value;

  try {
    const data = await apiRequest("auth/login", "POST", { username, password });

    if (data.access_token) {
      localStorage.setItem("access_token", data.access_token);
      window.location.href = "dashboard.html"; 
    } else {
      document.getElementById("login-status").textContent = "Login failed: No token received";
    }
  } catch (err) {
    document.getElementById("login-status").textContent = "Login failed: " + err.message;
  }
}

// REGISTER
async function register(event) {
  event.preventDefault();
  const username = document.getElementById("reg-username").value;
  const password = document.getElementById("reg-password").value;
  const role = document.getElementById("reg-role").value;
  const namespace = document.getElementById("reg-namespace").value;

  try {
    await apiRequest("auth/register", "POST", { username, password, role, namespace });
    document.getElementById("register-status").textContent =
      "Registered successfully. Please login.";
  } catch (err) {
    document.getElementById("register-status").textContent =
      "Register failed: " + err.message;
  }
}
