# Calendar Integration Guide

## Overview
The calendar has been updated to work with your API structure and display all the data correctly.

## API Data Structure

Your API returns data in this format:
```json
{
  "success": true,
  "data": {
    "attendance": [],
    "holiday": [
      {
        "id": 132,
        "description": "abc",
        "start": "2024-02-13",
        "backgroundColor": "rgba(255,255,0,0.5)",
        "color": "rgba(255,255,0,0.5)",
        "day": "Tuesday"
      }
    ],
    "leaves": [],
    "employeeLeaves": [
      {
        "date": "2025-12-10",
        "leave_info": [
          {
            "name": "William White",
            "leavereason": "hospitality",
            "leaveday": "ml",
            "leave_count": 0
          }
        ]
      }
    ],
    "birthdays": [
      {
        "first_name": "Colin",
        "last_name": "Wise",
        "birthdate": "12-04",
        "day": "Thursday",
        "dp": {...},
        "user_id": 554
      }
    ]
  }
}
```

## Features Implemented

### 1. Birthday Display
- Format: `"MM-DD"` (e.g., "12-04" for December 4th)
- Shows a small pink dot at the bottom of the date
- Pink background tint on birthday dates
- Tooltip shows: "🎂 [Name]'s birthday"

### 2. Holiday Display
- Format: Full date `"YYYY-MM-DD"`
- Red text color for holiday dates
- Tooltip shows: "🎉 [Holiday Description]"

### 3. Employee Leaves
- Format: Full date `"YYYY-MM-DD"`
- Orange background tint
- Orange dot indicator below the date
- Tooltip shows:
  - Employee name
  - Leave count (if not 0)
  - Leave type (ML, FL, HL1, HL2)
  - Leave reason

### 4. Attendance
- Tracks work hours
- Red dot indicator for short attendance (< 8.5 hours)
- Tooltip shows: "⚠️ Less Attendance"

## Visual Indicators

| Indicator | Meaning |
|-----------|---------|
| 🟢 Green circle with shadow | Today |
| 🩷 Pink background | Birthday |
| 🟠 Orange background | Employee leave |
| 🔴 Red background | Short attendance |
| 🔴 Red text | Weekend or Holiday |
| 🟣 Small pink dot | Birthday indicator |
| 🟠 Small orange dot | Leave indicator |
| 🔴 Small red dot | Short attendance indicator |

## Usage

### Basic Usage
```dart
TestCalender(
  birthdays: calendarData['birthdays'],
  holidays: calendarData['holiday'],
  leaves: calendarData['leaves'],
  attendance: calendarData['attendance'],
  employeeLeaves: calendarData['employeeLeaves'],
  isAdmin: false,
)
```

### With API Integration
```dart
// See calendar_demo_screen.dart for full example
final response = await GeneralCalendarService.getGeneralCalendarData();
if (response != null && response['success'] == true) {
  final data = response['data'];
  // Pass data to TestCalender widget
}
```

## Files Modified

1. **lib/screens/test_calender.dart**
   - Updated birthday parsing to handle "MM-DD" format
   - Added employee leave info extraction
   - Enhanced tooltip messages with detailed leave information
   - Improved visual styling

2. **lib/screens/calendar_demo_screen.dart**
   - Integrated with GeneralCalendarService
   - Added loading states
   - Added error handling
   - Shows data statistics

3. **lib/services/general_calendar_service.dart**
   - Already configured to fetch calendar data from API

## Testing

Run the calendar demo screen:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CalendarDemoScreen(),
  ),
);
```

## Customization

### Change Colors
Edit the color values in `_buildDateCell()` method:
```dart
// Birthday color
backgroundColor = Colors.pink[50];

// Leave color
backgroundColor = Colors.orange[50];

// Short attendance color
backgroundColor = Colors.red[50];
```

### Modify Tooltip Content
Edit the `_buildTooltipMessage()` method to customize what information is shown.

### Adjust Date Cell Size
Modify the width and height in `_buildDateCell()`:
```dart
Container(
  width: 44,  // Change this
  height: 44, // Change this
  ...
)
```

## Notes

- The calendar automatically handles month navigation
- Weekends (Saturday/Sunday) are displayed in red
- Dates outside the current month are shown in gray
- All tooltips show on hover/tap
- The legend is hidden for admin users (set `isAdmin: true`)

## Troubleshooting

### Birthdays not showing?
- Check the date format is "MM-DD" (e.g., "12-25")
- Verify the API response contains the `birthdays` array

### Employee leaves not displaying?
- Ensure the date format is "YYYY-MM-DD"
- Check that `leave_info` array exists in the data

### Holidays not appearing?
- Verify the `start` date format is "YYYY-MM-DD"
- Check the `holiday` array in API response

## Support

For issues or questions, check:
1. Console logs in the service file
2. API response structure
3. Date format consistency
