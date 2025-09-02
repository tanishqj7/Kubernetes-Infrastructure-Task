function collectJobData() {
    const ns = document.getElementById("job-ns").value.trim() || "backend";
    const name = document.getElementById("job-name").value.trim();
    const image = document.getElementById("job-image").value.trim();
    const completions = parseInt(document.getElementById("job-completions").value) || 1;
    const parallelism = parseInt(document.getElementById("job-parallelism").value) || 1;
    const backoffLimit = parseInt(document.getElementById("job-backoff").value) || 3;
    const cmd = document.getElementById("job-cmd").value.trim();
    const args = document.getElementById("job-args").value.trim();
    const envText = document.getElementById("job-env").value.trim();
    const labelsText = document.getElementById("job-labels").value.trim();

    const env = [];
    if (envText) {
        envText.split('\n').forEach(line => {
            const [name, value] = line.split('=');
            if (name && value) {
                env.push({ name: name.trim(), value: value.trim() });
            }
        });
    }

    const labels = {};
    if (labelsText) {
        labelsText.split('\n').forEach(line => {
            const [key, val] = line.split('=');
            if (key && val) {
                labels[key.trim()] = val.trim();
            }
        });
    }

    const jobSpec = {
        apiVersion: "batch/v1",
        kind: "Job",
        metadata: {
            name,
            namespace: ns,
            labels: Object.keys(labels).length > 0 ? labels : { "app": name }
        },
        spec: {
            completions,
            parallelism,
            backoffLimit,
            template: {
                metadata: {
                    labels: { "job": name }
                },
                spec: {
                    containers: [{
                        name: "main",
                        image
                    }],
                    restartPolicy: "Never"
                }
            }
        }
    };

    if (cmd) {
        jobSpec.spec.template.spec.containers[0].command = [cmd];
    }

    if (args) {
        jobSpec.spec.template.spec.containers[0].args = args.split(/\s+/);
    }

    if (env.length > 0) {
        jobSpec.spec.template.spec.containers[0].env = env;
    }

    return jobSpec;
}

document.getElementById("preview-job").addEventListener("click", () => {
    const jobSpec = collectJobData();
    document.getElementById("job-json").textContent = JSON.stringify(jobSpec, null, 2);
    document.getElementById("job-status").textContent = "Preview only — not submitted.";
    document.getElementById("job-status").className = "status";
});

document.getElementById("jobForm").addEventListener("submit", async (e) => {
    e.preventDefault();
    
    const jobSpec = collectJobData();
    
    if (!jobSpec.metadata.name || !jobSpec.spec.template.spec.containers[0].image) {
        document.getElementById("job-status").textContent = "Job name and image are required";
        document.getElementById("job-status").className = "status err";
        return;
    }

    try {
        const response = await apiRequest("api/jobs", "POST", jobSpec);
        document.getElementById("job-status").textContent = "Job created successfully!";
        document.getElementById("job-status").className = "status ok";
        document.getElementById("job-json").textContent = JSON.stringify(jobSpec, null, 2);
        
        document.getElementById("jobForm").reset();
        document.getElementById("job-ns").value = "backend";
        document.getElementById("job-completions").value = "1";
        document.getElementById("job-parallelism").value = "1";
        document.getElementById("job-backoff").value = "3";
        
        loadJobs(); 
    } catch (err) {
        console.error("Job creation error:", err);
        document.getElementById("job-status").textContent = "Error: " + err.message;
        document.getElementById("job-status").className = "status err";
    }
});

// Load jobs
async function loadJobs() {
    try {
        const jobs = await apiRequest("api/jobs", "GET");
        const container = document.getElementById("jobs-list");
        container.innerHTML = "";

        if (!jobs || jobs.length === 0) {
            container.textContent = "No jobs found.";
            return;
        }

        const ul = document.createElement("ul");
        jobs.forEach(job => {
            const li = document.createElement("li");
            li.textContent = `${job.namespace}/${job.name} — Status: ${job.status} — Completions: ${job.completions}`;
            
            const btn = document.createElement("button");
            btn.textContent = "Delete";
            btn.style.marginLeft = "10px";
            btn.onclick = async () => {
                if (confirm(`Delete job ${job.name}?`)) {
                    try {
                        await apiRequest(`api/jobs/${job.namespace}/${job.name}`, "DELETE");
                        loadJobs();
                    } catch (err) {
                        alert("Failed to delete job: " + err.message);
                    }
                }
            };
            li.appendChild(btn);
            ul.appendChild(li);
        });
        container.appendChild(ul);
    } catch (err) {
        console.error("Load jobs error:", err);
        document.getElementById("jobs-list").textContent = "Failed to load jobs: " + err.message;
    }
}

document.addEventListener("DOMContentLoaded", () => {
    loadJobs();
});








// //  ENV 
// document.getElementById("add-job-env").addEventListener("click", () => {
//   const tbody = document.querySelector("#job-env-table tbody");
//   const row = document.createElement("tr");
//   row.innerHTML = `
//     <td><input placeholder="ENV_NAME"></td>
//     <td><input placeholder="value"></td>
//     <td><button type="button" onclick="this.closest('tr').remove()">X</button></td>`;
//   tbody.appendChild(row);
// });

