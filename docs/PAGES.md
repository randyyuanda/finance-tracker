# FinTrack – Page & Feature Reference

All pages across backend API, React frontend, and Flutter mobile.

---

## Backend API Routes

### Auth (`/api/auth`)
| Route | Method | Auth | Description |
|---|---|---|---|
| `/login` | POST | No | Returns `{ token, user }` |
| `/register` | POST | No | Returns `{ token, user }` |
| `/me` | GET | Yes | Returns current user object |
| `/profile` | PUT | Yes | Update name (body: `{ name }`) |

### Accounts (`/api/accounts`)
| Route | Method | Auth | Description |
|---|---|---|---|
| `/` | GET | Yes | List all accounts |
| `/` | POST | Yes | Create account `{ name, type, balance, currency, color, icon }` |
| `/:id` | PATCH | Yes | Update account (supports negative balance) |
| `/:id` | DELETE | Yes | Delete account |

### Transactions (`/api/transactions`)
| Route | Method | Auth | Description |
|---|---|---|---|
| `/` | GET | Yes | List transactions (query: `page`, `limit`, `type`, `accountId`) |
| `/` | POST | Yes | Create `{ accountId, categoryId, type, amount, date, note? }` |
| `/:id` | DELETE | Yes | Delete transaction |

### Categories (`/api/categories`)
| Route | Method | Auth | Description |
|---|---|---|---|
| `/` | GET | Yes | List all categories (query: `type=income\|expense`) |

### Goals (`/api/goals`)
| Route | Method | Auth | Description |
|---|---|---|---|
| `/` | GET | Yes | List goals |
| `/` | POST | Yes | Create goal `{ name, targetAmount, deadline, color }` |
| `/:id` | PATCH | Yes | Update goal (deposit, rename, etc.) |
| `/:id` | DELETE | Yes | Delete goal |

### Recurring Transactions (`/api/recurring`)
| Route | Method | Auth | Description |
|---|---|---|---|
| `/` | GET | Yes | List recurring transactions |
| `/:id` | PATCH | Yes | Toggle active/pause |

### Reminders (`/api/reminders`)
| Route | Method | Auth | Description |
|---|---|---|---|
| `/` | GET | Yes | List all reminders for current user |
| `/` | POST | Yes | Create `{ title, note?, reminderDate, type, repeatType }` |
| `/:id` | PATCH | Yes | Update reminder |
| `/:id/complete` | PATCH | Yes | Toggle isCompleted |
| `/:id` | DELETE | Yes | Delete reminder |

### Dashboard (`/api/dashboard`)
| Route | Method | Auth | Description |
|---|---|---|---|
| `/` | GET | Yes | Returns `{ stats, recentTransactions, accounts }` |

### Admin (`/api/admin`)
| Route | Method | Auth (superadmin) | Description |
|---|---|---|---|
| `/broadcast` | POST | Yes | Send notification to all users `{ title, scheduledAt, repeatType, note? }` |
| `/stats` | GET | Yes | Platform stats |
| `/users` | GET | Yes | All users list |

### Notifications (`/api/notifications`)
| Route | Method | Auth | Description |
|---|---|---|---|
| `/admin` | GET | Yes | Fetch unread admin broadcasts for current user |

---

## React Frontend Pages

### Login (`/login`)
- Email + password form
- Redirects to `/dashboard` on success
- Link to register

### Register (`/register`)
- Name + email + password form
- Auto-login after register

### Dashboard (`/dashboard`)
- **Stats cards**: Total balance, monthly income, monthly expense, net savings
- **Charts**: Income vs expense trend, spending by category
- **Recent transactions**: Last 10 with category, account, amount

### Transactions (`/transactions`)
- Paginated list with filters (type, date range, account)
- Add transaction modal: type toggle, amount, account, category, date, note
- Delete with confirmation
- Export to CSV/PDF

### Accounts (`/accounts`)
- Card grid of all accounts with balance
- Add/edit account: name, type, balance (supports negative), icon, color
- Balance history chart

### Categories (`/categories`)
- Tabs: Income / Expense
- Add/edit/delete categories with color and icon

### Goals (`/goals`)
- Card grid with progress bars
- Add/edit goal: name, target, deadline, color
- Deposit amount to goal

### Reminders (`/reminders`)
- Tabs: All / Upcoming / Overdue / Done
- Add/edit reminder: title, note, date+time, type, repeat
- Complete toggle
- Browser push notification at reminder time

### Reports (`/reports`)
- Monthly/yearly date picker
- Income vs expense chart
- Category breakdown pie chart
- Download as CSV or PDF

### Settings (`/settings`)
- Update name
- Change password
- Notification preferences

