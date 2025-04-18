import os
import boto3
import uuid
from werkzeug.utils import secure_filename
from botocore.exceptions import ClientError
from flask import current_app
from botocore.config import Config

class S3Utils:
    """Utility for handling S3 operations"""
    
    @staticmethod
    def get_s3_client():
        """Get configured S3 client"""
        print(current_app.config['AWS_ACCESS_KEY'])
        print(current_app.config['AWS_SECRET_KEY'])
        print(current_app.config['AWS_REGION'])
        print(current_app.config['S3_BUCKET_NAME'])
        return boto3.client(
            's3',
            aws_access_key_id=current_app.config['AWS_ACCESS_KEY'],
            aws_secret_access_key=current_app.config['AWS_SECRET_KEY'],
            region_name=current_app.config['AWS_REGION'],
            config=Config(signature_version='s3v4'),
        )
    
    @staticmethod
    def upload_file(file_obj, user_id, family_member_id, document_type):
        """
        Upload a file to S3
        
        Args:
            file_obj: File object to upload
            user_id: ID of the user
            family_member_id: ID of the family member
            document_type: Type of document (e.g., prescription, lab_report)
            
        Returns:
            Tuple of (success, file_path or error_message)
        """
        try:
            s3_client = S3Utils.get_s3_client()
            bucket_name = current_app.config['S3_BUCKET_NAME']
            
            # Generate a unique filename
            original_filename = secure_filename(file_obj.filename)
            file_extension = os.path.splitext(original_filename)[1]
            unique_filename = f"{uuid.uuid4()}{file_extension}"
            
            # Create the S3 path (key)
            s3_path = f"documents/user_{user_id}/member_{family_member_id}/{document_type}/{unique_filename}"
            
            # Upload file to S3
            s3_client.upload_fileobj(
                file_obj,
                bucket_name,
                s3_path,
                ExtraArgs={
                    'ContentType': file_obj.content_type
                }
            )
            
            # Generate the URL path
            file_url = f"s3://{bucket_name}/{s3_path}"
            
            return True, file_url
        
        except ClientError as e:
            current_app.logger.error(f"Error uploading to S3: {e}")
            return False, str(e)
        except Exception as e:
            current_app.logger.error(f"Unexpected error: {e}")
            return False, str(e)
    
    @staticmethod
    def generate_presigned_url(file_path, expiration=3600):
        """
        Generate a presigned URL for accessing a document
        
        Args:
            file_path: S3 path for the file (s3://bucket-name/path/to/file)
            expiration: URL expiration time in seconds (default: 1 hour)
            
        Returns:
            Presigned URL string or None if error
        """
        try:
            # Extract bucket name and object key from file path
            if file_path.startswith('s3://'):
                path_parts = file_path[5:].split('/', 1)
                bucket_name = path_parts[0]
                object_key = path_parts[1]
            else:
                return None
                
            s3_client = S3Utils.get_s3_client()
            print(f"Bucket: {bucket_name}, Key: {object_key}")
            
            # Generate the presigned URL
            url = s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': bucket_name,
                    'Key': object_key
                },
                ExpiresIn=expiration
            )
            
            return url
        
        except ClientError as e:
            current_app.logger.error(f"Error generating presigned URL: {e}")
            return None
        except Exception as e:
            current_app.logger.error(f"Unexpected error: {e}")
            return None