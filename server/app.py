import os
from flask import Flask, jsonify, request, make_response
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager, jwt_required, create_access_token, create_refresh_token, get_jwt_identity
from flask_bcrypt import Bcrypt
from models import db, User
from config import config
import datetime
import re
import traceback
from gemini_bot import get_gemini_response 
import google.generativeai as genai
import os
import google.generativeai as genai
from dotenv import load_dotenv

from models import ChatHistory

# Load API key from .env file
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    raise ValueError("API Key not found. Make sure .env file contains GEMINI_API_KEY")

# Configure Gemini with your API key
genai.configure(api_key=api_key)
model = genai.GenerativeModel(model_name="gemini-2.0-flash")

chat_sessions = {}  # Stores user-wise chat objects 

def create_app(config_name=None):
    """Factory function to create and configure Flask application instance"""
    if config_name is None:
        config_name = os.environ.get('FLASK_CONFIG', 'default')
    
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    
    
    db.init_app(app)
    migrate = Migrate(app, db)
    bcrypt = Bcrypt(app)
    jwt = JWTManager(app)
    
    
    @app.route('/api')
    def index():
        return jsonify({
            "status": "success",
            "message": "Welcome to the Health Server API!"
        })

    @app.route('/api/health')
    def health():
        return jsonify({
            "status": "healthy",
            "timestamp": str(datetime.datetime.now())
        })
    
    
    @app.route('/api/v1/auth/signup', methods=['POST'])
    def signup():
        data = request.get_json()
        
        
        if not data:
            return jsonify({"error": "No input data provided"}), 400
        
        required_fields = ['full_name', 'phone_number', 'password']
        for field in required_fields:
            if not data.get(field):
                return jsonify({"error": f"Missing required field: {field}"}), 400
                
        
        phone_number = data['phone_number'].strip()
        if not re.match(r'^\d{6,15}$', phone_number):
            return jsonify({"error": "Invalid phone number format. Use only digits (6-15 characters)"}), 400
            
        
        if User.query.filter_by(phone_number=phone_number).first():
            return jsonify({"error": "User with this phone number already exists"}), 409
            
        
        new_user = User(
            full_name=data['full_name'],
            phone_number=phone_number,
            email=data.get('email'),  
            username=data.get('username')  
        )
        
        
        new_user.set_password(data['password'])
        
        try:
            db.session.add(new_user)
            db.session.commit()
            
            
            access_token = create_access_token(identity=new_user.id)
            refresh_token = create_refresh_token(identity=new_user.id)
            
            
            new_user.refresh_token = refresh_token
            db.session.commit()
            
            return jsonify({
                "message": "User created successfully",
                "user": {
                    "id": new_user.id,
                    "full_name": new_user.full_name,
                    "phone_number": new_user.phone_number
                },
                "access_token": access_token,
                "refresh_token": refresh_token,
                "token_type": "Bearer"
            }), 201
            
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": f"Failed to create user: {str(e)}"}), 500
    
    @app.route('/api/v1/auth/login', methods=['POST'])
    def login():
        data = request.get_json()
        
        
        if not data:
            return jsonify({"error": "No input data provided"}), 400
            
        if not data.get('phone_number') or not data.get('password'):
            return jsonify({"error": "Phone number and password required"}), 400
            
        
        user = User.query.filter_by(phone_number=data['phone_number']).first()
        if not user:
            return jsonify({"error": "Invalid credentials"}), 401
            
        
        if not user.check_password(data['password']):
            return jsonify({"error": "Invalid credentials"}), 401
            
        
        access_token = create_access_token(identity=user.id)
        refresh_token = create_refresh_token(identity=user.id)
        
        
        user.refresh_token = refresh_token
        db.session.commit()
        
        return jsonify({
            "message": "Login successful",
            "user": {
                "id": user.id,
                "full_name": user.full_name,
                "phone_number": user.phone_number
            },
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "Bearer"
        }), 200
    
    @app.route('/api/v1/auth/refresh', methods=['POST'])
    @jwt_required(refresh=True)
    def refresh():
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        
        access_token = create_access_token(identity=user.id)
        refresh_token = create_refresh_token(identity=user.id)
        
        
        user.refresh_token = refresh_token
        db.session.commit()
        
        return jsonify({
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "Bearer"
        }), 200
    
    @app.route('/api/v1/mental-health-chat', methods=['POST'])
    @jwt_required()
    def mental_health_chat():
        try:
            data = request.get_json()
            user_id = get_jwt_identity()
            user_message = data.get("message")
            family_member_id = data.get("family_member_id")  # Optional

            if not user_message:
                return jsonify({"error": "Message is required"}), 400

            # Step 1: Load chat history for this user (and optionally the family member)
            query = ChatHistory.query.filter_by(user_id=user_id)
            if family_member_id:
                query = query.filter_by(family_member_id=family_member_id)
            
            previous_chats = query.order_by(ChatHistory.timestamp).all()

            # Step 2: Prepare model-compatible history
            history = []
            if not previous_chats:
                # First-time chat: Inject system instruction
                history.append({
                    "role": "user",
                    "parts": [
                        "You are a friendly and professional healthcare assistant specialized in both physical and mental health. "
                        "Always keep your responses aligned with medical support, wellness advice, and mental health awareness. "
                        "Ask follow-up questions like a compassionate doctor — such as symptoms, duration, pain level, emotional impact, and previous treatments. "
                        "Avoid discussing any topic outside of healthcare and well-being. Always be empathetic and supportive."
                    ]
                })
            else:
                for chat in previous_chats:
                    history.append({
                        "role": "user",
                        "parts": [chat.user_message]
                    })
                    history.append({
                        "role": "model",
                        "parts": [chat.bot_response]
                    })

            # Step 3: Append the latest user message
            history.append({
                "role": "user",
                "parts": [user_message]
            })

            # Step 4: Interact with the Gemini model
            chat = model.start_chat(history=history)
            response = chat.send_message(user_message)
            bot_response = response.text.strip()

            # Step 5: Save this exchange to DB
            new_entry = ChatHistory(
                user_id=user_id,
                family_member_id=family_member_id,
                user_message=user_message,
                bot_response=bot_response
            )
            db.session.add(new_entry)
            db.session.commit()

            # Step 6: Return the response
            # Step 6: Return the response along with full chat history
            full_chat = ChatHistory.query.filter_by(user_id=user_id)
            if family_member_id:
                full_chat = full_chat.filter_by(family_member_id=family_member_id)

            full_chat = full_chat.order_by(ChatHistory.timestamp).all()

            formatted_history = []
            for chat in full_chat:
                formatted_history.append({
                    "user_message": chat.user_message,
                    "bot_response": chat.bot_response,
                    "timestamp": chat.timestamp.strftime('%Y-%m-%d %H:%M:%S')
                })

            return jsonify({
                # "response": bot_response,
                "history": formatted_history
            }), 200


        except Exception as e:
            traceback.print_exc()
            return jsonify({"error": str(e)}), 500

    @app.route('/api/v1/auth/me', methods=['GET'])
    @jwt_required()
    def get_user_profile():
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        if not user:
            return jsonify({"error": "User not found"}), 404
            
        return jsonify({
            "user": {
                "id": user.id,
                "full_name": user.full_name,
                "phone_number": user.phone_number,
                "email": user.email,
                "username": user.username
            }
        }), 200
    
    
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({"error": "Not found"}), 404
    
    @app.errorhandler(500)
    def internal_server_error(error):
        return jsonify({"error": "Server error"}), 500
    
    return app



app = create_app()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)