### Admin (`/admin`) — Superadmin only
- **Stats**: Total users, transactions, active accounts
- **Users**: Table with user details and last activity
- **Broadcast**: Create push notification to all users
  - Title, note, scheduled date/time, repeat type (none/daily/weekly/monthly)
  - Shows as OS notification on mobile app
  - Shows as browser Notification API popup on web

---

## Flutter Mobile Screens

### Auth
| Screen | File | Features |
|---|---|---|
| Login | `screens/auth/login_screen.dart` | Email + password, error display, link to register |
| Register | `screens/auth/register_screen.dart` | Name + email + password |

### Bottom Nav Tabs (HomeScreen)
| Tab | Screen | Features |
|---|---|---|
| Dashboard | `screens/dashboard/dashboard_screen.dart` | Balance header, stat cards, income/expense pie chart, 7-day bar chart, accounts carousel, recent transactions |
| Transactions | `screens/transactions/transactions_screen.dart` | Filter by type, paginated list, delete, FAB to add |
| Goals | `screens/goals/goals_screen.dart` | Progress bars, add/deposit/delete |
| Reminders | `screens/reminders/reminders_screen.dart` | 4 tabs (All/Upcoming/Overdue/Done), OS notification scheduling |
| More | `screens/more/more_screen.dart` | Profile card, links to Accounts, Recurring, Reports, Settings |

### Detail Screens
| Screen | File | Features |
|---|---|---|
| Add Transaction | `screens/transactions/add_transaction_screen.dart` | Type toggle (income/expense), amount, account dropdown, category dropdown, date picker, note |
| Accounts | `screens/accounts/accounts_screen.dart` | List with balance, add/edit with icon picker + color + negative balance |
| Recurring | `screens/recurring/recurring_screen.dart` | Read-only list, toggle active/pause |
| Reports | `screens/reports/reports_screen.dart` | Month selector, summary cards, category pie chart, transaction list, CSV export |
| Settings | `screens/settings/settings_screen.dart` | Profile photo (local), edit name, theme toggle (light/dark/system), language selector (en/id), sign out |

---

## Feature: Admin Broadcasts → Mobile Push Notification

**Flow:**
1. Superadmin logs in on web → goes to Admin page
2. Fills out broadcast form: title, scheduled time, repeat type, message
3. Submits → `POST /api/admin/broadcast`
4. Backend creates one `AdminNotification` record per active user
5. Mobile app calls `checkAdminNotifications()` on startup (in `HomeScreen.initState`)
6. Fetches `/api/notifications/admin` → list of unread notifications
7. For each: `NotificationService.scheduleAdmin()` schedules OS notification
   - **One-time past**: fires in 5 seconds (user sees immediately on open)
   - **One-time future**: scheduled at exact time
   - **Repeating** (daily/weekly/monthly): OS repeats automatically

**Web (browser) side:**
- `useReminderNotifications` hook in React polls every 60 seconds
- Calls `/api/notifications/admin`, checks `isDueNow()` with repeat awareness
- Fires `new Notification('📢 title', { body })` via the browser Notification API

---

## Feature: Transaction Page Fix

**Problem**: After adding a transaction, the list wasn't refreshing correctly.

**Root cause**: `TransactionProvider.create()` previously called `fetchAll(reset: true)` internally (without the type filter), then the screen also called `_load()` after pop — causing two fetches and a brief state inconsistency.

**Fix**: `create()` now only POSTs and returns true/false. The screen's `if (result == true) _load()` handles the refresh with the correct type filter.

---

## Feature: Theme & Language Persistence

**ThemeProvider** (`providers/theme_provider.dart`):
- `themeMode`: ThemeMode.light / ThemeMode.dark / ThemeMode.system
- `language`: 'en' or 'id'
- Both persisted in SharedPreferences via `Storage`
- `main.dart` passes `themeProvider.themeMode` to `MaterialApp.themeMode`
- Settings screen: SegmentedButton for theme, DropdownButton for language

---

## Feature: Profile Photo

- Picked from gallery or camera using `image_picker`
- Stored locally at the picked file path; path saved in SharedPreferences
- Displayed as `FileImage` in `CircleAvatar`
- No server upload (Vercel serverless doesn't support persistent file storage)
- Shown in Settings, More screen profile card, and Dashboard avatar

---

## Feature: Reports & CSV Export

**Reports screen** (`screens/reports/reports_screen.dart`):
- Month navigation (chevron left/right, can't go past current month)
- Summary cards: income, expense, net savings for selected month
- Category breakdown pie chart (fl_chart) for expenses
- Transaction list filtered by month
- Export button → generates CSV → `Share.shareXFiles()` opens system share sheet

**CSV format:**
```
Date,Type,Category,Account,Amount (IDR),Note
Apr 23 2026,expense,Food,BCA,45000,lunch
...
```
