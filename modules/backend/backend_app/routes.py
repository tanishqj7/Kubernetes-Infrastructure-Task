from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from functools import wraps
from models import User, Role, Permission, RolePermission
from db import db

from kubernetes import client, config

try:
    config.load_incluster_config()
except:
    config.load_kube_config()

core_v1 = client.CoreV1Api()
batch_v1 = client.BatchV1Api()

routes_bp = Blueprint("routes", __name__)

def permission_required(permission_name):
    def wrapper(fn):
        @wraps(fn)
        @jwt_required()
        def decorated(*args, **kwargs):
            user = User.query.filter_by(username=get_jwt_identity()).first()
            if not user:
                return jsonify({"msg": "Unauthorized"}), 401

            has_perm = (
                db.session.query(Permission)
                .join(RolePermission, Permission.id == RolePermission.permission_id)
                .filter(RolePermission.role_id == user.role_id, Permission.name == permission_name)
                .first()
            )

            if not has_perm:
                return jsonify({"msg": f"Missing permission: {permission_name}"}), 403

            return fn(user, *args, **kwargs)
        return decorated
    return wrapper

# Pods
@routes_bp.route("/pods", methods=["GET"])
@permission_required("view_pod")
def list_pods(user):
    try:
        # role_id 1 = Admin, 2 = NamespaceManager, 3 = Viewer
        if user.role_id == 1:
            pods = core_v1.list_pod_for_all_namespaces()
        
        elif user.role_id == 3:
            pods = core_v1.list_pod_for_all_namespaces()
        
        else:
            namespace = user.namespace or "default"
            pods = core_v1.list_namespaced_pod(namespace=namespace)
        
        result = []
        for pod in pods.items:
            result.append({
                "name": pod.metadata.name,
                "namespace": pod.metadata.namespace,
                "status": pod.status.phase if pod.status else "Unknown"
            })
        
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@routes_bp.route("/pods", methods=["POST"])
@permission_required("crud_pod")
def create_pod(user):
    try:
        pod_data = request.get_json()
        target_ns = pod_data.get("metadata", {}).get("namespace", "default")

        if user.role_id == 2 and target_ns != user.namespace:
            return jsonify({"msg": "Can only create pods in your namespace"}), 403
        
        response = core_v1.create_namespaced_pod(namespace=target_ns, body=pod_data)
        return jsonify({"msg": "Pod created", "name": response.metadata.name})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@routes_bp.route("/pods/<namespace>/<name>", methods=["DELETE"])
