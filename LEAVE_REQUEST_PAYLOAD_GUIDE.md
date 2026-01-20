# Leave Request Payload Guide

This document explains the payload structure for adding leave requests in the Flutter dashboard application.

## Payload Structure

All leave requests follow this basic structure:

```
user_name=<user_name>&user_id=<user_id>&leave_type=<leave_type>&leaveday=<leaveday>&leaveday1=<leaveday1>&startdate=<startdate>&leavereason=<leavereason>
```

For multi-day leaves, an additional `enddate` parameter is included:

```
user_name=<user_name>&user_id=<user_id>&leave_type=<leave_type>&leaveday=<leaveday>&leaveday1=<leaveday1>&startdate=<startdate>&enddate=<enddate>&leavereason=<leavereason>
```

## Parameters

| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `user_name` | String | Full name of the user | Yes |
| `user_id` | String | Unique identifier for the user | Yes |
| `leave_type` | String | Type of leave: `credit` or `debit` | Yes |
| `leaveday` | String | Leave duration code (see below) | Yes |
| `leaveday1` | String | Leave sub-type code (see below) | Yes |
| `startdate` | String | Start date in YYYY-MM-DD format | Yes |
| `enddate` | String | End date in YYYY-MM-DD format | Only for multi-day leaves |
| `leavereason` | String | Reason for the leave | Yes |

## Leave Type Codes

### leaveday Values
- `hl` - Half Leave
- `fl` - Full Leave  
- `ml` - Multi-day Leave

### leaveday1 Values
- `hl1` - Half Leave First Shift
- `hl2` - Half Leave Second Shift
- `fl1` - Full Day Leave
- `ml1` - Multi-day Leave

## Examples

### 1. Half Day Leave (First Shift)
```
user_name=Sophia first&user_id=3&leave_type=debit&leaveday=hl&leaveday1=hl1&startdate=2025-12-12&leavereason=nothing
```

### 2. Half Day Leave (Second Shift)
```
user_name=Sophia first&user_id=3&leave_type=debit&leaveday=hl&leaveday1=hl2&startdate=2025-12-12&leavereason=personal work
```

### 3. Full Day Leave
```
user_name=Sophia first&user_id=3&leave_type=credit&leaveday=fl&leaveday1=fl1&startdate=2025-12-15&leavereason=medical appointment
```

### 4. Multi-Day Leave
```
user_name=Sophia first&user_id=3&leave_type=debit&leaveday=ml&leaveday1=ml1&startdate=2025-12-01&enddate=2025-12-24&leavereason=nothing
```

## Implementation

The Flutter app uses the `LeaveRequest` model class to structure this data:

```dart
// Half day leave example
final halfDayLeave = LeaveRequest.halfDayLeave(
  userName: 'Sophia first',
  userId: '3',
  leaveType: 'debit',
  shift: 'first', // 'first' or 'second'
  startdate: '2025-12-12',
  leavereason: 'nothing',
);

// Multi-day leave example
final multiDayLeave = LeaveRequest.multiDayLeave(
  userName: 'Sophia first',
  userId: '3',
  leaveType: 'debit',
  startdate: '2025-12-01',
  enddate: '2025-12-24',
  leavereason: 'vacation',
);
```

## API Endpoint

The leave requests are sent to:
```
POST {BASE_URL}/leave_request/add_leave.php
```

With the payload sent as form data (application/x-www-form-urlencoded).

## Shift Information

For half-day leaves:
- **First Shift Leave (hl1)**: Working time 3 PM - 7:30 PM
- **Second Shift Leave (hl2)**: Working time 10 AM - 2:30 PM

## Notes

- All dates must be in YYYY-MM-DD format
- The `enddate` parameter is only required for multi-day leaves (`leaveday=ml`)
- Leave types can be either `credit` (adding leave balance) or `debit` (using leave balance)
- User names should match exactly as stored in the system