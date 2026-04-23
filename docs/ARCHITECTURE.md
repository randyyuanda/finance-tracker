# FinTrack – Architecture Overview

FinTrack is a full-stack personal finance tracker with three separate layers:

| Layer | Stack | Hosting |
|---|---|---|
| **Backend** | Node.js · Express · Prisma · PostgreSQL | Vercel (Serverless) |
| **Frontend** | React 18 · Ant Design · Vite | Vercel |
| **Mobile** | Flutter 3 · Provider · Dio | APK sideload / Play Store |

---

## Backend (`/backend`)

### Tech Stack
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **ORM**: Prisma (PostgreSQL via Neon/Vercel Postgres)
- **Auth**: JWT (jsonwebtoken) + bcrypt
- **Hosting**: Vercel Serverless Functions

### Folder Structure
```
backend/
├── prisma/
│   └── schema.prisma          # DB models
├── src/
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── accountController.js
│   │   ├── transactionController.js
│   │   ├── categoryController.js
│   │   ├── goalController.js
│   │   ├── recurringController.js
│   │   ├── reminderController.js
│   │   ├── dashboardController.js
│   │   ├── adminController.js
│   │   └── notificationController.js
│   ├── routes/
│   │   ├── auth.js
│   │   ├── accounts.js
│   │   ├── transactions.js
│   │   ├── categories.js
│   │   ├── goals.js
│   │   ├── recurring.js
│   │   ├── reminders.js
│   │   ├── dashboard.js
│   │   ├── admin.js
│   │   └── notifications.js
│   ├── middleware/
│   │   └── auth.js            # JWT verify middleware
│   └── server.js              # Express app entry point
└── vercel.json
```

### Database Models (Prisma)
| Model | Key Fields |
|---|---|
| `User` | id, name, email, password, role (user/superadmin), avatar |
| `Account` | id, userId, name, type, balance, currency, color, icon |
| `Category` | id, userId, name, type (income/expense), color, icon |
| `Transaction` | id, accountId, categoryId, amount, type, date, note |
| `Goal` | id, userId, name, targetAmount, currentAmount, deadline |
| `RecurringTransaction` | id, accountId, categoryId, type, amount, frequency, nextDue, isActive |
| `Reminder` | id, userId, title, note, reminderDate, type, repeatType, isCompleted |
| `AdminNotification` | id, userId, title, note, scheduledAt, repeatType, isRead |

### API Endpoints
| Method | Path | Description |
|---|---|---|
| POST | `/api/auth/login` | Login, returns JWT |
| POST | `/api/auth/register` | Register |
| GET | `/api/auth/me` | Current user |
| PUT | `/api/auth/profile` | Update name/avatar |
| GET/POST | `/api/accounts` | List / create accounts |
| PATCH/DELETE | `/api/accounts/:id` | Update / delete account |
| GET/POST | `/api/transactions` | List (paginated) / create |
| DELETE | `/api/transactions/:id` | Delete transaction |
| GET | `/api/categories` | List categories (filterable by type) |
| GET/POST | `/api/goals` | List / create goals |
| PATCH/DELETE | `/api/goals/:id` | Update / delete goal |
| GET/POST | `/api/recurring` | List / create recurring |
| PATCH | `/api/recurring/:id` | Toggle active |
| GET/POST | `/api/reminders` | List / create reminders |
| PATCH | `/api/reminders/:id` | Update reminder |
| PATCH | `/api/reminders/:id/complete` | Toggle complete |
| DELETE | `/api/reminders/:id` | Delete reminder |
| GET | `/api/dashboard` | Stats + recent transactions + accounts |
| POST | `/api/admin/broadcast` | Superadmin: broadcast notification |
| GET | `/api/admin/stats` | Superadmin: user/transaction stats |
| GET | `/api/admin/users` | Superadmin: user list |
| GET | `/api/notifications/admin` | User: fetch unread admin broadcasts |

