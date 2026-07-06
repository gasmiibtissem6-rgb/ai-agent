# Phase 1: User, Trust & Identity Management - Testing Guide

## ✅ Implementation Status

### Backend API (NestJS)
- [x] User Directory endpoint with pagination
- [x] Trust Metrics Override endpoint with audit trail
- [x] KYC Review Queue endpoint
- [x] Role-based access control (RBAC)
- [x] DTOs with validation
- [x] Admin action logging

### Frontend Admin Dashboard (Next.js)
- [x] User Directory page with real-time updates
- [x] Trust Metrics adjustment modal
- [x] KYC Queue review page
- [x] Responsive UI with dark mode
- [x] Server-side pagination
- [x] Supabase Realtime integration

---

## 🚀 Testing Workflow

### Prerequisites

1. **Database Running**
   ```bash
   npm run db:up
   npm run db:push
   ```

2. **Backend API Running**
   ```bash
   npm run dev:api
   # API should be running on http://localhost:3001
   ```

3. **Admin Dashboard Running**
   ```bash
   npm run dev:admin
   # Admin dashboard should be running on http://localhost:3000
   ```

4. **Supabase Users Created**
   - Create test users in Supabase Auth dashboard
   - Ensure corresponding profiles exist in the `profiles` table

---

## 🧪 Test Cases

### 1. User Directory Grid

#### Test 1.1: Load User Directory
**Expected Behavior:**
- Admin dashboard displays all users from Supabase
- Shows user profile, role, KYC status, trust metrics
- Pagination works correctly

**Steps:**
1. Navigate to `/admin/users`
2. Verify users are displayed in table format
3. Check that pagination controls appear if total users > 10

**API Endpoint:**
```
GET http://localhost:3001/api/v1/admin/users?page=1&limit=10
Headers:
  Authorization: Bearer <admin_token>
```

**Expected Response:**
```json
{
  "data": {
    "users": [
      {
        "id": "uuid",
        "displayName": "John Doe",
        "email": "john@example.com",
        "kycStatus": "APPROVED",
        "isAdmin": false,
        "adminRole": null,
        "createdAt": "2024-01-01T00:00:00.000Z",
        "trustCounter": {
          "successfulDeals": 5,
          "ongoingDeals": 2,
          "breachedDeals": 0
        }
      }
    ],
    "total": 15,
    "page": 1,
    "limit": 10,
    "totalPages": 2
  }
}
```

#### Test 1.2: Pagination
**Steps:**
1. Click "Next" button
2. Verify page number updates
3. Verify new users are loaded
4. Click specific page number
5. Verify correct page is loaded

#### Test 1.3: Real-time Updates
**Steps:**
1. Keep `/admin/users` page open
2. In Supabase dashboard, update a user's profile
3. Verify the admin dashboard updates automatically (within 2-3 seconds)

**Technical Note:**
The page subscribes to Supabase Realtime channel on `profiles` table changes.

---

### 2. Trust Metrics Override

#### Test 2.1: Open Adjustment Modal
**Steps:**
1. Navigate to `/admin/users`
2. Click "Adjust Metrics" button for any user
3. Verify modal opens with current trust counter values pre-filled

**Expected Behavior:**
- Modal displays user information
- Three counters: Successful, Ongoing, Breached
- Reason textarea (minimum 10 characters required)
- Save button disabled until reason is valid

#### Test 2.2: Increment/Decrement Counters
**Steps:**
1. Click + button on "Successful Deals"
2. Verify counter increases by 1
3. Click - button on "Breached Deals"
4. Verify counter decreases by 1 (minimum 0)
5. Manually type a number in counter input
6. Verify value is validated (no negatives allowed)

#### Test 2.3: Audit Reason Validation
**Steps:**
1. Try to submit with empty reason
2. Verify validation error appears
3. Type 5 characters
4. Verify warning shows "5 more needed"
5. Type 10 characters total
6. Verify checkmark appears

#### Test 2.4: Submit Override
**Steps:**
1. Adjust counters:
   - Successful: 10
   - Ongoing: 3
   - Breached: 1
