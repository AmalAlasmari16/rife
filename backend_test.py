import requests
import sys
from datetime import datetime, timedelta
import json

class NurseryConnectAPITester:
    def __init__(self, base_url="https://nursery-bridge.preview.emergentagent.com/api"):
        self.base_url = base_url
        self.worker_token = None
        self.parent_token = None
        self.worker_user = None
        self.parent_user = None
        self.child_id = None
        self.message_group_id = None
        self.event_id = None
        self.file_id = None
        self.payment_id = None
        self.contact_id = None
        self.tests_run = 0
        self.tests_passed = 0

    def run_test(self, name, method, endpoint, expected_status, data=None, token=None, files=None):
        """Run a single API test"""
        url = f"{self.base_url}/{endpoint}"
        headers = {'Content-Type': 'application/json'}
        if token:
            headers['Authorization'] = f'Bearer {token}'
        
        # Remove Content-Type for file uploads
        if files:
            headers.pop('Content-Type', None)

        self.tests_run += 1
        print(f"\n🔍 Testing {name}...")
        print(f"   URL: {url}")
        
        try:
            if method == 'GET':
                response = requests.get(url, headers=headers)
            elif method == 'POST':
                if files:
                    response = requests.post(url, files=files, headers=headers)
                else:
                    response = requests.post(url, json=data, headers=headers)
            elif method == 'PUT':
                response = requests.put(url, json=data, headers=headers)
            elif method == 'DELETE':
                response = requests.delete(url, headers=headers)

            success = response.status_code == expected_status
            if success:
                self.tests_passed += 1
                print(f"✅ Passed - Status: {response.status_code}")
                try:
                    return success, response.json() if response.content else {}
                except:
                    return success, {}
            else:
                print(f"❌ Failed - Expected {expected_status}, got {response.status_code}")
                try:
                    print(f"   Response: {response.json()}")
                except:
                    print(f"   Response: {response.text}")
                return False, {}

        except Exception as e:
            print(f"❌ Failed - Error: {str(e)}")
            return False, {}

    def test_worker_register(self):
        """Test worker registration"""
        timestamp = datetime.now().strftime('%H%M%S')
        success, response = self.run_test(
            "Worker Registration",
            "POST",
            "auth/register",
            200,
            data={
                "email": f"worker_test_{timestamp}@nursery.com",
                "password": "test123",
                "name": f"Test Worker {timestamp}",
                "role": "worker",
                "phone": "1234567890"
            }
        )
        if success:
            self.worker_token = response.get('token')
            self.worker_user = response.get('user')
        return success

    def test_parent_register(self):
        """Test parent registration"""
        timestamp = datetime.now().strftime('%H%M%S')
        success, response = self.run_test(
            "Parent Registration",
            "POST",
            "auth/register",
            200,
            data={
                "email": f"parent_test_{timestamp}@nursery.com",
                "password": "test123",
                "name": f"Test Parent {timestamp}",
                "role": "parent",
                "phone": "0987654321"
            }
        )
        if success:
            self.parent_token = response.get('token')
            self.parent_user = response.get('user')
        return success

    def test_worker_login(self):
        """Test worker login with existing credentials"""
        success, response = self.run_test(
            "Worker Login",
            "POST",
            "auth/login",
            200,
            data={
                "email": "worker@nursery.com",
                "password": "test123"
            }
        )
        if success:
            self.worker_token = response.get('token')
            self.worker_user = response.get('user')
        return success

    def test_parent_login(self):
        """Test parent login with existing credentials"""
        success, response = self.run_test(
            "Parent Login",
            "POST",
            "auth/login",
            200,
            data={
                "email": "parent@nursery.com",
                "password": "test123"
            }
        )
        if success:
            self.parent_token = response.get('token')
            self.parent_user = response.get('user')
        return success

    def test_auth_me(self):
        """Test /auth/me endpoint"""
        success, _ = self.run_test(
            "Auth Me (Worker)",
            "GET",
            "auth/me",
            200,
            token=self.worker_token
        )
        
        success2, _ = self.run_test(
            "Auth Me (Parent)",
            "GET",
            "auth/me",
            200,
            token=self.parent_token
        )
        return success and success2

    def test_create_child(self):
        """Test creating a child"""
        if not self.parent_user:
            print("❌ No parent user available for child creation")
            return False
            
        success, response = self.run_test(
            "Create Child",
            "POST",
            "children",
            200,
            data={
                "name": "Emma Smith",
                "dob": "2021-05-15",
                "parent_id": self.parent_user['id'],
                "notes": "Test child for API testing"
            },
            token=self.worker_token
        )
        if success:
            self.child_id = response.get('id')
        return success

    def test_get_children(self):
        """Test getting children list"""
        success1, _ = self.run_test(
            "Get Children (Worker)",
            "GET",
            "children",
            200,
            token=self.worker_token
        )
        
        success2, _ = self.run_test(
            "Get Children (Parent)",
            "GET",
            "children",
            200,
            token=self.parent_token
        )
        return success1 and success2

    def test_create_activities(self):
        """Test creating activities"""
        if not self.child_id:
            print("❌ No child ID available for activity creation")
            return False
            
        success1, _ = self.run_test(
            "Create Activity - Play",
            "POST",
            "activities",
            200,
            data={
                "child_id": self.child_id,
                "type": "play",
                "description": "Building blocks in playroom",
                "photos": []
            },
            token=self.worker_token
        )
        
        success2, _ = self.run_test(
            "Create Activity - Learning",
            "POST",
            "activities",
            200,
            data={
                "child_id": self.child_id,
                "type": "learning",
                "description": "Learning colors and shapes",
                "photos": []
            },
            token=self.worker_token
        )
        return success1 and success2

    def test_get_activities(self):
        """Test getting activities"""
        if not self.child_id:
            print("❌ No child ID available for getting activities")
            return False
            
        success, _ = self.run_test(
            "Get Activities",
            "GET",
            f"activities/{self.child_id}",
            200,
            token=self.parent_token
        )
        return success

    def test_attendance(self):
        """Test attendance logging"""
        if not self.child_id:
            print("❌ No child ID available for attendance")
            return False
            
        today = datetime.now().strftime('%Y-%m-%d')
        success1, response = self.run_test(
            "Log Check-in",
            "POST",
            "attendance",
            200,
            data={
                "child_id": self.child_id,
                "date": today,
                "check_in": "08:30",
                "notes": "On time arrival"
            },
            token=self.worker_token
        )
        
        attendance_id = response.get('id') if success1 else None
        
        success2 = True
        if attendance_id:
            success2, _ = self.run_test(
                "Update Check-out",
                "PUT",
                f"attendance/{attendance_id}?check_out=16:00",
                200,
                token=self.worker_token
            )
        
        success3, _ = self.run_test(
            "Get Attendance",
            "GET",
            f"attendance/{self.child_id}",
            200,
            token=self.parent_token
        )
        
        return success1 and success2 and success3

    def test_meals(self):
        """Test meal logging"""
        if not self.child_id:
            print("❌ No child ID available for meals")
            return False
            
        today = datetime.now().strftime('%Y-%m-%d')
        success1, _ = self.run_test(
            "Log Meal",
            "POST",
            "meals",
            200,
            data={
                "child_id": self.child_id,
                "date": today,
                "breakfast": "Oatmeal with fruit",
                "lunch": "Chicken and vegetables",
                "snack": "Apple slices"
            },
            token=self.worker_token
        )
        
        success2, _ = self.run_test(
            "Get Meals",
            "GET",
            f"meals/{self.child_id}",
            200,
            token=self.parent_token
        )
        
        return success1 and success2

    def test_messages(self):
        """Test messaging system"""
        if not self.parent_user or not self.worker_user:
            print("❌ Missing user data for messaging")
            return False
            
        # Create message group
        success1, response = self.run_test(
            "Create Message Group",
            "POST",
            "message-groups",
            200,
            data={
                "name": "Parent-Worker Chat",
                "member_ids": [self.parent_user['id'], self.worker_user['id']],
                "type": "direct"
            },
            token=self.worker_token
        )
        
        if success1:
            self.message_group_id = response.get('id')
        
        # Send message
        success2 = True
        if self.message_group_id:
            success2, _ = self.run_test(
                "Send Message",
                "POST",
                "messages",
                200,
                data={
                    "group_id": self.message_group_id,
                    "content": "Hello, this is a test message from worker",
                    "attachments": []
                },
                token=self.worker_token
            )
        
        # Get messages
        success3 = True
        if self.message_group_id:
            success3, _ = self.run_test(
                "Get Messages",
                "GET",
                f"messages/{self.message_group_id}",
                200,
                token=self.parent_token
            )
        
        # Get message groups
        success4, _ = self.run_test(
            "Get Message Groups",
            "GET",
            "message-groups",
            200,
            token=self.parent_token
        )
        
        return success1 and success2 and success3 and success4

    def test_events(self):
        """Test events management"""
        next_week = (datetime.now() + timedelta(days=7)).strftime('%Y-%m-%d')
        
        success1, response = self.run_test(
            "Create Event",
            "POST",
            "events",
            200,
            data={
                "title": "Parent-Teacher Meeting",
                "description": "Monthly parent-teacher meeting",
                "date": next_week,
                "time": "10:00"
            },
            token=self.worker_token
        )
        
        if success1:
            self.event_id = response.get('id')
        
        success2, _ = self.run_test(
            "Get Events",
            "GET",
            "events",
            200,
            token=self.parent_token
        )
        
        success3 = True
        if self.event_id:
            success3, _ = self.run_test(
                "Delete Event",
                "DELETE",
                f"events/{self.event_id}",
                200,
                token=self.worker_token
            )
        
        return success1 and success2 and success3

    def test_files(self):
        """Test file management"""
        # Create a test file
        test_content = b"This is a test file for NurseryConnect"
        
        success1, response = self.run_test(
            "Upload File",
            "POST",
            "files/upload",
            200,
            files={'file': ('test.txt', test_content, 'text/plain')},
            token=self.worker_token
        )
        
        if success1:
            self.file_id = response.get('id')
        
        success2, _ = self.run_test(
            "Get Files",
            "GET",
            "files",
            200,
            token=self.parent_token
        )
        
        success3 = True
        if self.file_id:
            success3, _ = self.run_test(
                "Delete File",
                "DELETE",
                f"files/{self.file_id}",
                200,
                token=self.worker_token
            )
        
        return success1 and success2 and success3

    def test_emergency_contacts(self):
        """Test emergency contacts"""
        if not self.child_id:
            print("❌ No child ID available for emergency contacts")
            return False
            
        success1, response = self.run_test(
            "Add Emergency Contact",
            "POST",
            "emergency-contacts",
            200,
            data={
                "child_id": self.child_id,
                "name": "John Doe",
                "relationship": "Uncle",
                "phone": "555-0123",
                "email": "john.doe@example.com"
            },
            token=self.worker_token
        )
        
        if success1:
            self.contact_id = response.get('id')
        
        success2, _ = self.run_test(
            "Get Emergency Contacts",
            "GET",
            f"emergency-contacts/{self.child_id}",
            200,
            token=self.parent_token
        )
        
        success3 = True
        if self.contact_id:
            success3, _ = self.run_test(
                "Delete Emergency Contact",
                "DELETE",
                f"emergency-contacts/{self.contact_id}",
                200,
                token=self.worker_token
            )
        
        return success1 and success2 and success3

    def test_payments(self):
        """Test payments system"""
        if not self.child_id:
            print("❌ No child ID available for payments")
            return False
            
        next_month = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d')
        
        success1, response = self.run_test(
            "Create Payment",
            "POST",
            "payments",
            200,
            data={
                "child_id": self.child_id,
                "amount": 500.0,
                "due_date": next_month,
                "description": "Monthly Fee",
                "status": "pending"
            },
            token=self.worker_token
        )
        
        if success1:
            self.payment_id = response.get('id')
        
        success2, _ = self.run_test(
            "Get Payments (Parent)",
            "GET",
            "payments",
            200,
            token=self.parent_token
        )
        
        success3, _ = self.run_test(
            "Get Payments (Worker)",
            "GET",
            "payments",
            200,
            token=self.worker_token
        )
        
        success4 = True
        if self.payment_id:
            success4, _ = self.run_test(
                "Update Payment Status",
                "PUT",
                f"payments/{self.payment_id}/status?status=paid",
                200,
                token=self.parent_token
            )
        
        return success1 and success2 and success3 and success4

    def test_stats(self):
        """Test stats endpoint"""
        success1, _ = self.run_test(
            "Get Stats (Parent)",
            "GET",
            "stats",
            200,
            token=self.parent_token
        )
        
        success2, _ = self.run_test(
            "Get Stats (Worker)",
            "GET",
            "stats",
            200,
            token=self.worker_token
        )
        
        return success1 and success2

