import os
from flask import Flask, jsonify, request, make_response
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager, jwt_required, create_access_token, create_refresh_token, get_jwt_identity
from flask_bcrypt import Bcrypt
from models import db, User, FamilyMember
from routes.document_routes import document_bp
from config import config
import datetime
import re

def create_app(config_name=None):
    """Factory function to create and configure Flask application instance"""
    if config_name is None:
        config_name = os.environ.get('FLASK_CONFIG', 'default')
    
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    
    # Configure S3 settings - these should be set in your environment variables or config
    app.config['AWS_ACCESS_KEY'] = os.environ.get('AWS_ACCESS_KEY') or 'your_access_key'
    app.config['AWS_SECRET_KEY'] = os.environ.get('AWS_SECRET_KEY') or 'your_secret_key'
    app.config['AWS_REGION'] = os.environ.get('AWS_REGION') or 'us-east-1'
    app.config['S3_BUCKET_NAME'] = os.environ.get('S3_BUCKET_NAME') or 'your-health-app-bucket'
    
    db.init_app(app)
    migrate = Migrate(app, db)
    bcrypt = Bcrypt(app)
    jwt = JWTManager(app)
    
    # Register blueprints
    app.register_blueprint(document_bp, url_prefix='/api/v1/documents')
    
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
            username=data.get('username'),
            gender=data.get('gender'),
        )
        
        # Parse and set date of birth if provided
        if data.get('date_of_birth'):
            try:
                date_of_birth = datetime.datetime.fromisoformat(data['date_of_birth'].replace('Z', '+00:00')).date()
                new_user.date_of_birth = date_of_birth
            except ValueError:
                return jsonify({"error": "Invalid date format for date_of_birth. Use ISO format (YYYY-MM-DD)"}), 400
        
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
    
    @app.route('/api/v1/auth/me', methods=['GET'])
    @jwt_required()
    def get_user_profile():
        current_user_id = get_jwt_identity()
        user = User.query.get(current_user_id)
        
        if not user:
            return jsonify({"error": "User not found"}), 404
        
        # Format date of birth to ISO string if it exists
        date_of_birth = None
        if user.date_of_birth:
            date_of_birth = user.date_of_birth.isoformat()
            
        return jsonify({
            "user": {
                "id": user.id,
                "full_name": user.full_name,
                "phone_number": user.phone_number,
                "email": user.email,
                "username": user.username,
                "date_of_birth": date_of_birth
            }
        }), 200
    
    
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({"error": "Not found"}), 404
    
    @app.errorhandler(500)
    def internal_server_error(error):
        return jsonify({"error": "Server error"}), 500
    
    # Family Members API routes
    @app.route('/api/v1/family', methods=['GET'])
    @jwt_required()
    def get_family_members():
        """Get all family members for the current user"""
        current_user_id = get_jwt_identity()
        
        # Get the current user first
        current_user = User.query.get(current_user_id)
        if not current_user:
            return jsonify({"error": "User not found"}), 404
            
        # Format date of birth to ISO string if it exists
        current_user_dob = None
        if (current_user.date_of_birth):
            current_user_dob = current_user.date_of_birth.isoformat()
        
        # Create a list with the current user as the first member
        family_members = [{
            "id": current_user.id,
            "family_member_id": 0,  # Special value to identify as self
            "full_name": current_user.full_name,
            "phone_number": current_user.phone_number,
            "email": current_user.email,
            "relationship": "self",
            "date_of_birth": current_user_dob,
            "gender": current_user.gender,
            "is_self": True
        }]
        
        # Find all family relationships where the current user is the main user
        family_relationships = FamilyMember.query.filter_by(user_id=current_user_id).all()
        
        for relationship in family_relationships:
            member = User.query.get(relationship.member_id)
            if member:
                # Format date of birth to ISO string if it exists
                date_of_birth = None
                if member.date_of_birth:
                    date_of_birth = member.date_of_birth.isoformat()
                
                family_members.append({
                    "id": member.id,
                    "family_member_id": relationship.id,
                    "full_name": member.full_name,
                    "phone_number": member.phone_number,
                    "email": member.email,
                    "relationship": relationship.relationship,
                    "date_of_birth": date_of_birth,
                    "gender": member.gender,
                    "is_self": False
                })
        
        return jsonify({
            "family_members": family_members
        }), 200
    
    @app.route('/api/v1/family', methods=['POST'])
    @jwt_required()
    def add_family_member():
        """Add a new family member for the current user"""
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No input data provided"}), 400
        
        # Check required fields
        required_fields = ['full_name', 'relationship']
        for field in required_fields:
            if not data.get(field):
                return jsonify({"error": f"Missing required field: {field}"}), 400
        
        # Check if we need to create a new user or use existing
        existing_user = None
        if data.get('phone_number'):
            existing_user = User.query.filter_by(phone_number=data['phone_number']).first()
        
        # If user doesn't exist, create a new one
        if not existing_user:
            # Generate a temporary password for the family member
            import secrets
            temp_password = secrets.token_hex(8)
            
            new_member = User(
                full_name=data['full_name'],
                phone_number=data.get('phone_number'),  # This is now nullable
                email=data.get('email'),
                gender=data.get('gender')
            )
            
            # Parse and set date of birth if provided
            if data.get('date_of_birth'):
                try:
                    date_of_birth = datetime.datetime.fromisoformat(data['date_of_birth'].replace('Z', '+00:00')).date()
                    new_member.date_of_birth = date_of_birth
                except ValueError:
                    return jsonify({"error": "Invalid date format for date_of_birth. Use ISO format (YYYY-MM-DD)"}), 400
            
            new_member.set_password(temp_password)
            
            try:
                db.session.add(new_member)
                db.session.flush()  # Get the ID without committing
                member_id = new_member.id
            except Exception as e:
                db.session.rollback()
                return jsonify({"error": f"Failed to create family member: {str(e)}"}), 500
        else:
            # Use existing user
            member_id = existing_user.id
            
            # Check if relationship already exists
            existing_relationship = FamilyMember.query.filter_by(
                user_id=current_user_id,
                member_id=member_id
            ).first()
            
            if existing_relationship:
                return jsonify({"error": "This person is already in your family"}), 409
        
        # Create the family relationship
        family_relation = FamilyMember(
            user_id=current_user_id,
            member_id=member_id,
            relationship=data['relationship']
        )
        
        try:
            db.session.add(family_relation)
            db.session.commit()
            
            # Get the member data to return
            member = User.query.get(member_id)
            
            # Format date of birth to ISO string if it exists
            date_of_birth = None
            if member.date_of_birth:
                date_of_birth = member.date_of_birth.isoformat()
            
            return jsonify({
                "message": "Family member added successfully",
                "family_member": {
                    "id": member.id,
                    "family_member_id": family_relation.id,
                    "full_name": member.full_name,
                    "phone_number": member.phone_number,
                    "email": member.email,
                    "relationship": family_relation.relationship,
                    "date_of_birth": date_of_birth,
                    "gender": member.gender
                }
            }), 201
            
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": f"Failed to add family member: {str(e)}"}), 500
    
    @app.route('/api/v1/family/<int:family_member_id>', methods=['GET'])
    @jwt_required()
    def get_family_member(family_member_id):
        """Get details of a specific family member"""
        current_user_id = get_jwt_identity()
        
        # Find the family relationship
        relationship = FamilyMember.query.filter_by(
            id=family_member_id,
            user_id=current_user_id
        ).first()
        
        if not relationship:
            return jsonify({"error": "Family member not found"}), 404
        
        # Get the user details
        member = User.query.get(relationship.member_id)
        if not member:
            return jsonify({"error": "User not found"}), 404
        
        # Format date of birth to ISO string if it exists
        date_of_birth = None
        if member.date_of_birth:
            date_of_birth = member.date_of_birth.isoformat()
        
        return jsonify({
            "family_member": {
                "id": member.id,
                "family_member_id": relationship.id,
                "full_name": member.full_name,
                "phone_number": member.phone_number,
                "email": member.email,
                "relationship": relationship.relationship,
                "date_of_birth": date_of_birth,
                "gender": member.gender
            }
        }), 200
    
    @app.route('/api/v1/family/<int:family_member_id>', methods=['PUT'])
    @jwt_required()
    def update_family_member(family_member_id):
        """Update a family member's relationship information"""
        current_user_id = get_jwt_identity()
        data = request.get_json()
        
        if not data:
            return jsonify({"error": "No input data provided"}), 400
        
        # Find the family relationship
        relationship = FamilyMember.query.filter_by(
            id=family_member_id,
            user_id=current_user_id
        ).first()
        
        if not relationship:
            return jsonify({"error": "Family member not found"}), 404
        
        # Update relationship type if provided
        if data.get('relationship'):
            relationship.relationship = data['relationship']
        
        # Get the user record
        member = User.query.get(relationship.member_id)
        if not member:
            return jsonify({"error": "User not found"}), 404
        
        # Update user fields if provided
        if data.get('full_name'):
            member.full_name = data['full_name']
            
        if data.get('email'):
            member.email = data['email']
            
        if data.get('gender'):
            member.gender = data['gender']
            
        if data.get('date_of_birth'):
            try:
                date_of_birth = datetime.datetime.fromisoformat(data['date_of_birth'].replace('Z', '+00:00')).date()
                member.date_of_birth = date_of_birth
            except ValueError:
                return jsonify({"error": "Invalid date format for date_of_birth. Use ISO format (YYYY-MM-DD)"}), 400
        
        try:
            db.session.commit()
            
            # Format date of birth to ISO string if it exists
            date_of_birth = None
            if member.date_of_birth:
                date_of_birth = member.date_of_birth.isoformat()
            
            return jsonify({
                "message": "Family member updated successfully",
                "family_member": {
                    "id": member.id,
                    "family_member_id": relationship.id,
                    "full_name": member.full_name,
                    "phone_number": member.phone_number,
                    "email": member.email,
                    "relationship": relationship.relationship,
                    "date_of_birth": date_of_birth,
                    "gender": member.gender
                }
            }), 200
            
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": f"Failed to update family member: {str(e)}"}), 500
    
    @app.route('/api/v1/family/<int:family_member_id>', methods=['DELETE'])
    @jwt_required()
    def remove_family_member(family_member_id):
        """Remove a family member relationship"""
        current_user_id = get_jwt_identity()
        
        # Find the family relationship
        relationship = FamilyMember.query.filter_by(
            id=family_member_id,
            user_id=current_user_id
        ).first()
        
        if not relationship:
            return jsonify({"error": "Family member not found"}), 404
        
        try:
            db.session.delete(relationship)
            db.session.commit()
            return jsonify({"message": "Family member removed successfully"}), 200
            
        except Exception as e:
            db.session.rollback()
            return jsonify({"error": f"Failed to remove family member: {str(e)}"}), 500
    
    return app


app = create_app()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)