from flask import Flask
from flask_jwt_extended import JWTManager
from config import Config
from db import db
from auth import auth_bp
from routes import routes_bp
from flask_cors import CORS


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    JWTManager(app)

    CORS(app)
    
    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(routes_bp, url_prefix="/api")

    with app.app_context():
        db.create_all()

    return app

app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
