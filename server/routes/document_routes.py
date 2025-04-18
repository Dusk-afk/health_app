from flask import Blueprint, request, jsonify, current_app
from models import db, MedicalDocument, User, FamilyMember
from utils.s3_utils import S3Utils
from datetime import datetime
from flask_jwt_extended import jwt_required, get_jwt_identity
import os

document_bp = Blueprint('document_routes', __name__)

@document_bp.route('/upload', methods=['POST'])
@jwt_required()
def upload_document():
    """Upload a medical document"""
    try:
        # Get the current user ID from the JWT
        current_user_id = get_jwt_identity()
        
        # Check if file is included in the request
        if 'document' not in request.files:
            return jsonify({'error': 'No document file provided'}), 400
        
        file = request.files['document']
        if file.filename == '':
            return jsonify({'error': 'Empty document file'}), 400
        
        # Get document metadata from form
        document_name = request.form.get('document_name')
        document_type = request.form.get('document_type')  # Prescription, Lab Report, etc.
        document_date = request.form.get('document_date')  # Format: YYYY-MM-DD
        family_member_id = request.form.get('family_member_id')
        description = request.form.get('description', '')
        
        # Validate required fields
        if not all([document_name, document_type, document_date, family_member_id]):
            return jsonify({'error': 'Missing required document information'}), 400
        
        # Validate that the family member belongs to the current user
        family_member = FamilyMember.query.filter_by(
            id=family_member_id, 
            user_id=current_user_id
        ).first()
        
        if not family_member:
            return jsonify({'error': 'Invalid or unauthorized family member'}), 403
        
        # Convert date string to Date object
        try:
            doc_date = datetime.strptime(document_date, '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
        
        # Calculate file size *before* uploading
        file.seek(0, os.SEEK_END)
        file_size = file.tell()
        file.seek(0) # Reset file pointer for upload

        # Upload file to S3
        success, file_path = S3Utils.upload_file(
            file, 
            current_user_id, 
            family_member_id, 
            document_type.lower().replace(' ', '_')
        )
        
        if not success:
            return jsonify({'error': f'Failed to upload document: {file_path}'}), 500
        
        # Create new document record
        new_document = MedicalDocument(
            user_id=current_user_id,
            family_member_id=family_member_id,
            document_name=document_name,
            document_type=document_type,
            document_date=doc_date,
            description=description,
            file_path=file_path,
            file_size=file_size # Use the calculated size
        )
        
        # Save to database
        db.session.add(new_document)
        db.session.commit()
        
        # Return success response with document ID
        return jsonify({
            'message': 'Document uploaded successfully',
            'document_id': new_document.id
        }), 201
        
    except Exception as e:
        current_app.logger.error(f"Error uploading document: {e}")
        return jsonify({'error': f'Error uploading document: {str(e)}'}), 500


@document_bp.route('/family/<int:family_member_id>/documents', methods=['GET'])
@jwt_required()
def get_family_member_documents(family_member_id):
    """Get all documents for a specific family member"""
    try:
        # Get the current user ID from the JWT
        current_user_id = get_jwt_identity()
        
        # Validate that the family member belongs to the current user
        family_member = FamilyMember.query.filter_by(
            id=family_member_id, 
            user_id=current_user_id
        ).first()
        
        if not family_member:
            return jsonify({'error': 'Invalid or unauthorized family member'}), 403
        
        # Query all documents for this family member
        documents = MedicalDocument.query.filter_by(
            family_member_id=family_member_id,
            user_id=current_user_id
        ).order_by(MedicalDocument.document_date.desc()).all()
        
        # Format documents for response
        documents_list = []
        for doc in documents:
            # Generate a temporary URL for the document
            document_url = S3Utils.generate_presigned_url(doc.file_path, expiration=3600)
            
            documents_list.append({
                'id': doc.id,
                'document_name': doc.document_name,
                'document_type': doc.document_type,
                'document_date': doc.document_date.strftime('%Y-%m-%d'),
                'description': doc.description,
                'created_at': doc.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                'file_size': doc.file_size,
                'download_url': document_url
            })
        
        # Return the documents list
        return jsonify({
            'documents': documents_list,
            'count': len(documents_list)
        }), 200
        
    except Exception as e:
        current_app.logger.error(f"Error retrieving documents: {e}")
        return jsonify({'error': f'Error retrieving documents: {str(e)}'}), 500


@document_bp.route('/documents/<int:document_id>', methods=['GET'])
@jwt_required()
def get_document(document_id):
    """Get details for a specific document"""
    try:
        # Get the current user ID from the JWT
        current_user_id = get_jwt_identity()
        
        # Find the document
        document = MedicalDocument.query.filter_by(
            id=document_id,
            user_id=current_user_id
        ).first()
        
        if not document:
            return jsonify({'error': 'Document not found or unauthorized'}), 404
        
        # Generate a temporary URL for the document
        document_url = S3Utils.generate_presigned_url(document.file_path)
        
        # Return document details
        return jsonify({
            'id': document.id,
            'document_name': document.document_name,
            'document_type': document.document_type,
            'document_date': document.document_date.strftime('%Y-%m-%d'),
            'description': document.description,
            'created_at': document.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'file_size': document.file_size,
            'download_url': document_url
        }), 200
        
    except Exception as e:
        current_app.logger.error(f"Error retrieving document: {e}")
        return jsonify({'error': f'Error retrieving document: {str(e)}'}), 500


@document_bp.route('/documents/<int:document_id>', methods=['DELETE'])
@jwt_required()
def delete_document(document_id):
    """Delete a specific document"""
    try:
        # Get the current user ID from the JWT
        current_user_id = get_jwt_identity()
        
        # Find the document
        document = MedicalDocument.query.filter_by(
            id=document_id,
            user_id=current_user_id
        ).first()
        
        if not document:
            return jsonify({'error': 'Document not found or unauthorized'}), 404
        
        # Delete from database (Note: we're not deleting from S3 in this version)
        db.session.delete(document)
        db.session.commit()
        
        return jsonify({'message': 'Document deleted successfully'}), 200
        
    except Exception as e:
        current_app.logger.error(f"Error deleting document: {e}")
        return jsonify({'error': f'Error deleting document: {str(e)}'}), 500


@document_bp.route('/request_upload_url', methods=['POST'])
@jwt_required()
def request_upload_url():
    """Request a presigned URL for direct S3 upload"""
    try:
        # Get the current user ID from the JWT
        current_user_id = get_jwt_identity()
        
        # Get document info from request data
        data = request.json
        if not data:
            return jsonify({'error': 'No data provided'}), 400
            
        file_name = data.get('file_name')
        document_type = data.get('document_type')
        family_member_id = data.get('family_member_id')
        content_type = data.get('content_type', 'application/octet-stream')
        
        # Validate required fields
        if not all([file_name, document_type, family_member_id]):
            return jsonify({'error': 'Missing required document information'}), 400
            
        # Validate that the family member belongs to the current user
        family_member = FamilyMember.query.filter_by(
            id=family_member_id, 
            user_id=current_user_id
        ).first()
        
        if not family_member:
            return jsonify({'error': 'Invalid or unauthorized family member'}), 403
            
        # Create a unique filename using UUID
        import uuid
        from werkzeug.utils import secure_filename
        
        original_filename = secure_filename(file_name)
        file_extension = os.path.splitext(original_filename)[1]
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        
        # Create the S3 object key (path)
        doc_type_safe = document_type.lower().replace(' ', '_')
        s3_key = f"documents/user_{current_user_id}/member_{family_member_id}/{doc_type_safe}/{unique_filename}"
        
        # Get S3 client
        s3_client = S3Utils.get_s3_client()
        bucket_name = current_app.config['S3_BUCKET_NAME']
        
        # Generate a presigned URL for a PUT operation
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket_name,
                'Key': s3_key,
                'ContentType': content_type
            },
            ExpiresIn=3600  # URL valid for 1 hour
        )
        
        return jsonify({
            'presigned_url': presigned_url,
            's3_key': f"s3://{bucket_name}/{s3_key}"  # Full S3 path for reference
        }), 200
        
    except Exception as e:
        current_app.logger.error(f"Error generating presigned URL: {e}")
        return jsonify({'error': f'Error generating presigned URL: {str(e)}'}), 500


