# University E-Library Mobile App

A Flutter-based mobile application prototype for university library management, supporting both students and librarians.

## Features

### Student Features (Click & Collect)
- Browse book catalog (Physical & E-Books)
- Search books by title or author
- Book physical books for pickup (24-hour reservation)
- Read E-Books directly in-app
- View active bookings with QR codes
- Track booking history

### Librarian Features (Admin)
- Dashboard with library statistics
- View pending book pickups
- Scan/validate student QR codes
- Process book handovers
- Manage loan records

## Tech Stack

- **Framework:** Flutter (Latest)
- **Language:** Dart
- **State Management:** flutter_riverpod (Notifier API)
- **Navigation:** go_router
- **UI Components:** Google Fonts, Lucide Icons
- **QR Code:** qr_flutter
- **Data Source:** In-Memory Mock Service (1-second simulated delay)

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── enums/          # UserRole, BookType, BookingStatus, LoanStatus
│   ├── models/         # User, Book, Booking, Loan
│   ├── router/         # GoRouter configuration
│   ├── services/       # MockDataService
│   └── theme/          # AppTheme (Navy Blue/Orange)
├── features/
│   ├── auth/           # Authentication provider & login screen
│   ├── books/          # Book list & search providers
│   ├── booking/        # Booking logic with validations
│   ├── loan/           # Loan management (admin)
│   ├── student/        # Student UI screens
│   └── admin/          # Admin UI screens
└── shared/widgets/     # Reusable UI components
```

## Demo Credentials

| Role     | Login Credential          |
|----------|---------------------------|
| Student  | `2021001` or `john@university.edu` |
| Admin    | `jane@university.edu`     |

## Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK
- Android Studio / VS Code
- Android Emulator or iOS Simulator

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd university_elibrary
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## App Flow

### Student Flow
1. Login with student credentials
2. Browse books on Home screen
3. Tap a book to view details
4. For Physical Books: Click "Book Now" to reserve
5. For E-Books: Click "Read Now" to open reader
6. View active bookings in "My Shelf" tab
7. Show QR code to librarian for pickup

### Admin Flow
1. Login with admin credentials
2. View dashboard statistics
3. Click "Scan QR" to process pickups
4. Enter booking ID or scan QR code
5. Validate and confirm handover
6. Loan record is automatically created

## Business Logic

### Booking Validations
- Only physical books can be booked
- Stock must be > 0
- Maximum 3 active bookings per user
- Cannot book the same book twice
- No active fines (mock: always false)

### Booking Lifecycle
1. **Active** - Book reserved, awaiting pickup (24h expiry)
2. **Claimed** - Book handed over, loan created
3. **Expired** - Not picked up within 24 hours

## Screenshots

| Login | Home | Book Detail |
|-------|------|-------------|
| Student/Admin selection | Book catalog | Booking action |

| My Shelf | Admin Dashboard | Scanner |
|----------|-----------------|---------|
| QR codes for pickup | Statistics & pending | Validate & handover |

## Color Scheme

- **Primary:** Navy Blue (#1E3A5F)
- **Secondary:** Orange (#FF6B35)
- **Background:** Off-white (#F8F9FA)
- **Success:** Green (#10B981)
- **Error:** Red (#EF4444)

## License

This project is created for educational purposes.

---

Built with Flutter
