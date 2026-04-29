# BuxBux Finance Tracker — Project Guide for Claude

## Project Overview
Full-stack personal finance app. Three layers: **Backend** (Node.js + Express + Prisma + PostgreSQL), **Frontend** (React + Redux Toolkit + Ant Design), **Mobile** (Flutter + Android widgets). Deployed on Vercel (backend & frontend). GitHub: `randyyuanda/finance-tracker`.

---

## Architecture at a Glance

```
finance-tracker/
├── backend/          Node.js + Express + Prisma (PostgreSQL)
├── frontend/         React + Redux Toolkit + Ant Design
└── mobile/           Flutter + Android home-screen widgets
```

---

## Backend (`backend/src/`)

### Stack
- **Framework**: Express.js
- **ORM**: Prisma (PostgreSQL)
- **Auth**: JWT (`middleware/auth.js` → `protect` middleware) + Google OAuth (passport.js)
- **Email**: Nodemailer (`services/emailService.js`)
- **Push notifications**: FCM (`services/fcmService.js`)
- **Deployment**: Vercel serverless

### Key files
| File | Purpose |
|---|---|
| `server.js` | Express app entrypoint, route mounting |
| `lib/prisma.js` | Prisma client singleton |
| `lib/format.js` | `fmtAccount`, `fmtTransaction`, `fmtCategory` serialisers |
| `middleware/auth.js` | JWT `protect` middleware — attaches `req.user._id` |
| `config/passport.js` | Google OAuth strategy + `DEFAULT_CATEGORIES` + `seedUserDefaults()` |
| `utils/seed.js` | Admin seed script |

### Controllers & Routes (1:1 mapping)
| Route prefix | Controller | Notes |
|---|---|---|
| `/auth` | `authController.js` | Register, login, Google OAuth, verify email, forgot/reset password |
| `/accounts` | `accountController.js` | CRUD; `balance` updated on transaction create/update/delete |
| `/categories` | `categoryController.js` | CRUD; **backfills missing default categories on every GET** |
| `/transactions` | `transactionController.js` | CRUD + supports `?startDate&endDate&type&accountId` filters |
| `/dashboard` | `dashboardController.js` | Aggregated stats: `totalBalance`, `balancesByCurrency`, `thisMonth.{income,expense,savings}`, `recentTransactions` |
| `/reports` | `reportController.js` | Monthly summary endpoint |
| `/goals` | `goalController.js` | CRUD savings goals |
| `/recurring` | `recurringController.js` | Recurring transaction templates |
| `/reminders` | `reminderController.js` | User reminders + admin notification broadcast |
| `/notifications` | `notificationController.js` | FCM token registration |
| `/cron` | `cronController.js` | Cron-triggered recurring/reminder jobs |
| `/admin` | `adminController.js` | Admin-only routes |

### Default categories (seeded on new user + backfilled on GET /categories)
Defined in `config/passport.js` → `DEFAULT_CATEGORIES`. Both income and expense variants exist for "Investment". New defaults automatically appear for existing users on next `/categories` fetch.

### Transaction rules
- `type`: `'income'` | `'expense'` | `'transfer'`
- Creating a transaction adjusts `account.balance` atomically in a Prisma `$transaction`
- Transfers debit `accountId` and credit `toAccountId`
- `groupBy` in dashboard excludes transfers from savings: `savings = income - expense`

---

## Frontend (`frontend/src/`)

### Stack
- React + Vite
- **State**: Redux Toolkit (slices in `store/slices/`)
- **UI**: Ant Design
- **HTTP**: Axios (`api/axios.js`)
- **i18n**: `i18n/translations.js` + `useT()` hook

### Slices → API mapping
| Slice | Endpoint |
|---|---|
| `authSlice` | `/auth/*` |
| `accountSlice` | `/accounts` |
| `categorySlice` | `/categories` |
| `transactionSlice` | `/transactions` |
| `dashboardSlice` | `/dashboard` |
| `goalSlice` | `/goals` |
| `recurringSlice` | `/recurring` |
| `reminderSlice` | `/reminders` |
| `settingsSlice` | Local settings |

### Pages
`Dashboard`, `Transactions`, `Accounts`, `Categories`, `Reports`, `Goals`, `RecurringTransactions`, `Reminders`, `Calendar`, `ExchangeRates`, `Settings`, `Admin`, auth pages.