// //  Label 
// document.getElementById("add-job-label").addEventListener("click", () => {
//   const tbody = document.querySelector("#job-label-table tbody");
//   const row = document.createElement("tr");
//   row.innerHTML = `
//     <td><input placeholder="key"></td>
//     <td><input placeholder="value"></td>
//     <td><button type="button" onclick="this.closest('tr').remove()">X</button></td>`;
//   tbody.appendChild(row);
// });

// // Collect Job Data 
// function collectJobData() {
//   const ns = document.getElementById("job-ns").value.trim() || "default";
//   const name = document.getElementById("job-name").value.trim();
//   const image = document.getElementById("job-image").value.trim();
//   const cmd = document.getElementById("job-cmd").value.trim();
//   const args = document.getElementById("job-args").value.trim();
//   const completions = parseInt(document.getElementById("job-completions").value, 10) || 1;
//   const backoffLimit = parseInt(document.getElementById("job-backoff").value, 10) || 4;

//   // Env vars
//   const env = [];
//   document.querySelectorAll("#job-env-table tbody tr").forEach(row => {
//     const ename = row.querySelector("td:nth-child(1) input").value.trim();
//     const evalv = row.querySelector("td:nth-child(2) input").value.trim();
//     if (ename && evalv) env.push({ name: ename, value: evalv });
//   });

//   // Labels
//   const labels = {};
//   document.querySelectorAll("#job-label-table tbody tr").forEach(row => {
//     const key = row.querySelector("td:nth-child(1) input").value.trim();
//     const val = row.querySelector("td:nth-child(2) input").value.trim();
//     if (key && val) labels[key] = val;
//   });

//   // Build  Job manifest
//   return {
//     apiVersion: "batch/v1",
//     kind: "Job",
//     metadata: {
//       name,
//       namespace: ns,
//       labels
//     },
//     spec: {
//       completions,
//       backoffLimit,
//       template: {
//         metadata: {
//           labels
//         },
//         spec: {
//           restartPolicy: "Never",
//           containers: [
//             {
//               name: "main",
//               image,
//               command: cmd ? [cmd] : undefined,
//               args: args ? args.split(/\s+/) : undefined,
//               env: env.length > 0 ? env : undefined
//             }
//           ]
//         }
//       }
//     }
//   };
// }

// // Preview JSON
// document.getElementById("preview-job").addEventListener("click", () => {
//   const jobSpec = collectJobData();
//   document.getElementById("job-json").textContent = JSON.stringify(jobSpec, null, 2);
//   document.getElementById("job-status").textContent = "Preview only — not submitted.";
//   document.getElementById("job-status").className = "status";
// });

// // Submit Job
// document.getElementById("jobTab").addEventListener("submit", async (e) => {
//   e.preventDefault();
//   const jobSpec = collectJobData();

//   try {
//     await apiRequest("api/jobs", "POST", jobSpec);
//     document.getElementById("job-status").textContent = "✅ Job created successfully!";
//     document.getElementById("job-status").className = "status ok";
//     document.getElementById("job-json").textContent = JSON.stringify(jobSpec, null, 2);
//     loadJobs(); 
//   } catch (err) {
//     document.getElementById("job-status").textContent = "❌ Error: " + err.message;
//     document.getElementById("job-status").className = "status err";
//   }
// });

// // Load Jobs List 
// async function loadJobs() {
//   try {
//     const jobs = await apiRequest("api/jobs", "GET");
//     const container = document.getElementById("jobs-list");
//     container.innerHTML = "";

//     if (!jobs.items || jobs.items.length === 0) {
//       container.textContent = "No jobs found.";
//       return;
//     }

//     const ul = document.createElement("ul");
//     jobs.items.forEach(job => {
//       const li = document.createElement("li");
//       const status = job.status?.succeeded
//         ? `Succeeded: ${job.status.succeeded}`
//         : job.status?.active
//         ? `Active: ${job.status.active}`
//         : "Unknown";
//       li.textContent = `${job.metadata.namespace}/${job.metadata.name} — ${status}`;

//     // Add delete button
//       const btn = document.createElement("button");
//       btn.textContent = "Delete";
//       btn.style.marginLeft = "10px";
//       btn.onclick = async () => {
//         try {
//           await apiRequest(`api/jobs/${job.metadata.namespace}/${job.metadata.name}`, "DELETE");
//           loadJobs();
//         } catch (err) {
//           alert("Failed to delete job: " + err.message);
//         }
//       };

//       li.appendChild(btn);
//       ul.appendChild(li);
//     });
//     container.appendChild(ul);
//   } catch (err) {
//     document.getElementById("jobs-list").textContent = "Failed to load jobs: " + err.message;
//   }
// }




// document.addEventListener("DOMContentLoaded", () => {
//   loadJobs();
// });