2. Enter reason: "Resolved dispute - customer fraud case #12345"
3. Click "Save Adjustments"
4. Verify success message appears
5. Verify modal closes after 1.8 seconds
6. Verify user directory refreshes with new values

**API Endpoint:**
```
POST http://localhost:3001/api/v1/admin/users/:profileId/trust-override
Headers:
  Authorization: Bearer <admin_token>
Content-Type: application/json

Body:
{
  "successfulDeals": 10,
  "ongoingDeals": 3,
  "breachedDeals": 1,
  "reason": "Resolved dispute - customer fraud case #12345"
}
```

**Expected Response:**
```json
{
  "data": {
    "id": "counter-uuid",
    "profileId": "user-uuid",
    "successfulDeals": 10,
    "ongoingDeals": 3,
    "breachedDeals": 1,
    "updatedAt": "2024-01-01T00:00:00.000Z"
  }
}
```

#### Test 2.5: Audit Trail Verification
**Steps:**
1. After submitting override
2. Query database directly:
   ```sql
   SELECT * FROM admin_actions 
   WHERE target_resource_type = 'TrustCounter' 
   ORDER BY created_at DESC 
   LIMIT 1;
   ```
3. Verify action is logged with:
   - `adminProfileId`: Current admin's profile ID
   - `actionType`: "ADMIN_ACTION"
   - `reason`: Provided justification
   - `metadataJson`: Contains modifications object

---

### 3. KYC Review Queue

#### Test 3.1: Load Pending KYC Queue
**Steps:**
1. Navigate to `/admin/kyc`
2. Verify pending KYC submissions are displayed
3. Check that only SUBMITTED or UNDER_REVIEW submissions appear

**API Endpoint:**
```
GET http://localhost:3001/api/v1/admin/kyc/pending
Headers:
  Authorization: Bearer <admin_token>
```

**Expected Response:**
```json
{
  "data": [
    {
      "id": "submission-uuid",
      "idType": "PASSPORT",
      "idNumber": "AB123456",
      "documentUrl": "https://...",
      "status": "SUBMITTED",
      "createdAt": "2024-01-01T00:00:00.000Z",
      "profile": {
        "id": "user-uuid",
        "displayName": "Jane Smith",
        "email": "jane@example.com"
      },
      "files": [
        {
          "id": "file-uuid",
          "fileUrl": "https://...",
          "fileType": "KYC_DOCUMENT"
        }
      ]
    }
  ]
}
```

#### Test 3.2: Approve KYC Submission
**Steps:**
1. Click "Approve" button on a submission
2. Verify button shows "Processing..."
3. Wait for API response
4. Verify submission disappears from queue
5. Verify user directory shows updated KYC status: "APPROVED"

**API Endpoint:**
```
PATCH http://localhost:3001/api/v1/admin/kyc/:submissionId/review
Headers:
  Authorization: Bearer <admin_token>
Content-Type: application/json

Body:
{
  "status": "APPROVED"
}
```

#### Test 3.3: Reject KYC Submission
**Steps:**
1. Enter rejection reason in input field
2. Click "Reject" button
3. Verify button shows "Processing..."
4. Wait for API response
5. Verify submission disappears from queue
6. Verify user directory shows updated KYC status: "REJECTED"

**API Endpoint:**
```
PATCH http://localhost:3001/api/v1/admin/kyc/:submissionId/review
Headers:
  Authorization: Bearer <admin_token>
Content-Type: application/json

Body:
{
  "status": "REJECTED",
  "reason": "Document expired - please resubmit valid ID"
}
```

#### Test 3.4: Reject Without Reason (Validation)
**Steps:**
1. Click "Reject" without entering a reason
2. Verify alert appears: "Please provide an administrative reason for rejecting this document verification."
3. Verify no API call is made

---

## 🔐 Authentication & Authorization

### Admin Token Setup

1. **Login as Admin**
   ```
   POST http://localhost:3001/api/v1/auth/login/admin
   Content-Type: application/json

   {
     "email": "admin@ideal.local",
     "password": "ChangeMe123!"
   }
   ```

2. **Store Token**
   ```javascript
   localStorage.setItem('admin_token', response.data.access_token);
   ```

