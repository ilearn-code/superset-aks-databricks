from flask import request, jsonify
from superset import app, db
from superset.models.core import Database
from superset.views.base import BaseSupersetView
from superset.utils import get_user_id

class CustomViews(BaseSupersetView):
    @app.route('/api/custom/data', methods=['GET'])
    def get_custom_data():
        user_id = get_user_id()
        # Fetch custom data based on user_id
        data = db.session.query(Database).filter_by(user_id=user_id).all()
        return jsonify([d.to_dict() for d in data])

    @app.route('/api/custom/update', methods=['POST'])
    def update_custom_data():
        data = request.json
        # Update custom data logic here
        # Example: db.session.query(Database).filter_by(id=data['id']).update(data)
        db.session.commit()
        return jsonify({"status": "success", "message": "Data updated successfully."})

    @app.route('/api/custom/delete/<int:id>', methods=['DELETE'])
    def delete_custom_data(id):
        # Delete custom data logic here
        # Example: db.session.query(Database).filter_by(id=id).delete()
        db.session.commit()
        return jsonify({"status": "success", "message": "Data deleted successfully."})

# Register the custom views
app.add_url_rule('/custom', view_func=CustomViews.as_view('custom_views'))