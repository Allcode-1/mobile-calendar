from app.db.mongodb import db_instance

def get_db():
    return db_instance.db

def get_collection(name: str):
    return db_instance.db[name]