### Auth Flow
1. Client posts credentials → `authController.login`
2. bcrypt compares password → sign JWT (24h expiry)
3. Token stored in `localStorage` (web) or `SharedPreferences` (mobile)
4. All protected routes use `authMiddleware` which verifies JWT and attaches `req.user`

### Superadmin Broadcasts
1. Superadmin creates broadcast via `POST /api/admin/broadcast` with `{ title, scheduledAt, repeatType, note }`
2. Backend creates one `AdminNotification` record per active user
3. Mobile app fetches `/api/notifications/admin` on login/startup
4. Unread one-time notifications are auto-marked read; repeating stay unread perpetually
5. Mobile schedules OS push notification for each one

---

## Frontend (`/frontend`)

### Tech Stack
- **Framework**: React 18
- **UI Library**: Ant Design 5
- **Charts**: Ant Design Charts / Recharts
- **HTTP Client**: Axios
- **State**: React hooks (no global state library)
- **Build**: Vite

### Folder Structure
```
frontend/
├── src/
│   ├── api/
│   │   └── axios.js           # Axios instance with auth interceptor
│   ├── hooks/
│   │   ├── useAuth.js
│   │   └── useReminderNotifications.js  # Browser push polling
│   ├── pages/
│   │   ├── Login.jsx
│   │   ├── Register.jsx
│   │   ├── Dashboard.jsx      # Charts + summary
│   │   ├── Transactions.jsx
│   │   ├── Accounts.jsx
│   │   ├── Categories.jsx
│   │   ├── Goals.jsx
│   │   ├── Reminders.jsx
│   │   ├── Recurring.jsx
│   │   ├── Reports.jsx
│   │   ├── Settings.jsx
│   │   └── Admin.jsx          # Superadmin dashboard
│   ├── components/
│   │   └── Layout.jsx         # Sidebar + header shell
│   └── main.jsx
└── vite.config.js
```

### Key Pages
| Page | Features |
|---|---|
| Dashboard | Total balance, monthly income/expense, charts, recent transactions |
| Transactions | CRUD with date/type/account filters, pagination |
| Accounts | CRUD, balance history, icon/color picker, supports negative balance |
| Categories | Custom income/expense categories with color coding |
| Goals | Savings goals with progress bars |
| Reminders | Browser notifications, overdue badge, repeat types |
| Reports | Monthly/yearly reports, download CSV/PDF |
| Admin | Superadmin only: user list, broadcast notifications, system stats |

### Browser Notifications (Reminders + Admin)
- `useReminderNotifications` hook polls every minute
- For reminders: checks `reminderDate` within the current minute
- For admin broadcasts: polls `/api/notifications/admin`, fires `Notification` API popup
- Deduplication via minute-bucket key stored in session

---

## Mobile (`/mobile`)

### Tech Stack
- **Framework**: Flutter 3.41+
- **State Management**: Provider (ChangeNotifier)
- **HTTP**: Dio (with auth interceptor)
- **Notifications**: flutter_local_notifications + timezone
- **Storage**: SharedPreferences
- **Charts**: fl_chart
- **Image**: image_picker
- **Export**: share_plus + path_provider

