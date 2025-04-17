from app import create_app, db
import os

app = create_app(os.environ.get('FLASK_CONFIG', 'development'))

def init_db():
    """
    Initialize the database tables. This is a utility function
    to create all tables based on the models. 
    
    For real migrations, use the Flask-Migrate commands:
    - flask db init (first time only)
    - flask db migrate -m "migration message"
    - flask db upgrade
    """
    with app.app_context():
        db.create_all()
        print("Database tables created.")

if __name__ == '__main__':
    init_db()