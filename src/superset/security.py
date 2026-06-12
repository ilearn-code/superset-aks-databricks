class SecurityManager:
    def __init__(self, app):
        self.app = app
        self.user_roles = {}
        self.permissions = {}

    def add_user(self, username, role):
        if username not in self.user_roles:
            self.user_roles[username] = role
            return f"User {username} added with role {role}."
        return f"User {username} already exists."

    def remove_user(self, username):
        if username in self.user_roles:
            del self.user_roles[username]
            return f"User {username} removed."
        return f"User {username} does not exist."

    def assign_permission(self, role, permission):
        if role not in self.permissions:
            self.permissions[role] = set()
        self.permissions[role].add(permission)
        return f"Permission {permission} assigned to role {role}."

    def check_permission(self, username, permission):
        role = self.user_roles.get(username)
        if role and permission in self.permissions.get(role, set()):
            return True
        return False

    def authenticate(self, username, password):
        return False

    def authorize(self, username, permission):
        if self.check_permission(username, permission):
            return True
        return False