### Folder Structure
```
mobile/lib/
├── core/
│   ├── api.dart               # Dio client, base URL, auth interceptor
│   ├── storage.dart           # SharedPreferences wrapper (token, theme, avatar, language)
│   ├── notifications.dart     # OS notification scheduling (reminders + admin broadcasts)
│   ├── theme.dart             # Light/dark Material 3 themes
│   └── formatters.dart        # Currency (IDR), date, relative time formatters
├── models/
│   ├── user.dart
│   ├── account.dart
│   ├── transaction.dart
│   ├── category.dart
│   ├── goal.dart
│   ├── reminder.dart
│   └── recurring_transaction.dart
├── providers/
│   ├── auth_provider.dart     # Login, register, logout, profile update
│   ├── account_provider.dart  # Account CRUD
│   ├── category_provider.dart # Category fetch (income/expense filtered)
│   ├── transaction_provider.dart # Paginated transaction list, create, delete
│   ├── dashboard_provider.dart   # Stats + recent transactions + accounts
│   ├── goal_provider.dart     # Goal CRUD
│   ├── recurring_provider.dart # Recurring list + toggle
│   ├── reminder_provider.dart # Reminder CRUD + OS notification scheduling
│   └── theme_provider.dart    # ThemeMode + language, persisted
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart  # Charts: income/expense pie, 7-day bar
│   ├── transactions/
│   │   ├── transactions_screen.dart
│   │   └── add_transaction_screen.dart
│   ├── accounts/
│   │   └── accounts_screen.dart
│   ├── goals/
│   │   └── goals_screen.dart
│   ├── reminders/
│   │   └── reminders_screen.dart
│   ├── recurring/
│   │   └── recurring_screen.dart
│   ├── reports/
│   │   └── reports_screen.dart   # Monthly report + category pie + CSV export
│   ├── settings/
│   │   └── settings_screen.dart  # Profile image, theme, language
│   ├── more/
│   │   └── more_screen.dart
│   └── home_screen.dart           # Bottom nav (5 tabs)
├── widgets/
│   ├── transaction_tile.dart
│   ├── stat_card.dart
│   └── empty_state.dart
└── main.dart                      # App entry, MultiProvider, slideRoute/fadeRoute helpers
```

### Navigation & Transitions
- Tab-based navigation: `IndexedStack` with 5 bottom nav tabs (Dashboard, Transactions, Goals, Reminders, More)
- Page push transitions: `slideRoute()` (slide from right) and `fadeRoute()` (fade in) defined in `main.dart`
- All `Navigator.push` calls use `slideRoute` instead of `MaterialPageRoute`

### Notifications
| Type | Source | Behaviour |
|---|---|---|
| Reminder | User-created | Scheduled exact alarm at `reminderDate` |
| Admin Broadcast (one-time) | Superadmin | If past → fires in 5s; future → scheduled |
| Admin Broadcast (repeating) | Superadmin | OS reschedules at next occurrence (daily/weekly/monthly) |

### Theme & Language
- `ThemeProvider` exposes `themeMode` (light/dark/system) and `language` (en/id)
- Both persisted via `SharedPreferences` through `Storage`
- Changing theme takes effect immediately via `MaterialApp.themeMode`

### API Base URL
```
https://fintech-api-randyyuandas-projects.vercel.app/api
```

---

## Deployment

### Backend
- Auto-deployed to Vercel on push to `main`
- Project: `fintech-api` in `randyyuandas-projects`
- Stable production URL: `https://fintech-api-randyyuandas-projects.vercel.app`
- Environment variables set in Vercel dashboard: `DATABASE_URL`, `JWT_SECRET`

### Frontend
- Auto-deployed to Vercel on push to `main`
- Environment variable: `VITE_API_URL` pointing to backend

### Mobile
- Build: `flutter build apk --release` in `mobile/`
- Install on device: `adb install build/app/outputs/flutter-apk/app-release.apk`
- Wireless debug: ADB pair via IP from Developer Options → Wireless debugging

---

## Key Design Decisions

1. **No Redux/Riverpod** – Provider is sufficient for this scale; each screen reads only the providers it needs
2. **Local avatar storage** – Profile photos stored in device filesystem (path in SharedPreferences); no server upload since Vercel is serverless
3. **Admin notifications as DB records** – `AdminNotification` model in Prisma means each user gets their own copy, enabling per-user read tracking and cleanup
4. **Flutter `IndexedStack`** – Keeps all tab screens alive (no rebuild on tab switch), which avoids reload flicker on Dashboard
5. **Exact alarms** – Uses `AndroidScheduleMode.exactAllowWhileIdle` for reliable notification delivery on Doze mode
