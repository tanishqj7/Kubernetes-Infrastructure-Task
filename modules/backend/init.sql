CREATE DATABASE kube;

\c kube;

CREATE TABLE IF NOT EXISTS role (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS permission (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS role_permission (
    role_id INT REFERENCES role(id) ON DELETE CASCADE,
    permission_id INT REFERENCES permission(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE IF NOT EXISTS "user" (
    id SERIAL PRIMARY KEY,
    username VARCHAR(120) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role_id INT REFERENCES role(id) ON DELETE CASCADE,
    namespace VARCHAR(120) DEFAULT 'platform',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Namespaces table
CREATE TABLE IF NOT EXISTS namespace (
    id SERIAL PRIMARY KEY,
    name VARCHAR(120) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO role (name, description) VALUES
('AdminManager', 'Access to all namespaces with all operations'),
('NamespaceManager', 'Access to assigned namespace with all operations'),
('Viewer', 'Read-only access, limited to default namespace')
ON CONFLICT (name) DO NOTHING;

INSERT INTO permission (name, description) VALUES
('view_pod', 'View pod details'),
('crud_pod', 'CRUD pod'),
('view_job', 'View job details'),
('crud_job', 'CRUD job')
ON CONFLICT (name) DO NOTHING;

INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM role r, permission p
WHERE r.name = 'AdminManager'
ON CONFLICT (role_id, permission_id) DO NOTHING;

INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM role r
JOIN permission p ON p.name IN ('view_pod','crud_pod','view_job','crud_job')
WHERE r.name = 'NamespaceManager'
ON CONFLICT (role_id, permission_id) DO NOTHING;

INSERT INTO role_permission (role_id, permission_id)
SELECT r.id, p.id
FROM role r
JOIN permission p ON p.name IN ('view_pod','view_job')
WHERE r.name = 'Viewer'
ON CONFLICT (role_id, permission_id) DO NOTHING;

INSERT INTO namespace (name)
VALUES ('default')
ON CONFLICT (name) DO NOTHING;

INSERT INTO "user" (username, password, role_id, namespace)
VALUES (
    'admin',
    'admin',
    (SELECT id FROM role WHERE name = 'AdminManager'),
    NULL
)
ON CONFLICT (username) DO NOTHING;



-- CREATE DATABASE kube;
-- \c kube;

-- -- Roles table
-- CREATE TABLE IF NOT EXISTS roles (
--     id SERIAL PRIMARY KEY,
--     name VARCHAR(50) UNIQUE NOT NULL,
--     description TEXT
-- );

-- -- Permissions table
-- CREATE TABLE IF NOT EXISTS permissions (
--     id SERIAL PRIMARY KEY,
--     name VARCHAR(100) UNIQUE NOT NULL,
--     description TEXT
-- );

-- -- Role ↔ Permissions mapping
-- CREATE TABLE IF NOT EXISTS role_permissions (
--     role_id INT REFERENCES roles(id) ON DELETE CASCADE,
--     permission_id INT REFERENCES permissions(id) ON DELETE CASCADE,
--     PRIMARY KEY (role_id, permission_id)
-- );

-- -- Users table
-- CREATE TABLE IF NOT EXISTS users (
--     id SERIAL PRIMARY KEY,
--     username VARCHAR(120) UNIQUE NOT NULL,
--     password VARCHAR(255) NOT NULL,
--     role_id INT REFERENCES roles(id) ON DELETE CASCADE,
--     namespace VARCHAR(120),
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- -- Namespaces table
-- CREATE TABLE IF NOT EXISTS namespaces (
--     id SERIAL PRIMARY KEY,
--     name VARCHAR(120) UNIQUE NOT NULL,
--     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
-- );

-- -- Roles
-- INSERT INTO roles (name, description) VALUES
-- ('AdminManager', 'Access to all namespaces with all operations'),
-- ('NamespaceManager', 'Access to assigned namespace with all operations'),
-- ('Viewer', 'Read-only access, limited to default namespace')
-- ON CONFLICT (name) DO NOTHING;

-- -- Permissions
-- INSERT INTO permissions (name, description) VALUES
-- ('view_pod', 'View pod details'),
-- ('crud_pod', 'CRUD pod'),
-- ('view_job', 'View job details'),
-- ('crud_job', 'CRUD job')
-- ON CONFLICT (name) DO NOTHING;

-- -- Permissions to AdminManager (all perms)
-- INSERT INTO role_permissions (role_id, permission_id)
-- SELECT r.id, p.id
-- FROM roles r, permissions p
-- WHERE r.name = 'AdminManager'
-- ON CONFLICT (role_id, permission_id) DO NOTHING;

-- -- Permissions to NamespaceManager
-- INSERT INTO role_permissions (role_id, permission_id)
-- SELECT r.id, p.id
-- FROM roles r
-- JOIN permissions p ON p.name IN ('view_pod','crud_pod','view_job','crud_job')
-- WHERE r.name = 'NamespaceManager'
-- ON CONFLICT (role_id, permission_id) DO NOTHING;

-- -- Permissions to Viewer
-- INSERT INTO role_permissions (role_id, permission_id)
-- SELECT r.id, p.id
-- FROM roles r
-- JOIN permissions p ON p.name IN ('view_pod','view_job')
-- WHERE r.name = 'Viewer'
-- ON CONFLICT (role_id, permission_id) DO NOTHING;

-- -- Default namespace
-- INSERT INTO namespaces (name)
-- VALUES ('default')
-- ON CONFLICT (name) DO NOTHING;

-- -- Admin user
-- INSERT INTO users (username, password, role_id, namespace)
-- VALUES (
--     'admin',
--     'admin',
--     (SELECT id FROM roles WHERE name = 'AdminManager'),
--     NULL
-- )
-- ON CONFLICT (username) DO NOTHING;
