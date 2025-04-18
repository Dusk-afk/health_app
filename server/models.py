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
    phone_number = db.Column(db.String(20), unique=True, nullable=True)  # Changed to nullable=True
    email = db.Column(db.String(255), unique=True, nullable=True)
    username = db.Column(db.String(100), unique=True, nullable=True)
    password_hash = db.Column(db.String(255), nullable=False)
    date_of_birth = db.Column(db.Date, nullable=True)
    gender = db.Column(db.String(20), nullable=True)  # Added gender column
    refresh_token = db.Column(db.String(500), nullable=True)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=func.now())
    updated_at = db.Column(db.DateTime, default=func.now(), onupdate=func.now())
    
    # Family relationships
    family_members = db.relationship('FamilyMember', 
                                   foreign_keys='FamilyMember.user_id',
                                   back_populates='user', 
                                   lazy='dynamic',
                                   cascade='all, delete-orphan')
    
    as_family_member = db.relationship('FamilyMember', 
                                     foreign_keys='FamilyMember.member_id',
                                     back_populates='member', 
                                     lazy='dynamic')
    
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


class FamilyMember(db.Model):
    """Model for storing family relationships between users"""
    __tablename__ = 'family_members'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id', name='fk_family_user_id'), nullable=False)
    member_id = db.Column(db.Integer, db.ForeignKey('users.id', name='fk_family_member_id'), nullable=False)
    relationship = db.Column(db.String(50), nullable=False)  # spouse, child, parent, etc.
    created_at = db.Column(db.DateTime, default=func.now())
    updated_at = db.Column(db.DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    user = db.relationship('User', foreign_keys=[user_id], back_populates='family_members')
    member = db.relationship('User', foreign_keys=[member_id], back_populates='as_family_member')
    documents = db.relationship('MedicalDocument', back_populates='family_member', lazy='dynamic')
    
    __table_args__ = (
        db.UniqueConstraint('user_id', 'member_id', name='unique_family_relationship'),
    )

    def __repr__(self):
        return f'<FamilyMember {self.relationship}>'

class MedicalDocument(db.Model):
    """Model for storing medical document metadata"""
    __tablename__ = 'medical_documents'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    family_member_id = db.Column(db.Integer, db.ForeignKey('family_members.id'), nullable=False)
    document_name = db.Column(db.String(255), nullable=False)
    document_type = db.Column(db.String(50), nullable=False)  # Prescription, Lab Report, XRay, Other
    document_date = db.Column(db.Date, nullable=False)
    description = db.Column(db.Text, nullable=True)
    file_path = db.Column(db.String(500), nullable=False)  # S3 path
    file_size = db.Column(db.Integer, nullable=True)  # Size in bytes
    created_at = db.Column(db.DateTime, default=func.now())
    updated_at = db.Column(db.DateTime, default=func.now(), onupdate=func.now())
    
    # Relationships
    user = db.relationship('User', back_populates='documents')
    family_member = db.relationship('FamilyMember', back_populates='documents')
    
    def __repr__(self):
        return f'<MedicalDocument {self.document_name} ({self.document_type})>'