---

## Mobile (`mobile/lib/`)

### Stack
- Flutter (Dart)
- **State**: `provider` package (`ChangeNotifier`)
- **HTTP**: Dio (`core/api.dart` → `ApiClient.dio`)
- **Local storage**: `shared_preferences` via `core/storage.dart`
- **Push**: Firebase Messaging (`core/notifications.dart`)
- **Home widgets**: `home_widget` package + native Android Kotlin providers

### Core utilities
| File | Purpose |
|---|---|
| `core/api.dart` | Dio singleton, `kApiBaseUrl`, `parseError()` |
| `core/formatters.dart` | `formatCurrency(amount, {currency})`, `formatDate`, `formatMonth` |
| `core/storage.dart` | Token, language, avatar, quick-add config persistence |
| `core/theme.dart` | `kPrimaryColor`, `kIncomeColor`, `kExpenseColor`, light/dark themes |
| `core/l10n.dart` | `context.l10n` extension, `AppL10n` |
| `core/notifications.dart` | `NotificationService.showImmediate()` |
| `core/widget_service.dart` | `WidgetService.updateBalance()` → saves to Android widget |
| `core/input_formatters.dart` | `AmountInputFormatter` (thousand-separator) |

### Models
| Model | Key fields |
|---|---|
| `Account` | `id, name, type, balance, currency, color, icon` |
| `Transaction` | `id, accountId, categoryId, amount, type, date, accountCurrency, toAccountId, toAccountCurrency` |
| `Category` | `id, name, type, color, icon` |
| `QuickAddConfig` | `id, type, amount, accountId, accountName, currency, categoryId, categoryName, label, note` |

`Transaction.fromJson` handles the backend pattern where `accountId`/`categoryId` can be an embedded object OR a plain string ID.

### Providers
| Provider | fetchAll trigger | Notes |
|---|---|---|
| `AuthProvider` | `initialize()` on app start | JWT stored in storage |
| `AccountProvider` | `HomeScreen.initState` | `fetchAll()` → GET /accounts |
| `CategoryProvider` | `HomeScreen.initState` | `fetchAll()` → GET /categories |
| `TransactionProvider` | On-demand | `fetchAll({startDate, endDate, limit, type, accountId})` → GET /transactions. Reports passes month date-range with `limit: 5000`. |
| `DashboardProvider` | `DashboardScreen.initState` | GET /dashboard — server-side aggregation |
| `QuickAddProvider` | `main()` app startup | Config stored locally; `_syncToWidget()` pushes to Android widget on every change |
| `ThemeProvider` | App startup | Language, theme mode, global currency |
| `GoalProvider` | `GoalsScreen` | Goals CRUD |
| `RecurringProvider` | `RecurringScreen` | Recurring templates |
| `ReminderProvider` | `HomeScreen.initState` | Reminders + admin notifications |

**IMPORTANT — cold-start from widget**: When the app opens via a home-screen widget deep link, `AccountProvider` and `CategoryProvider` may not have fetched yet. `QuickAddScreen` handles this by triggering `fetchAll()` in `initState` if providers are empty, and uses `didChangeDependencies` to set defaults once data arrives.

### Screens
| Screen | Path | Notes |
|---|---|---|
| `HomeScreen` | `screens/home_screen.dart` | Tab container. Triggers `AccountProvider.fetchAll()` + `CategoryProvider.fetchAll()` on init. |
| `DashboardScreen` | `screens/dashboard/` | Shows balance, stat cards, charts. Uses `DashboardProvider`. |
| `TransactionsScreen` | `screens/transactions/transactions_screen.dart` | Paginated list, uses `TransactionProvider` |
| `AddTransactionScreen` | `screens/transactions/add_transaction_screen.dart` | Full add/edit form |
| `TransferScreen` | `screens/transactions/transfer_screen.dart` | Account-to-account transfer |
| `QuickAddScreen` | `screens/transactions/quick_add_screen.dart` | Minimal add form; launched from widget deep link `buxbux://add?type=&amount=` |
| `ReportsScreen` | `screens/reports/reports_screen.dart` | Monthly reports. **Fetches by date range** (`startDate`/`endDate`) so net savings matches dashboard. Currency shown per selected account. |
| `AccountsScreen` | `screens/accounts/accounts_screen.dart` | CRUD accounts |
| `GoalsScreen` | `screens/goals/goals_screen.dart` | Savings goals |
| `RemindersScreen` | `screens/reminders/reminders_screen.dart` | User reminders |
| `QuickAddSettingsScreen` | `screens/settings/quick_add_settings_screen.dart` | Configure 4 widget buttons. Shows account currency in amount field. |
| `SettingsScreen` | `screens/settings/settings_screen.dart` | Profile, theme, language |
| `ExchangeRateScreen` | `screens/currency/exchange_rate_screen.dart` | Live exchange rates |

