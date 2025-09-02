async function getLogs() {
  const ns = document.getElementById("log-ns").value;
  const pod = document.getElementById("log-pod").value;

  if (!ns || !pod) {
    document.getElementById("log-output").textContent = "Please enter both namespace and pod name";
    return;
  }

//   try {
//     const data = await apiRequest(`api/logs/${ns}/${pod}`);
//     document.getElementById("log-output").textContent = data.logs || "No logs available.";
//   } catch (err) {
//     document.getElementById("log-output").textContent = "Error: " + err.message;
//   }
// }

document.getElementById("log-output").textContent = "Loading logs...";

  try {
    const data = await apiRequest(`api/logs/${ns}/${pod}`);
    document.getElementById("log-output").textContent = data.logs || "No logs available.";
  } catch (err) {
    document.getElementById("log-output").textContent = "Error: " + err.message;
  }
}