

from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
from models import User, Role, Namespace
from db import db

auth_bp = Blueprint("auth", __name__)

# Register
@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")
    role_name = data.get("role")
    namespace = data.get("namespace")

    if not username or not password or not role_name:
        return jsonify({"msg": "Missing fields"}), 400

    role = Role.query.filter_by(name=role_name).first()
    if not role:
        return jsonify({"msg": "Invalid role"}), 400

    if role.name == "Viewer":
        namespace = "backend"

    if role.name == "NamespaceManager":
        if not namespace:
            return jsonify({"msg": "Namespace required for NamespaceManager"}), 400
        ns = Namespace.query.filter_by(name=namespace).first()
        if not ns:
            ns = Namespace(name=namespace)
            db.session.add(ns)

    user = User(username=username, password=password, role_id=role.id, namespace=namespace)

    db.session.add(user)
    db.session.commit()

    return jsonify({"msg": "User registered successfully"}), 201


#login
@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username")
    password = data.get("password")

    user = User.query.filter_by(username=username).first()
    if not user or user.password != password:
        return jsonify({"msg": "Invalid credentials"}), 401

    token = create_access_token(identity=user.username)
    return jsonify({"access_token": token}), 200
