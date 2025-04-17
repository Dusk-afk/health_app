from datetime import datetime, timedelta
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.sql import func
import bcrypt
import jwt
import os
from flask import current_app

db = SQLAlchemy()

class User(db.Model):
    """User model for storing user account data"""
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(255), nullable=False)
    phone_number = db.Column(db.String(20), unique=True, nullable=False)
    email = db.Column(db.String(255), unique=True, nullable=True)
    username = db.Column(db.String(100), unique=True, nullable=True)
    password_hash = db.Column(db.String(255), nullable=False)
    refresh_token = db.Column(db.String(500), nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=func.now())
    updated_at = db.Column(db.DateTime, default=func.now(), onupdate=func.now())
    
    
    family_members = db.relationship('FamilyMember', back_populates='user', lazy='dynamic')
    documents = db.relationship('MedicalDocument', back_populates='user', lazy='dynamic')

    def __repr__(self):
        return f'<User {self.full_name}>'
    
    def set_password(self, password):
        """Hash the user password before storing it."""
        password_bytes = password.encode('utf-8')
        salt = bcrypt.gensalt()
        self.password_hash = bcrypt.hashpw(password_bytes, salt).decode('utf-8')
    
    def check_password(self, password):
        """Verify if the provided password matches the stored hash."""
        password_bytes = password.encode('utf-8')
        hash_bytes = self.password_hash.encode('utf-8')
        return bcrypt.checkpw(password_bytes, hash_bytes)
    
    def generate_access_token(self):
        """Generate a JWT access token for the user."""
        payload = {
            'user_id': self.id,
            'exp': datetime.utcnow() + timedelta(minutes=30),
            'iat': datetime.utcnow(),
            'type': 'access'
        }
        return jwt.encode(
            payload,
            current_app.config.get('JWT_SECRET_KEY', 'default-dev-key'),
            algorithm='HS256'
        )
    
    def generate_refresh_token(self):
        """Generate a JWT refresh token for the user."""
        payload = {
            'user_id': self.id,
            'exp': datetime.utcnow() + timedelta(days=30),
            'iat': datetime.utcnow(),
            'type': 'refresh'
        }
        refresh_token = jwt.encode(
            payload,
            current_app.config.get('JWT_SECRET_KEY', 'default-dev-key'),
            algorithm='HS256'
        )
        self.refresh_token = refresh_token
        return refresh_token
    
    @staticmethod
    def verify_token(token):
        """Verify and decode a JWT token."""
        try:
            payload = jwt.decode(
                token,
                current_app.config.get('JWT_SECRET_KEY', 'default-dev-key'),
                algorithms=['HS256']
            )
            return payload
        except jwt.ExpiredSignatureError:
            return None
        except jwt.InvalidTokenError:
            return None


class FamilyMember(db.Model):
    """Model for storing family member information"""
    __tablename__ = 'family_members'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    relation = db.Column(db.String(50), nullable=False)
    date_of_birth = db.Column(db.Date, nullable=True)
    created_at = db.Column(db.DateTime, default=func.now())
    updated_at = db.Column(db.DateTime, default=func.now(), onupdate=func.now())

    
    user = db.relationship('User', back_populates='family_members')
    documents = db.relationship('MedicalDocument', back_populates='family_member', lazy='dynamic')

    def __repr__(self):
        return f'<FamilyMember {self.name}>'


class MedicalDocument(db.Model):
    """Model for storing medical documents"""
    __tablename__ = 'medical_documents'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    family_member_id = db.Column(db.Integer, db.ForeignKey('family_members.id'), nullable=True)
    document_name = db.Column(db.String(255), nullable=False)
    document_type = db.Column(db.String(50), nullable=False)  
    document_date = db.Column(db.Date, nullable=False)
    description = db.Column(db.Text, nullable=True)
    file_path = db.Column(db.String(500), nullable=False)
    created_at = db.Column(db.DateTime, default=func.now())
    updated_at = db.Column(db.DateTime, default=func.now(), onupdate=func.now())

    
    user = db.relationship('User', back_populates='documents')
    family_member = db.relationship('FamilyMember', back_populates='documents')
    medicines = db.relationship('Medicine', back_populates='document', lazy='dynamic', cascade='all, delete-orphan')

    def __repr__(self):
        return f'<MedicalDocument {self.document_name}>'


class Medicine(db.Model):
    """Model for storing medicine information linked to documents"""
    __tablename__ = 'medicines'

    id = db.Column(db.Integer, primary_key=True)
    document_id = db.Column(db.Integer, db.ForeignKey('medical_documents.id'), nullable=False)
    name = db.Column(db.String(255), nullable=False)
    dosage = db.Column(db.String(100), nullable=True)
    frequency = db.Column(db.String(100), nullable=True)
    duration = db.Column(db.String(100), nullable=True)
    created_at = db.Column(db.DateTime, default=func.now())

    
    document = db.relationship('MedicalDocument', back_populates='medicines')

    def __repr__(self):
        return f'<Medicine {self.name}>'


class HealthData(db.Model):
    """Model for storing health data from Google Health Connect API"""
    __tablename__ = 'health_data'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    family_member_id = db.Column(db.Integer, db.ForeignKey('family_members.id'), nullable=True)
    data_type = db.Column(db.String(50), nullable=False)  
    value = db.Column(db.Float, nullable=False)
    unit = db.Column(db.String(20), nullable=True)
    timestamp = db.Column(db.DateTime, nullable=False)
    source = db.Column(db.String(100), nullable=True)  
    created_at = db.Column(db.DateTime, default=func.now())

    
    user = db.relationship('User', backref=db.backref('health_data', lazy='dynamic'))
    family_member = db.relationship('FamilyMember', backref=db.backref('health_data', lazy='dynamic'))

    def __repr__(self):
        return f'<HealthData {self.data_type}: {self.value}{self.unit}>'