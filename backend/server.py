from fastapi import FastAPI, APIRouter, HTTPException, Depends, status, UploadFile, File
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field, ConfigDict, EmailStr
from typing import List, Optional
import uuid
from datetime import datetime, timezone, timedelta
import bcrypt
import jwt
import base64

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# JWT Configuration
JWT_SECRET = os.environ.get('JWT_SECRET', 'your-secret-key-change-in-production')
JWT_ALGORITHM = 'HS256'
JWT_EXPIRATION_DAYS = 30

# Create the main app
app = FastAPI()
api_router = APIRouter(prefix="/api")
security = HTTPBearer()

# ============ MODELS ============

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str
    role: str  # 'parent' or 'worker'
    phone: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class User(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str
    email: str
    name: str
    role: str
    phone: Optional[str] = None
    profile_pic: Optional[str] = None

class AuthResponse(BaseModel):
    token: str
    user: User

class ChildCreate(BaseModel):
    name: str
    dob: str
    parent_id: str
    photo: Optional[str] = None
    notes: Optional[str] = None

class Child(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str
    name: str
    dob: str
    parent_id: str
    photo: Optional[str] = None
    notes: Optional[str] = None
    created_at: str

class ActivityCreate(BaseModel):
    child_id: str
    type: str  # 'play', 'learning', 'nap', 'outdoor', 'art'
    description: str
    photos: Optional[List[str]] = []
    timestamp: Optional[str] = None

class Activity(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str
    child_id: str
    type: str
    description: str
    photos: List[str]
    worker_id: str
    timestamp: str

class AttendanceCreate(BaseModel):
    child_id: str
    date: str
    check_in: str
    check_out: Optional[str] = None
    notes: Optional[str] = None

class Attendance(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str
    child_id: str
    date: str
    check_in: str
    check_out: Optional[str] = None
    notes: Optional[str] = None

class MealCreate(BaseModel):
    child_id: str
    date: str
    breakfast: Optional[str] = None
    lunch: Optional[str] = None
    snack: Optional[str] = None
    notes: Optional[str] = None

class Meal(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str
    child_id: str
    date: str
    breakfast: Optional[str] = None
    lunch: Optional[str] = None
    snack: Optional[str] = None
    notes: Optional[str] = None

class MessageCreate(BaseModel):
    group_id: str
    content: str
    attachments: Optional[List[str]] = []

class Message(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str
    group_id: str
    sender_id: str
    sender_name: str
    content: str
    attachments: List[str]
    timestamp: str

class MessageGroupCreate(BaseModel):
    name: str
    member_ids: List[str]
    type: str  # 'group' or 'direct'

class MessageGroup(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str
    name: str
    member_ids: List[str]
    type: str
    created_at: str

class EventCreate(BaseModel):
    title: str
    description: str
    date: str
    time: Optional[str] = None

class Event(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str
    title: str
    description: str
    date: str
    time: Optional[str] = None
    created_by: str
    created_at: str

class FileUploadResponse(BaseModel):
    id: str
    name: str
    url: str
    category: str
    uploaded_by: str
    created_at: str

class PaymentCreate(BaseModel):
    child_id: str
    amount: float
    due_date: str
    description: str
    status: str = 'pending'  # 'pending', 'paid', 'overdue'

class Payment(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str
    child_id: str
    amount: float
    due_date: str
    description: str
    status: str
    created_at: str

class EmergencyContactCreate(BaseModel):
    child_id: str
    name: str
    relationship: str
    phone: str
    email: Optional[str] = None

class EmergencyContact(BaseModel):
    model_config = ConfigDict(extra="ignore")
    id: str
    child_id: str
    name: str
    relationship: str
    phone: str
    email: Optional[str] = None

# ============ AUTH UTILITIES ============

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))

def create_token(user_id: str) -> str:
    payload = {
        'user_id': user_id,
        'exp': datetime.now(timezone.utc) + timedelta(days=JWT_EXPIRATION_DAYS)
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    token = credentials.credentials
    payload = decode_token(token)
    user_id = payload.get('user_id')
    
    user = await db.users.find_one({'id': user_id}, {'_id': 0})
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    
    return user

# ============ AUTH ROUTES ============

@api_router.post("/auth/register", response_model=AuthResponse)
async def register(user_data: UserCreate):
    existing_user = await db.users.find_one({'email': user_data.email}, {'_id': 0})
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    user_id = str(uuid.uuid4())
    hashed_pw = hash_password(user_data.password)
    
    user_doc = {
        'id': user_id,
        'email': user_data.email,
        'password': hashed_pw,
        'name': user_data.name,
        'role': user_data.role,
        'phone': user_data.phone,
        'profile_pic': None,
        'created_at': datetime.now(timezone.utc).isoformat()
    }
    
    await db.users.insert_one(user_doc)
    
    token = create_token(user_id)
    user = User(**{k: v for k, v in user_doc.items() if k != 'password'})
    
    return AuthResponse(token=token, user=user)

@api_router.post("/auth/login", response_model=AuthResponse)
async def login(credentials: UserLogin):
    user = await db.users.find_one({'email': credentials.email}, {'_id': 0})
    if not user or not verify_password(credentials.password, user['password']):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    token = create_token(user['id'])
    user_response = User(**{k: v for k, v in user.items() if k != 'password'})
    
    return AuthResponse(token=token, user=user_response)

@api_router.get("/auth/me", response_model=User)
async def get_me(current_user: dict = Depends(get_current_user)):
    return User(**{k: v for k, v in current_user.items() if k != 'password'})

# ============ CHILDREN ROUTES ============

@api_router.post("/children", response_model=Child)
async def create_child(child_data: ChildCreate, current_user: dict = Depends(get_current_user)):
    child_id = str(uuid.uuid4())
    child_doc = {
        'id': child_id,
        **child_data.model_dump(),
        'created_at': datetime.now(timezone.utc).isoformat()
    }
    
    await db.children.insert_one(child_doc)
    return Child(**{k: v for k, v in child_doc.items() if k != '_id'})

@api_router.get("/children", response_model=List[Child])
async def get_children(current_user: dict = Depends(get_current_user)):
    query = {}
    if current_user['role'] == 'parent':
        query['parent_id'] = current_user['id']
    
    children = await db.children.find(query, {'_id': 0}).to_list(100)
    return [Child(**child) for child in children]

@api_router.get("/children/{child_id}", response_model=Child)
async def get_child(child_id: str, current_user: dict = Depends(get_current_user)):
    child = await db.children.find_one({'id': child_id}, {'_id': 0})
    if not child:
        raise HTTPException(status_code=404, detail="Child not found")
    
    if current_user['role'] == 'parent' and child['parent_id'] != current_user['id']:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    return Child(**child)

# ============ ACTIVITIES ROUTES ============

@api_router.post("/activities", response_model=Activity)
async def create_activity(activity_data: ActivityCreate, current_user: dict = Depends(get_current_user)):
    if current_user['role'] != 'worker':
        raise HTTPException(status_code=403, detail="Only workers can create activities")
    
    activity_id = str(uuid.uuid4())
    activity_doc = {
        'id': activity_id,
        **activity_data.model_dump(),
        'worker_id': current_user['id'],
        'timestamp': activity_data.timestamp or datetime.now(timezone.utc).isoformat()
    }
    
    await db.activities.insert_one(activity_doc)
    return Activity(**{k: v for k, v in activity_doc.items() if k != '_id'})

@api_router.get("/activities/{child_id}", response_model=List[Activity])
async def get_activities(child_id: str, current_user: dict = Depends(get_current_user)):
    activities = await db.activities.find({'child_id': child_id}, {'_id': 0}).sort('timestamp', -1).to_list(100)
    return [Activity(**activity) for activity in activities]

# ============ ATTENDANCE ROUTES ============

@api_router.post("/attendance", response_model=Attendance)
async def create_attendance(attendance_data: AttendanceCreate, current_user: dict = Depends(get_current_user)):
    if current_user['role'] != 'worker':
        raise HTTPException(status_code=403, detail="Only workers can log attendance")
    
    attendance_id = str(uuid.uuid4())
    attendance_doc = {
        'id': attendance_id,
        **attendance_data.model_dump()
    }
    
    await db.attendance.insert_one(attendance_doc)
    return Attendance(**{k: v for k, v in attendance_doc.items() if k != '_id'})

@api_router.get("/attendance/{child_id}", response_model=List[Attendance])
async def get_attendance(child_id: str, current_user: dict = Depends(get_current_user)):
    records = await db.attendance.find({'child_id': child_id}, {'_id': 0}).sort('date', -1).to_list(100)
    return [Attendance(**record) for record in records]

@api_router.put("/attendance/{attendance_id}", response_model=Attendance)
async def update_attendance(attendance_id: str, check_out: str, current_user: dict = Depends(get_current_user)):
    if current_user['role'] != 'worker':
        raise HTTPException(status_code=403, detail="Only workers can update attendance")
    
    result = await db.attendance.update_one(
        {'id': attendance_id},
        {'$set': {'check_out': check_out}}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Attendance record not found")
    
    updated = await db.attendance.find_one({'id': attendance_id}, {'_id': 0})
    return Attendance(**updated)

# ============ MEALS ROUTES ============

@api_router.post("/meals", response_model=Meal)
async def create_meal(meal_data: MealCreate, current_user: dict = Depends(get_current_user)):
    if current_user['role'] != 'worker':
        raise HTTPException(status_code=403, detail="Only workers can log meals")
    
    meal_id = str(uuid.uuid4())
    meal_doc = {
        'id': meal_id,
        **meal_data.model_dump()
    }
    
    await db.meals.insert_one(meal_doc)
    return Meal(**{k: v for k, v in meal_doc.items() if k != '_id'})

@api_router.get("/meals/{child_id}", response_model=List[Meal])
async def get_meals(child_id: str, current_user: dict = Depends(get_current_user)):
    meals = await db.meals.find({'child_id': child_id}, {'_id': 0}).sort('date', -1).to_list(100)
    return [Meal(**meal) for meal in meals]

# ============ MESSAGES ROUTES ============

@api_router.post("/message-groups", response_model=MessageGroup)
async def create_message_group(group_data: MessageGroupCreate, current_user: dict = Depends(get_current_user)):
    group_id = str(uuid.uuid4())
    group_doc = {
        'id': group_id,
        **group_data.model_dump(),
        'created_at': datetime.now(timezone.utc).isoformat()
    }
    
    await db.message_groups.insert_one(group_doc)
    return MessageGroup(**{k: v for k, v in group_doc.items() if k != '_id'})

@api_router.get("/message-groups", response_model=List[MessageGroup])
async def get_message_groups(current_user: dict = Depends(get_current_user)):
    groups = await db.message_groups.find(
        {'member_ids': current_user['id']},
        {'_id': 0}
    ).to_list(100)
    return [MessageGroup(**group) for group in groups]

@api_router.post("/messages", response_model=Message)
async def create_message(message_data: MessageCreate, current_user: dict = Depends(get_current_user)):
    message_id = str(uuid.uuid4())
    message_doc = {
        'id': message_id,
        **message_data.model_dump(),
        'sender_id': current_user['id'],
        'sender_name': current_user['name'],
        'timestamp': datetime.now(timezone.utc).isoformat()
    }
    
    await db.messages.insert_one(message_doc)
    return Message(**{k: v for k, v in message_doc.items() if k != '_id'})

@api_router.get("/messages/{group_id}", response_model=List[Message])
async def get_messages(group_id: str, current_user: dict = Depends(get_current_user)):
    messages = await db.messages.find(
        {'group_id': group_id},
        {'_id': 0}
    ).sort('timestamp', 1).to_list(500)
    return [Message(**message) for message in messages]

# ============ EVENTS ROUTES ============

@api_router.post("/events", response_model=Event)
async def create_event(event_data: EventCreate, current_user: dict = Depends(get_current_user)):
    if current_user['role'] != 'worker':
        raise HTTPException(status_code=403, detail="Only workers can create events")
    
    event_id = str(uuid.uuid4())
    event_doc = {
        'id': event_id,
        **event_data.model_dump(),
        'created_by': current_user['id'],
        'created_at': datetime.now(timezone.utc).isoformat()
    }
    
    await db.events.insert_one(event_doc)
    return Event(**{k: v for k, v in event_doc.items() if k != '_id'})

@api_router.get("/events", response_model=List[Event])
async def get_events(current_user: dict = Depends(get_current_user)):
    events = await db.events.find({}, {'_id': 0}).sort('date', 1).to_list(100)
    return [Event(**event) for event in events]

@api_router.delete("/events/{event_id}")
async def delete_event(event_id: str, current_user: dict = Depends(get_current_user)):
    if current_user['role'] != 'worker':
        raise HTTPException(status_code=403, detail="Only workers can delete events")
    
    result = await db.events.delete_one({'id': event_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Event not found")
    
    return {'message': 'Event deleted'}

# ============ FILES ROUTES ============

@api_router.post("/files/upload", response_model=FileUploadResponse)
async def upload_file(
    file: UploadFile = File(...),
    category: str = 'general',
    current_user: dict = Depends(get_current_user)
):
    # Read file and convert to base64 for simple storage
    contents = await file.read()
    base64_content = base64.b64encode(contents).decode('utf-8')
    
    file_id = str(uuid.uuid4())
    file_doc = {
        'id': file_id,
        'name': file.filename,
        'content': base64_content,
        'content_type': file.content_type,
        'category': category,
        'uploaded_by': current_user['id'],
        'created_at': datetime.now(timezone.utc).isoformat()
    }
    
    await db.files.insert_one(file_doc)
    
    return FileUploadResponse(
        id=file_id,
        name=file.filename,
        url=f"/api/files/{file_id}",
        category=category,
        uploaded_by=current_user['name'],
        created_at=file_doc['created_at']
    )

@api_router.get("/files", response_model=List[FileUploadResponse])
async def get_files(current_user: dict = Depends(get_current_user)):
    files = await db.files.find({}, {'_id': 0, 'content': 0}).sort('created_at', -1).to_list(100)
    
    # Get uploader names
    result = []
    for file_doc in files:
        uploader = await db.users.find_one({'id': file_doc['uploaded_by']}, {'_id': 0, 'name': 1})
        result.append(FileUploadResponse(
            id=file_doc['id'],
            name=file_doc['name'],
            url=f"/api/files/{file_doc['id']}",
            category=file_doc['category'],
            uploaded_by=uploader['name'] if uploader else 'Unknown',
            created_at=file_doc['created_at']
        ))
    
    return result

@api_router.delete("/files/{file_id}")
async def delete_file(file_id: str, current_user: dict = Depends(get_current_user)):
    result = await db.files.delete_one({'id': file_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="File not found")
    
    return {'message': 'File deleted'}

# ============ PAYMENTS ROUTES ============

@api_router.post("/payments", response_model=Payment)
async def create_payment(payment_data: PaymentCreate, current_user: dict = Depends(get_current_user)):
    if current_user['role'] != 'worker':
        raise HTTPException(status_code=403, detail="Only workers can create payments")
    
    payment_id = str(uuid.uuid4())
    payment_doc = {
        'id': payment_id,
        **payment_data.model_dump(),
        'created_at': datetime.now(timezone.utc).isoformat()
    }
    
    await db.payments.insert_one(payment_doc)
    return Payment(**{k: v for k, v in payment_doc.items() if k != '_id'})

@api_router.get("/payments", response_model=List[Payment])
async def get_payments(current_user: dict = Depends(get_current_user)):
    query = {}
    
    if current_user['role'] == 'parent':
        # Get children for this parent
        children = await db.children.find({'parent_id': current_user['id']}, {'_id': 0, 'id': 1}).to_list(100)
        child_ids = [child['id'] for child in children]
        query['child_id'] = {'$in': child_ids}
    
    payments = await db.payments.find(query, {'_id': 0}).sort('due_date', 1).to_list(100)
    return [Payment(**payment) for payment in payments]

@api_router.put("/payments/{payment_id}/status")
async def update_payment_status(payment_id: str, status: str, current_user: dict = Depends(get_current_user)):
    result = await db.payments.update_one(
        {'id': payment_id},
        {'$set': {'status': status}}
    )
    
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    return {'message': 'Payment status updated'}

# ============ EMERGENCY CONTACTS ROUTES ============

@api_router.post("/emergency-contacts", response_model=EmergencyContact)
async def create_emergency_contact(contact_data: EmergencyContactCreate, current_user: dict = Depends(get_current_user)):
    contact_id = str(uuid.uuid4())
    contact_doc = {
        'id': contact_id,
        **contact_data.model_dump()
    }
    
    await db.emergency_contacts.insert_one(contact_doc)
    return EmergencyContact(**{k: v for k, v in contact_doc.items() if k != '_id'})

@api_router.get("/emergency-contacts/{child_id}", response_model=List[EmergencyContact])
async def get_emergency_contacts(child_id: str, current_user: dict = Depends(get_current_user)):
    contacts = await db.emergency_contacts.find({'child_id': child_id}, {'_id': 0}).to_list(100)
    return [EmergencyContact(**contact) for contact in contacts]

@api_router.delete("/emergency-contacts/{contact_id}")
async def delete_emergency_contact(contact_id: str, current_user: dict = Depends(get_current_user)):
    result = await db.emergency_contacts.delete_one({'id': contact_id})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Contact not found")
    
    return {'message': 'Contact deleted'}

# ============ STATS ROUTE ============

@api_router.get("/stats")
async def get_stats(current_user: dict = Depends(get_current_user)):
    if current_user['role'] == 'parent':
        children = await db.children.find({'parent_id': current_user['id']}, {'_id': 0}).to_list(100)
        child_ids = [child['id'] for child in children]
        
        activities_count = await db.activities.count_documents({'child_id': {'$in': child_ids}})
        messages_count = 0  # Calculate based on groups
        
        return {
            'children_count': len(children),
            'activities_count': activities_count,
            'messages_count': messages_count
        }
    else:
        children_count = await db.children.count_documents({})
        activities_count = await db.activities.count_documents({})
        events_count = await db.events.count_documents({})
        
        return {
            'children_count': children_count,
            'activities_count': activities_count,
            'events_count': events_count
        }

# Include the router
app.include_router(api_router)

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
    allow_methods=["*"],
    allow_headers=["*"],
)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()