from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
import os
import json

app = Flask(__name__)
CORS(app)

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(BASE_DIR, 'user.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# Models
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password = db.Column(db.String(120), nullable=False)

class Log(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    content = db.Column(db.Text, nullable=False)

# Signup
@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'error': 'Email and password are required'}), 400

    if User.query.filter_by(email=email).first():
        return jsonify({'error': 'User already exists'}), 400

    user = User(email=email, password=password)
    db.session.add(user)
    db.session.commit()

    return jsonify({'message': 'User created successfully. Please log in.'}), 200

# Login
@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({'error': 'Email and password are required'}), 400

    user = User.query.filter_by(email=email, password=password).first()
    if not user:
        return jsonify({'error': 'Invalid credentials'}), 401

    return jsonify({'message': 'Login successful', 'user_id': user.id}), 200

# Backup logs
@app.route('/backup', methods=['POST'])
def backup():
    data = request.get_json()
    user_id = data.get('user_id')
    logs = data.get('logs')

    if not logs or not user_id:
        return jsonify({'error': 'User ID and logs are required'}), 400

    for entry in logs:
        log = Log(user_id=user_id, content=json.dumps(entry))
        db.session.add(log)

    db.session.commit()
    return jsonify({'message': 'Logs backed up successfully'}), 200

# Restore logs
@app.route('/restore/<int:user_id>', methods=['GET'])
def restore(user_id):
    logs = Log.query.filter_by(user_id=user_id).all()
    restored_logs = [json.loads(log.content) for log in logs]
    return jsonify({'logs': restored_logs}), 200

@app.before_first_request
def create_tables():
    db.create_all()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=os.environ.get("PORT", 5000))