3. **Verify Token Works**
   ```
   GET http://localhost:3001/api/v1/auth/me
   Headers:
     Authorization: Bearer <token>
   ```

### Role-Based Access Control

**Required Roles:**
- `GET /admin/users` - Any admin (isAdmin: true)
- `GET /admin/kyc/pending` - SUPER_ADMIN, ADMIN, SUPPORT_REVIEWER
- `PATCH /admin/kyc/:id/review` - SUPER_ADMIN, ADMIN, SUPPORT_REVIEWER
- `POST /admin/users/:id/trust-override` - SUPER_ADMIN, ADMIN

**Test Unauthorized Access:**
```bash
# Try to access admin endpoint without token
curl http://localhost:3001/api/v1/admin/users

# Expected: 401 Unauthorized
```

```bash
# Try to access admin endpoint with regular user token
curl -H "Authorization: Bearer <user_token>" \
     http://localhost:3001/api/v1/admin/users

# Expected: 403 Forbidden
```

---

## 🐛 Known Issues & Edge Cases

### Issue 1: Empty Trust Counter
**Scenario:** User profile exists but no trust_counter record
**Expected:** Display "0" for all metrics
**Fix:** Backend upserts trust counter on first override

### Issue 2: Realtime Subscription Failure
**Scenario:** Supabase credentials missing from API response
**Expected:** Page still works, but no auto-refresh
**Fix:** Page falls back to manual refresh only

### Issue 3: Pagination with Deleted Users
**Scenario:** User deleted while viewing page 2
**Expected:** Page recalculates totalPages correctly
**Fix:** Backend returns updated total count

---

## 📊 Database Verification Queries

### Check User Profiles
```sql
SELECT 
  id, 
  email, 
  display_name, 
  kyc_status, 
  is_admin, 
  admin_role,
  created_at
FROM profiles
ORDER BY created_at DESC;
```

### Check Trust Counters
```sql
SELECT 
  p.email,
  tc.successful_deals,
  tc.ongoing_deals,
  tc.breached_deals,
  tc.updated_at
FROM trust_counters tc
JOIN profiles p ON tc.profile_id = p.id;
```

### Check Admin Actions Audit Trail
```sql
SELECT 
  aa.action_type,
  aa.target_resource_type,
  aa.reason,
  aa.metadata_json,
  aa.created_at,
  p.email as admin_email
FROM admin_actions aa
JOIN profiles p ON aa.admin_profile_id = p.id
ORDER BY aa.created_at DESC
LIMIT 10;
```

### Check KYC Submissions
```sql
SELECT 
  ks.id,
  ks.status,
  ks.submitted_at,
  ks.reviewed_at,
  ks.rejection_reason,
  p.email as applicant_email,
  reviewer.email as reviewer_email
FROM kyc_submissions ks
JOIN profiles p ON ks.profile_id = p.id
LEFT JOIN profiles reviewer ON ks.reviewed_by_profile_id = reviewer.id
ORDER BY ks.created_at DESC;
```

---

## ✅ Success Criteria

Phase 1 is considered **complete and functional** when:

- [x] ✅ Backend compiles without errors
- [x] ✅ Frontend compiles without errors
- [x] ✅ User directory loads and displays Supabase users
- [x] ✅ Pagination works correctly
- [x] ✅ Realtime updates reflect database changes
- [x] ✅ Trust metrics modal opens and validates input
- [x] ✅ Trust override saves successfully and logs to audit trail
- [x] ✅ KYC queue loads pending submissions
- [x] ✅ KYC approval/rejection updates both submission and profile
- [x] ✅ Role-based access control blocks unauthorized users
- [x] ✅ All API endpoints return proper error messages

---

## 🎯 Next Steps

**Phase 1 Complete!** ✅

Ready to move to Phase 2:
- Deal Creation & Management
- File Upload & Storage
- Notification System
- Advanced Search & Filters

---

## 📝 Notes

- All admin actions are logged to `admin_actions` table for compliance
- Trust counter overrides require minimum 10-character justification
- KYC rejections require explicit reason
- Real-time updates use Supabase Realtime channels
- All endpoints protected with JWT authentication
- Role-based access enforced at controller level
