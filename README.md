# BuxBux Finance Tracker

Personal finance tracker — web (React), mobile (Flutter/Android), and Android widgets.

## Live URLs

| Service | URL |
|---------|-----|
| **Frontend** | https://fintech-randyyuandas-projects.vercel.app |
| **Backend API** | https://fintech-api-randyyuandas-projects.vercel.app/api |
| **API Docs (Swagger)** | https://fintech-api-randyyuandas-projects.vercel.app/api/docs |
| **OpenAPI JSON** | https://fintech-api-randyyuandas-projects.vercel.app/api/docs.json |

## API Documentation

Open **[Swagger UI](https://fintech-api-randyyuandas-projects.vercel.app/api/docs)** to explore and test every endpoint interactively.

### How to authenticate in Swagger

1. Click **Authorize** (top-right lock icon)
2. Call `POST /auth/login` with `{ "email": "john@example.com", "password": "password123" }`
3. Copy the `token` from the response
4. Click **Authorize**, paste `<token>` in the **bearerAuth** field, click **Authorize**
5. All protected endpoints will now include your JWT automatically

### Quick test account

```
email:    john@example.com
password: password123
```

Run `npm run seed` inside `backend/` to recreate it if needed.

---

## Stack

| Layer | Tech |
|-------|------|
| Backend | Node.js + Express + PostgreSQL (Neon) + Prisma |
| Frontend | React (Vite) + Ant Design + Redux Toolkit |
| Mobile | Flutter (Android) + Provider |
| Auth | JWT + Passport Google OAuth + Email OTP |
| Push | Firebase Cloud Messaging (FCM) + flutter_local_notifications |
| Reports | ExcelJS |
| Hosting | Vercel (both backend and frontend) |

---

## Features

- **Dashboard** — monthly income/expense/savings stats, balance history chart, recent transactions
- **Accounts** — multi-currency (IDR/USD/EUR/SGD/JPY/GBP/AUD/MYR), CRUD
- **Categories** — income/expense tabs, custom colors and icons
- **Transactions** — income, expense, **transfer** between accounts, filters, pagination
- **Reports** — Excel download with account + type filters
- **Goals** — savings targets with progress
- **Recurring** — scheduled recurring transactions
- **Reminders** — local push notifications (mobile) + browser notifications (web)
- **Exchange Rates** — live rates via fawazahmed0 free API
- **Android Widget** — 2×1 quick-add widget that opens a themed popup
- **Admin panel** — FCM broadcast notifications, user management

---

## Local development

### Backend

```bash
cd backend
cp .env.example .env   # fill in DATABASE_URL, JWT_SECRET, SMTP_*, etc.
npm install
npm run db:push        # sync Prisma schema to DB
npm run dev            # starts on :5000
```

### Frontend

```bash
cd frontend
npm install
npm run dev            # starts on :3000
```

### Mobile

```bash
cd mobile
flutter pub get
flutter run            # Android emulator or device required
```

---

## Environment variables (backend)

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Neon PostgreSQL connection string (pooled) |
| `DIRECT_URL` | Neon direct URL for migrations |
| `JWT_SECRET` | Secret for signing JWTs |
| `SESSION_SECRET` | Express session secret |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret |
| `CLIENT_URL` | Comma-separated list of allowed frontend origins |
| `SMTP_SERVICE` | `gmail` |
| `SMTP_USER` | Gmail address for sending OTP emails |
| `SMTP_PASS` | Gmail App Password |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase Admin SDK JSON (stringified) — required for FCM push |
| `CRON_SECRET` | Optional secret to protect the `/api/cron/reminders` endpoint |

---

## FCM Setup (push notifications)

1. Go to [Firebase Console](https://console.firebase.google.com/) → Project Settings → Service Accounts
2. Click **Generate new private key** — download the JSON file
3. Minify the JSON and set it as the `FIREBASE_SERVICE_ACCOUNT` env var in Vercel
4. The daily cron at `/api/cron/reminders` will then send FCM pushes for due reminders