@permission_required("crud_pod")
def delete_pod(user, namespace, name):
    try:
        if user.role_id == 2 and namespace != user.namespace:
            return jsonify({"msg": "Can only delete pods in your namespace"}), 403
        
        core_v1.delete_namespaced_pod(name=name, namespace=namespace)
        return jsonify({"msg": "Pod deleted"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@routes_bp.route("/jobs", methods=["GET"])
@permission_required("view_job")
def list_jobs(user):
    try:
        if user.role_id == 1 or user.role_id == 3:
            jobs = batch_v1.list_job_for_all_namespaces()
        else:
            namespace = user.namespace or "default"
            jobs = batch_v1.list_namespaced_job(namespace=namespace)
        
        result = []
        for job in jobs.items:
            succeeded = job.status.succeeded or 0
            total = job.spec.completions or 1
            
            if job.status.succeeded:
                status = "Complete"
            elif job.status.active:
                status = "Running"  
            else:
                status = "Failed"
            
            result.append({
                "name": job.metadata.name,
                "namespace": job.metadata.namespace,
                "completions": f"{succeeded}/{total}",
                "status": status
            })
        
        return jsonify(result)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@routes_bp.route("/jobs", methods=["POST"])
@permission_required("crud_job")
def create_job(user):
    try:
        job_data = request.get_json()
        target_ns = job_data.get("metadata", {}).get("namespace", "default")
        
        if user.role_id == 2 and target_ns != user.namespace:
            return jsonify({"msg": "Can only create jobs in your namespace"}), 403
        
        response = batch_v1.create_namespaced_job(namespace=target_ns, body=job_data)
        return jsonify({"msg": "Job created", "name": response.metadata.name})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@routes_bp.route("/jobs/<namespace>/<name>", methods=["DELETE"])
@permission_required("crud_job")
def delete_job(user, namespace, name):
    try:
        if user.role_id == 2 and namespace != user.namespace:
            return jsonify({"msg": "Can only delete jobs in your namespace"}), 403
        
        batch_v1.delete_namespaced_job(name=name, namespace=namespace)
        return jsonify({"msg": "Job deleted"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500




@routes_bp.route("/logs/<namespace>/<pod_name>", methods=["GET"])
@permission_required("view_pod")
def get_pod_logs(user, namespace, pod_name):
    try:
        if user.role_id == 2 and namespace != user.namespace:
            return jsonify({"msg": "Can only view logs in your namespace"}), 403
        
        

        logs = core_v1.read_namespaced_pod_log(
            name=pod_name, 
            namespace=namespace,
            tail_lines=100
        )
        
        return jsonify({
            "logs": logs,
            "pod": pod_name,
            "namespace": namespace,
        })
        
    except client.exceptions.ApiException as e:
        if e.status == 404:
            return jsonify({"error": "Pod not found"}), 404
        else:
            return jsonify({"error": str(e)}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# from flask import Blueprint, jsonify, request
# from flask_jwt_extended import jwt_required, get_jwt_identity
# from functools import wraps
# from models import User, Role, Permission, RolePermission
# from db import db

# from kubernetes import client, config


# try:
#     config.load_incluster_config()
# except:
#     config.load_kube_config()




# core_v1 = client.CoreV1Api()
# batch_v1 = client.BatchV1Api()

# routes_bp = Blueprint("routes", __name__)

# def permission_required(permission_name):
#     def wrapper(fn):
#         @wraps(fn)
#         @jwt_required()
#         def decorated(*args, **kwargs):
#             user = User.query.filter_by(username=get_jwt_identity()).first()
#             if not user:
#                 return jsonify({"msg": "Unauthorized"}), 401

#             has_perm = (
#                 db.session.query(Permission)
#                 .join(RolePermission, Permission.id == RolePermission.permission_id)
#                 .filter(RolePermission.role_id == user.role_id, Permission.name == permission_name)
#                 .first()
#             )

#             if not has_perm:
#                 return jsonify({"msg": f"Missing permission: {permission_name}"}), 403

#             return fn(user, *args, **kwargs)
#         return decorated
#     return wrapper

# # Pods
# @routes_bp.route("/pods", methods=["GET"])
# @permission_required("view_pod")
# def list_pods(user):
#     ns = user.namespace if user.namespace else request.args.get("namespace", "default")
#     pods = core_v1.list_namespaced_pod(namespace=ns)
#     pod_list = []
#     for pod in pods.items:
#         pod_list.append({
#             "name": pod.metadata.name,
#             "namespace": pod.metadata.namespace,
#             "status": pod.status.phase if pod.status else "Unknown"
#         })
#     return jsonify(pod_list)
#     # return jsonify([p.metadata.name for p in pods.items])

# @routes_bp.route("/pods", methods=["POST"])
# @permission_required("crud_pod")
# def create_pod(user):
#     ns = user.namespace if user.namespace else request.args.get("namespace", "default")
#     pod_spec = request.get_json()
#     resp = core_v1.create_namespaced_pod(namespace=ns, body=pod_spec)
#     return jsonify({"msg": "Pod created", "name": resp.metadata.name})
    

# @routes_bp.route("/pods/<namespace>/<name>", methods=["DELETE"])
# @permission_required("crud_pod")
# def delete_pod(user, namespace, name):
#     try:
#         core_v1.delete_namespaced_pod(name=name, namespace=namespace)
#         return jsonify({"msg": "Pod deleted successfully"})
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# # Jobs
# @routes_bp.route("/jobs", methods=["GET"])
# @permission_required("view_job")
# def list_jobs(user):
#     ns = user.namespace if user.namespace else request.args.get("namespace", "default")
#     jobs = batch_v1.list_namespaced_job(namespace=ns)
#     # return jsonify([j.metadata.name for j in jobs.items])
#     job_list = []
#     for job in jobs.items:
#         completions = f"{job.status.succeeded or 0}/{job.spec.completions or 1}"
#         status = "Complete" if job.status.succeeded else "Running" if job.status.active else "Failed"
        
#         job_list.append({
#             "name": job.metadata.name,
#             "namespace": job.metadata.namespace,
#             "completions": completions,
#             "status": status
#         })
#     return jsonify(job_list)

# @routes_bp.route("/jobs", methods=["POST"])
# @permission_required("crud_job")
# def create_job(user):
#     ns = user.namespace if user.namespace else request.args.get("namespace", "default")
#     job_spec = request.get_json()
#     resp = batch_v1.create_namespaced_job(namespace=ns, body=job_spec)
#     return jsonify({"msg": "Job created", "name": resp.metadata.name})

# @routes_bp.route("/jobs/<namespace>/<name>", methods=["DELETE"])
# @permission_required("crud_job")
# def delete_job(user, namespace, name):
#     try:
#         batch_v1.delete_namespaced_job(name=name, namespace=namespace)
#         return jsonify({"msg": "Job deleted successfully"})
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500




# from flask import Blueprint, jsonify, request
# from flask_jwt_extended import jwt_required, get_jwt_identity
# from functools import wraps
# from models import User, Role, Permission, RolePermission
# from db import db

# from kubernetes import client, config

# try:
#     config.load_incluster_config()
# except:
#     config.load_kube_config()

# core_v1 = client.CoreV1Api()
# batch_v1 = client.BatchV1Api()

# routes_bp = Blueprint("routes", __name__)

# def permission_required(permission_name):
#     def wrapper(fn):
#         @wraps(fn)
#         @jwt_required()
#         def decorated(*args, **kwargs):
#             user = User.query.filter_by(username=get_jwt_identity()).first()
#             if not user:
#                 return jsonify({"msg": "Unauthorized"}), 401

#             has_perm = (
#                 db.session.query(Permission)
#                 .join(RolePermission, Permission.id == RolePermission.permission_id)
#                 .filter(RolePermission.role_id == user.role_id, Permission.name == permission_name)
#                 .first()
#             )

#             if not has_perm:
#                 return jsonify({"msg": f"Missing permission: {permission_name}"}), 403

#             return fn(user, *args, **kwargs)
#         return decorated
#     return wrapper

# def get_accessible_namespaces(user):
#     """Determine which namespaces a user can access based on their role"""
#     role_name = user.role.name if user.role else None
    
#     if role_name == "AdminManager":  # AdminManager Manager
#         return "all"
#     elif role_name == "NamespaceManager":  # Namespace Manager
#         return user.namespace if user.namespace else "default"
#     elif role_name == "Viewer":  # Viewer
#         return "all"
#     else:
#         return user.namespace if user.namespace else "default"

# def can_access_namespace(user, target_namespace):
#     """Check if user can access a specific namespace"""
#     role_name = user.role.name if user.role else None
    
#     if role_name == "AdminManager":  # AdminManager Manager - access all
#         return True
#     elif role_name == "NamespaceManager":  # Namespace Manager - only their namespace
#         return user.namespace == target_namespace
#     elif role_name == "Viewer":  # Viewer - access all for viewing
#         return True
#     else:
#         return user.namespace == target_namespace

# # PODS ROUTES
# @routes_bp.route("/pods", methods=["GET"])
# @permission_required("view_pod")
# def list_pods(user):
#     try:
#         accessible_namespaces = get_accessible_namespaces(user)
        
#         if accessible_namespaces == "all":
#             # AdminManager and Viewer can see all namespaces
#             pods = core_v1.list_pod_for_all_namespaces()
#         else:
#             # NamespaceManager sees only their namespace
#             pods = core_v1.list_namespaced_pod(namespace=accessible_namespaces)
        
#         pod_list = []
#         for pod in pods.items:
#             pod_list.append({
#                 "name": pod.metadata.name,
#                 "namespace": pod.metadata.namespace,
#                 "status": pod.status.phase if pod.status else "Unknown"
#             })
#         return jsonify(pod_list)
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# @routes_bp.route("/pods", methods=["POST"])
# @permission_required("crud_pod")
# def create_pod(user):
#     try:
#         pod_spec = request.get_json()
        
#         # Determine target namespace
#         target_namespace = pod_spec.get("metadata", {}).get("namespace")
#         if not target_namespace:
#             # Use namespace from request args or user's namespace
#             target_namespace = request.args.get("namespace", user.namespace or "default")
#             # Set namespace in pod spec
#             if "metadata" not in pod_spec:
#                 pod_spec["metadata"] = {}
#             pod_spec["metadata"]["namespace"] = target_namespace
        
#         # Check if user can access this namespace
#         if not can_access_namespace(user, target_namespace):
#             return jsonify({"msg": f"Access denied to namespace: {target_namespace}"}), 403
        
#         resp = core_v1.create_namespaced_pod(namespace=target_namespace, body=pod_spec)
#         return jsonify({"msg": "Pod created", "name": resp.metadata.name})
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# @routes_bp.route("/pods/<namespace>/<name>", methods=["DELETE"])
# @permission_required("crud_pod")
# def delete_pod(user, namespace, name):
#     try:
#         # Check if user can access this namespace
#         if not can_access_namespace(user, namespace):
#             return jsonify({"msg": f"Access denied to namespace: {namespace}"}), 403
        
#         core_v1.delete_namespaced_pod(name=name, namespace=namespace)
#         return jsonify({"msg": "Pod deleted successfully"})
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# @routes_bp.route("/pods/<namespace>/<name>", methods=["GET"])
# @permission_required("view_pod")
# def get_pod(user, namespace, name):
#     try:
#         # Check if user can access this namespace
#         if not can_access_namespace(user, namespace):
#             return jsonify({"msg": f"Access denied to namespace: {namespace}"}), 403
        
#         pod = core_v1.read_namespaced_pod(name=name, namespace=namespace)
#         return jsonify({
#             "name": pod.metadata.name,
#             "namespace": pod.metadata.namespace,
#             "status": pod.status.phase if pod.status else "Unknown",
#             "node": pod.spec.node_name,
#             "created": pod.metadata.creation_timestamp.isoformat() if pod.metadata.creation_timestamp else None
#         })
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# # JOBS ROUTES
# @routes_bp.route("/jobs", methods=["GET"])
# @permission_required("view_job")
# def list_jobs(user):
#     try:
#         accessible_namespaces = get_accessible_namespaces(user)
        
#         if accessible_namespaces == "all":
#             # AdminManager and Viewer can see all namespaces
#             jobs = batch_v1.list_job_for_all_namespaces()
#         else:
#             # NamespaceManager sees only their namespace
#             jobs = batch_v1.list_namespaced_job(namespace=accessible_namespaces)
        
#         job_list = []
#         for job in jobs.items:
#             completions = f"{job.status.succeeded or 0}/{job.spec.completions or 1}"
#             status = "Complete" if job.status.succeeded else "Running" if job.status.active else "Failed"
            
#             job_list.append({
#                 "name": job.metadata.name,
#                 "namespace": job.metadata.namespace,
#                 "completions": completions,
#                 "status": status
#             })
#         return jsonify(job_list)
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# @routes_bp.route("/jobs", methods=["POST"])
# @permission_required("crud_job")
# def create_job(user):
#     try:
#         job_spec = request.get_json()
        
#         # Determine target namespace
#         target_namespace = job_spec.get("metadata", {}).get("namespace")
#         if not target_namespace:
#             # Use namespace from request args or user's namespace
#             target_namespace = request.args.get("namespace", user.namespace or "default")
#             # Set namespace in job spec
#             if "metadata" not in job_spec:
#                 job_spec["metadata"] = {}
#             job_spec["metadata"]["namespace"] = target_namespace
        
#         # Check if user can access this namespace
#         if not can_access_namespace(user, target_namespace):
#             return jsonify({"msg": f"Access denied to namespace: {target_namespace}"}), 403
        
#         resp = batch_v1.create_namespaced_job(namespace=target_namespace, body=job_spec)
#         return jsonify({"msg": "Job created", "name": resp.metadata.name})
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# @routes_bp.route("/jobs/<namespace>/<name>", methods=["DELETE"])
# @permission_required("crud_job")
# def delete_job(user, namespace, name):
#     try:
#         # Check if user can access this namespace
#         if not can_access_namespace(user, namespace):
#             return jsonify({"msg": f"Access denied to namespace: {namespace}"}), 403
        
#         batch_v1.delete_namespaced_job(name=name, namespace=namespace)
#         return jsonify({"msg": "Job deleted successfully"})
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# @routes_bp.route("/jobs/<namespace>/<name>", methods=["GET"])
# @permission_required("view_job")
# def get_job(user, namespace, name):
#     try:
#         # Check if user can access this namespace
#         if not can_access_namespace(user, namespace):
#             return jsonify({"msg": f"Access denied to namespace: {namespace}"}), 403
        
#         job = batch_v1.read_namespaced_job(name=name, namespace=namespace)
#         return jsonify({
#             "name": job.metadata.name,
#             "namespace": job.metadata.namespace,
#             "completions": f"{job.status.succeeded or 0}/{job.spec.completions or 1}",
#             "status": "Complete" if job.status.succeeded else "Running" if job.status.active else "Failed",
#             "created": job.metadata.creation_timestamp.isoformat() if job.metadata.creation_timestamp else None
#         })
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# # UTILITY ROUTES
# @routes_bp.route("/namespaces", methods=["GET"])
# @permission_required("view_pod")  # Anyone who can view pods can see namespaces
# def list_namespaces(user):
#     try:
#         role_name = user.role.name if user.role else None
        
#         if role_name in ["AdminManager", "Viewer"]:
#             # AdminManager and Viewer can see all namespaces
#             namespaces = core_v1.list_namespace()
#             ns_list = [{"name": ns.metadata.name} for ns in namespaces.items]
#         else:
#             # NamespaceManager sees only their namespace
#             ns_list = [{"name": user.namespace or "default"}]
        
#         return jsonify(ns_list)
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500

# # USER INFO ROUTE
# @routes_bp.route("/user-info", methods=["GET"])
# @jwt_required()
# def get_user_info():
#     try:
#         user = User.query.filter_by(username=get_jwt_identity()).first()
#         if not user:
#             return jsonify({"msg": "User not found"}), 404
        
#         return jsonify({
#             "username": user.username,
#             "role": user.role.name if user.role else None,
#             "namespace": user.namespace,
#             "accessible_namespaces": get_accessible_namespaces(user)
#         })
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500
