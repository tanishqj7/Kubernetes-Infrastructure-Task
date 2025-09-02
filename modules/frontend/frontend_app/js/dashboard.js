

async function loadDashboard() {
    try {
        const pods = await apiRequest("api/pods");
        const jobs = await apiRequest("api/jobs");

        const podTable = document.querySelector("#pods-table tbody");
        podTable.innerHTML = "";
        pods.forEach(p => {
            podTable.innerHTML += `<tr><td>${p.name}</td><td>${p.namespace}</td><td>${p.status}</td></tr>`;           
        });

        const jobTable = document.querySelector("#jobs-table tbody"); 
        jobTable.innerHTML = "";
        jobs.forEach(j => {
            jobTable.innerHTML += `<tr><td>${j.name}</td><td>${j.namespace}</td><td>${j.completions}</td><td>${j.status}</td></tr>`;
        });
    } catch (err) {
        console.error("Dashboard load error:", err);
        alert("Failed to load dashboard: " + err.message);
    }
}

document.addEventListener("DOMContentLoaded", loadDashboard);