### Deep link / widget flow
```
Android widget tap
  → HomeWidgetLaunchIntent → buxbux://add?type=&amount=
  → _DeepLinkHandler (wraps HomeScreen) → Navigator.pushNamed('/quick_add')
  → QuickAddScreen
```
Background widget tap (buxbux://quickadd) → `_homeWidgetBackgroundHandler` in `main.dart` → posts transaction directly via Dio without opening the app.

### Android home-screen widgets
| Widget | Kotlin class | Layout | Info XML |
|---|---|---|---|
| Balance + Quick Add buttons | `BuxBuxWidgetProvider` | `buxbux_widget.xml` | `buxbux_widget_info.xml` |
| 4-button Quick Transaction (2×2 grid) | `BuxBuxQuickListWidgetProvider` | `buxbux_quicklist_widget.xml` | `buxbux_quicklist_widget_info.xml` |

**Widget data**: All widget preferences stored in `HomeWidgetPreferences` SharedPreferences. Keys: `q1_type`, `q1_amount` (String), `q1_label`, `q1_categoryName`, `q1_accountId`, `q1_categoryId`, `q1_note` (for i=1..4). Amount **must** be saved as String (not double) to avoid `Long/Float ClassCastException`.

**`QuickAddProvider._syncToWidget()`** pushes all config to Android after every change. Labels auto-include currency prefix when account is selected.

### Currency handling
- `formatCurrency(amount, {currency})` — defaults to `IDR` if currency omitted. Always pass `currency` explicitly.
- Accounts each have their own `currency` field. Multi-currency totals are summed as raw numbers (known limitation for "All Accounts" view).
- Reports `_displayCurrency` getter returns the selected account's currency, or the currency of transactions when only one currency is in the filtered set.
- Dashboard stat cards (income/expense/savings) show aggregated totals; for multi-currency users the total balance section shows per-currency breakdown.

### Adding a new feature — checklist
1. **Backend**: Add Prisma model (if needed) → controller → route → mount in `server.js`
2. **Frontend**: Add Redux slice → dispatch in component → page UI
3. **Mobile model**: Add Dart model class with `fromJson`/`toJson`
4. **Mobile provider**: `ChangeNotifier` subclass, `fetchAll()` using `ApiClient.dio`
5. **Mobile screen**: `context.watch<Provider>()` for reactive UI, `context.read<Provider>()` for one-shot calls
6. **Register provider** in `main.dart` `MultiProvider`
7. **Trigger fetch** in appropriate screen's `initState` (or `HomeScreen.initState` for global data)
8. If new category defaults: add to `DEFAULT_CATEGORIES` in `config/passport.js` — existing users get them automatically on next GET /categories

---

## Known patterns & gotchas

- **`Transaction.fromJson`**: `accountId` and `categoryId` from the API can be embedded objects (with `id`, `name`, etc.) or plain strings. The model handles both.
- **Reports date range**: Always pass `startDate`/`endDate` when fetching for reports (month-specific). Do NOT rely on client-side filtering from a large undated fetch — it diverges from the server-side dashboard aggregation.
- **Widget amount serialisation**: Save amounts as `String` (`c.amount.toString()`), never as `double`/`num` via `HomeWidget.saveWidgetData`. The Android `getFloat()` call throws `ClassCastException` when the value was stored as Long.
- **Category defaults backfill**: `getCategories` in the backend checks for and creates any missing default categories. Safe to call on every request.
- **`_defaultsLoaded` flag in QuickAddScreen**: Prevents `didChangeDependencies` from overriding user selections after providers have already loaded defaults.
- **`formatCurrency` without currency**: Defaults to `IDR`. Always pass `currency:` explicitly when the value might be in another currency.