def main():
    print("🚀 Starting NurseryConnect API Tests...")
    tester = NurseryConnectAPITester()
    
    # Test authentication first
    print("\n" + "="*50)
    print("AUTHENTICATION TESTS")
    print("="*50)
    
    # Try existing users first, then register new ones if needed
    if not tester.test_worker_login():
        if not tester.test_worker_register():
            print("❌ Worker authentication failed, stopping tests")
            return 1
    
    if not tester.test_parent_login():
        if not tester.test_parent_register():
            print("❌ Parent authentication failed, stopping tests")
            return 1
    
    if not tester.test_auth_me():
        print("❌ Auth/me endpoint failed")
        return 1
    
    # Test all other endpoints
    print("\n" + "="*50)
    print("CHILDREN MANAGEMENT TESTS")
    print("="*50)
    tester.test_create_child()
    tester.test_get_children()
    
    print("\n" + "="*50)
    print("ACTIVITIES TESTS")
    print("="*50)
    tester.test_create_activities()
    tester.test_get_activities()
    
    print("\n" + "="*50)
    print("ATTENDANCE TESTS")
    print("="*50)
    tester.test_attendance()
    
    print("\n" + "="*50)
    print("MEALS TESTS")
    print("="*50)
    tester.test_meals()
    
    print("\n" + "="*50)
    print("MESSAGING TESTS")
    print("="*50)
    tester.test_messages()
    
    print("\n" + "="*50)
    print("EVENTS TESTS")
    print("="*50)
    tester.test_events()
    
    print("\n" + "="*50)
    print("FILES TESTS")
    print("="*50)
    tester.test_files()
    
    print("\n" + "="*50)
    print("EMERGENCY CONTACTS TESTS")
    print("="*50)
    tester.test_emergency_contacts()
    
    print("\n" + "="*50)
    print("PAYMENTS TESTS")
    print("="*50)
    tester.test_payments()
    
    print("\n" + "="*50)
    print("STATS TESTS")
    print("="*50)
    tester.test_stats()
    
    # Print final results
    print("\n" + "="*50)
    print("FINAL RESULTS")
    print("="*50)
    print(f"📊 Tests passed: {tester.tests_passed}/{tester.tests_run}")
    
    if tester.tests_passed == tester.tests_run:
        print("🎉 All tests passed!")
        return 0
    else:
        print(f"⚠️  {tester.tests_run - tester.tests_passed} tests failed")
        return 1

if __name__ == "__main__":
    sys.exit(main())