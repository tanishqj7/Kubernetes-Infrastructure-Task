// Collect Data
function collectPodData() {
    const ns = document.getElementById("pod-ns").value.trim() || "backend";
    const name = document.getElementById("pod-name").value.trim();
    const image = document.getElementById("pod-image").value.trim();
    const restartPolicy = document.getElementById("pod-restart").value;
    const cmd = document.getElementById("pod-cmd").value.trim();
    const args = document.getElementById("pod-args").value.trim();
    const envText = document.getElementById("pod-env").value.trim();
    const labelsText = document.getElementById("pod-labels").value.trim();

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

    //manifest
    const podSpec = {
        apiVersion: "v1",
        kind: "Pod",
        metadata: {
            name,
            namespace: ns,
            labels: Object.keys(labels).length > 0 ? labels : { "app": name }
        },
        spec: {
            restartPolicy,
            containers: [{
                name: "main",
                image
            }]
        }
    };

    if (cmd) {
        podSpec.spec.containers[0].command = [cmd];
    }

    if (args) {
        podSpec.spec.containers[0].args = args.split(/\s+/);
    }

    if (env.length > 0) {
        podSpec.spec.containers[0].env = env;
    }

    return podSpec;
}

// Preview 
document.getElementById("preview-pod").addEventListener("click", () => {
    const podSpec = collectPodData();
    document.getElementById("pod-json").textContent = JSON.stringify(podSpec, null, 2);
    document.getElementById("pod-status").textContent = "Preview only — not submitted.";
    document.getElementById("pod-status").className = "status";
});

// Submit
document.getElementById("podForm").addEventListener("submit", async (e) => {
    e.preventDefault();
    
    const podSpec = collectPodData();
    
    if (!podSpec.metadata.name || !podSpec.spec.containers[0].image) {
        document.getElementById("pod-status").textContent = "Pod name and image are required";
        document.getElementById("pod-status").className = "status err";
        return;
    }

    try {
        const response = await apiRequest("api/pods", "POST", podSpec);
        document.getElementById("pod-status").textContent = "Pod created successfully!";
        document.getElementById("pod-status").className = "status ok";
        document.getElementById("pod-json").textContent = JSON.stringify(podSpec, null, 2);
        
        document.getElementById("podForm").reset();
        document.getElementById("pod-ns").value = "backend";
        
        loadPods(); 
    } catch (err) {
        console.error("Pod creation error:", err);
        document.getElementById("pod-status").textContent = "Error: " + err.message;
        document.getElementById("pod-status").className = "status err";
    }
});

// Load pods
async function loadPods() {
    try {
        const pods = await apiRequest("api/pods", "GET");
        const container = document.getElementById("pods-list");
        container.innerHTML = "";

        if (!pods || pods.length === 0) {
            container.textContent = "No pods found.";
            return;
        }

        const ul = document.createElement("ul");
        pods.forEach(pod => {
            const li = document.createElement("li");
            li.textContent = `${pod.namespace}/${pod.name} — Status: ${pod.status}`;
            
            const btn = document.createElement("button");
            btn.textContent = "Delete";
            btn.style.marginLeft = "10px";
            btn.onclick = async () => {
                if (confirm(`Delete pod ${pod.name}?`)) {
                    try {
                        await apiRequest(`api/pods/${pod.namespace}/${pod.name}`, "DELETE");
                        loadPods();
                    } catch (err) {
                        alert("Failed to delete pod: " + err.message);
                    }
                }
            };
            li.appendChild(btn);
            ul.appendChild(li);
        });
        container.appendChild(ul);
    } catch (err) {
        console.error("Load pods error:", err);
        document.getElementById("pods-list").textContent = "Failed to load pods: " + err.message;
    }
}

document.addEventListener("DOMContentLoaded", () => {
    loadPods();
});