@document_bp.route('/complete_upload', methods=['POST'])
@jwt_required()
def complete_upload():
    """Complete the document upload process after direct S3 upload"""
    try:
        # Get the current user ID from the JWT
        current_user_id = get_jwt_identity()
        
        # Get document metadata from request
        data = request.json
        if not data:
            return jsonify({'error': 'No data provided'}), 400
            
        document_name = data.get('document_name')
        document_type = data.get('document_type')
        document_date = data.get('document_date')
        family_member_id = data.get('family_member_id')
        description = data.get('description', '')
        s3_key = data.get('s3_key')  # S3 path where file was uploaded
        
        # Validate required fields
        if not all([document_name, document_type, document_date, family_member_id, s3_key]):
            return jsonify({'error': 'Missing required document information'}), 400
            
        # Validate that the family member belongs to the current user
        family_member = FamilyMember.query.filter_by(
            id=family_member_id, 
            user_id=current_user_id
        ).first()
        
        if not family_member:
            return jsonify({'error': 'Invalid or unauthorized family member'}), 403
            
        # Convert date string to Date object
        try:
            doc_date = datetime.strptime(document_date, '%Y-%m-%d').date()
        except ValueError:
            return jsonify({'error': 'Invalid date format. Use YYYY-MM-DD'}), 400
            
        # Get file size from S3
        # Extract bucket name and object key from s3_key
        if s3_key.startswith('s3://'):
            path_parts = s3_key[5:].split('/', 1)
            bucket_name = path_parts[0]
            object_key = path_parts[1]
            
            try:
                s3_client = S3Utils.get_s3_client()
                response = s3_client.head_object(Bucket=bucket_name, Key=object_key)
                file_size = response.get('ContentLength', 0)
            except Exception as e:
                current_app.logger.error(f"Error getting S3 object metadata: {e}")
                file_size = 0
        else:
            return jsonify({'error': 'Invalid S3 key format'}), 400
            
        # Create new document record
        new_document = MedicalDocument(
            user_id=current_user_id,
            family_member_id=family_member_id,
            document_name=document_name,
            document_type=document_type,
            document_date=doc_date,
            description=description,
            file_path=s3_key,
            file_size=file_size
        )
        
        # Save to database
        db.session.add(new_document)
        db.session.commit()
        
        # Return success response with document ID
        return jsonify({
            'message': 'Document registered successfully',
            'document_id': new_document.id
        }), 201
        
    except Exception as e:
        current_app.logger.error(f"Error registering document: {e}")
        db.session.rollback()  # Roll back in case of error
        return jsonify({'error': f'Error registering document: {str(e)}'}), 500