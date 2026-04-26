const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'BuxBux Finance Tracker API',
      version: '1.0.0',
      description: 'REST API for BuxBux personal finance tracker. All protected routes require a Bearer JWT token obtained from `/api/auth/login`.',
    },
    servers: [
      { url: 'https://fintech-api-randyyuandas-projects.vercel.app/api', description: 'Production' },
      { url: 'http://localhost:5000/api', description: 'Local development' },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
        },
      },
      schemas: {
        Error: {
          type: 'object',
          properties: {
            message: { type: 'string' },
          },
        },
        User: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            email: { type: 'string' },
            avatar: { type: 'string', nullable: true },
            language: { type: 'string', example: 'en' },
            currency: { type: 'string', example: 'IDR' },
            emailVerified: { type: 'boolean' },
            isAdmin: { type: 'boolean' },
          },
        },
        Account: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            type: { type: 'string', enum: ['cash', 'bank', 'e-wallet', 'savings', 'investment'] },
            balance: { type: 'number' },
            currency: { type: 'string', example: 'IDR' },
            color: { type: 'string', example: '#1890ff' },
            icon: { type: 'string', example: 'wallet' },
          },
        },
        Category: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            type: { type: 'string', enum: ['income', 'expense'] },
            color: { type: 'string' },
            icon: { type: 'string' },
            isDefault: { type: 'boolean' },
          },
        },
        Transaction: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            accountId: { type: 'object' },
            toAccountId: { type: 'object', nullable: true },
            categoryId: { type: 'object', nullable: true },
            amount: { type: 'number' },
            type: { type: 'string', enum: ['income', 'expense', 'transfer'] },
            date: { type: 'string', format: 'date-time' },
            note: { type: 'string', nullable: true },
          },
        },
        Goal: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            name: { type: 'string' },
            targetAmount: { type: 'number' },
            currentAmount: { type: 'number' },
            deadline: { type: 'string', format: 'date-time', nullable: true },
            color: { type: 'string' },
            isCompleted: { type: 'boolean' },
          },
        },
        Reminder: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            title: { type: 'string' },
            note: { type: 'string', nullable: true },
            reminderDate: { type: 'string', format: 'date-time' },
            type: { type: 'string', example: 'custom' },
            isCompleted: { type: 'boolean' },
            repeatType: { type: 'string', enum: ['none', 'daily', 'weekly', 'monthly', 'yearly'] },
          },
        },
        RecurringTransaction: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            accountId: { type: 'string' },
            categoryId: { type: 'string' },
            type: { type: 'string', enum: ['income', 'expense'] },
            amount: { type: 'number' },
            frequency: { type: 'string', enum: ['daily', 'weekly', 'monthly', 'yearly'] },
            nextDue: { type: 'string', format: 'date-time' },
            isActive: { type: 'boolean' },
          },
        },
      },
    },
    tags: [
      { name: 'Auth', description: 'Authentication and user profile' },
      { name: 'Accounts', description: 'Manage financial accounts' },
      { name: 'Categories', description: 'Manage transaction categories' },
      { name: 'Transactions', description: 'Manage transactions (income, expense, transfer)' },
      { name: 'Dashboard', description: 'Dashboard statistics and balance history' },
      { name: 'Reports', description: 'Download Excel reports and category summaries' },
      { name: 'Goals', description: 'Savings goals' },
      { name: 'Recurring', description: 'Recurring transaction schedules' },
      { name: 'Reminders', description: 'Reminders and due-date alerts' },
      { name: 'Notifications', description: 'Admin broadcast notifications' },
      { name: 'Cron', description: 'Scheduled background jobs' },
    ],
    paths: {
      // ── AUTH ──────────────────────────────────────────────────────────────
      '/auth/register': {
        post: {
          tags: ['Auth'],
          summary: 'Register a new user',
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['name', 'email', 'password'],
                  properties: {
                    name: { type: 'string', example: 'Randy Yuanda' },
                    email: { type: 'string', example: 'randy@example.com' },
                    password: { type: 'string', example: 'password123' },
                  },
                },
              },
            },
          },
          responses: {
            201: { description: 'Registered — OTP email sent for verification' },
            409: { description: 'Email already exists' },
          },
        },
      },
      '/auth/login': {
        post: {
          tags: ['Auth'],
          summary: 'Log in with email and password',
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['email', 'password'],
                  properties: {
                    email: { type: 'string', example: 'john@example.com' },
                    password: { type: 'string', example: 'password123' },
                  },
                },
              },
            },
          },
          responses: {
            200: { description: 'Login success — returns { token, user }' },
            401: { description: 'Invalid credentials' },
          },
        },
      },
      '/auth/me': {
        get: {
          tags: ['Auth'],
          summary: 'Get current user profile',
          security: [{ bearerAuth: [] }],
          responses: {
            200: { description: 'User object', content: { 'application/json': { schema: { $ref: '#/components/schemas/User' } } } },
          },
        },
      },
      '/auth/profile': {
        patch: {
          tags: ['Auth'],
          summary: 'Update profile (name, avatar, language, currency)',
          security: [{ bearerAuth: [] }],
          requestBody: {
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  properties: {
                    name: { type: 'string' },
                    avatar: { type: 'string' },
                    language: { type: 'string', example: 'en' },
                    currency: { type: 'string', example: 'IDR' },
                  },
                },
              },
            },
          },
          responses: { 200: { description: 'Updated user' } },
        },
      },
      '/auth/fcm-token': {
        post: {
          tags: ['Auth'],
          summary: 'Save FCM device token for push notifications',
          security: [{ bearerAuth: [] }],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: { type: 'object', required: ['fcmToken'], properties: { fcmToken: { type: 'string' } } },
              },
            },
          },
          responses: { 200: { description: 'Token saved' } },
        },
      },
      '/auth/verify-email': {
        post: {
          tags: ['Auth'],
          summary: 'Verify email with OTP code',
          security: [{ bearerAuth: [] }],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: { type: 'object', required: ['otp'], properties: { otp: { type: 'string', example: '123456' } } },
              },
            },
          },
          responses: { 200: { description: 'Email verified' }, 400: { description: 'Invalid or expired OTP' } },
        },
      },
      '/auth/resend-verification': {
        post: {
          tags: ['Auth'],
          summary: 'Resend email verification OTP',
          security: [{ bearerAuth: [] }],
          responses: { 200: { description: 'OTP sent' } },
        },
      },
      '/auth/request-otp': {
        post: {
          tags: ['Auth'],
          summary: 'Request password-reset OTP',
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: { type: 'object', required: ['email'], properties: { email: { type: 'string' } } },
              },
            },
          },
          responses: { 200: { description: 'OTP sent to email' } },
        },
      },
      '/auth/verify-otp': {
        post: {
          tags: ['Auth'],
          summary: 'Verify password-reset OTP',
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['email', 'otp'],
                  properties: {
                    email: { type: 'string' },
                    otp: { type: 'string' },
                  },
                },
              },
            },
          },
          responses: { 200: { description: 'Returns resetToken' } },
        },
      },
      '/auth/reset-password': {
        post: {
          tags: ['Auth'],
          summary: 'Reset password using resetToken',
          security: [{ bearerAuth: [] }],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['newPassword'],
                  properties: { newPassword: { type: 'string' } },
                },
              },
            },
          },
          responses: { 200: { description: 'Password reset' } },
        },
      },
      '/auth/set-password': {
        post: {
          tags: ['Auth'],
          summary: 'Set password for OAuth users who have no password',
          security: [{ bearerAuth: [] }],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['password'],
                  properties: { password: { type: 'string' } },
                },
              },
            },
          },
          responses: { 200: { description: 'Password set' } },
        },
      },

      // ── ACCOUNTS ──────────────────────────────────────────────────────────
      '/accounts': {
        get: {
          tags: ['Accounts'],
          summary: 'List all accounts',
          security: [{ bearerAuth: [] }],
          responses: {
            200: { description: 'Array of accounts', content: { 'application/json': { schema: { type: 'array', items: { $ref: '#/components/schemas/Account' } } } } },
          },
        },
        post: {
          tags: ['Accounts'],
          summary: 'Create a new account',
          security: [{ bearerAuth: [] }],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['name', 'type'],
                  properties: {
                    name: { type: 'string', example: 'BCA Bank' },
                    type: { type: 'string', enum: ['cash', 'bank', 'e-wallet', 'savings', 'investment'] },
                    balance: { type: 'number', example: 0 },
                    currency: { type: 'string', example: 'IDR' },
                    color: { type: 'string', example: '#1890ff' },
                    icon: { type: 'string', example: 'bank' },
                  },
                },
              },
            },
          },
          responses: { 201: { description: 'Created account' } },
        },
      },
      '/accounts/{id}': {
        put: {
          tags: ['Accounts'],
          summary: 'Update an account',
          security: [{ bearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          requestBody: {
            content: { 'application/json': { schema: { $ref: '#/components/schemas/Account' } } },
          },
          responses: { 200: { description: 'Updated account' } },
        },
        delete: {
          tags: ['Accounts'],
          summary: 'Delete an account',
          security: [{ bearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { 200: { description: 'Deleted' } },
        },
      },

      // ── CATEGORIES ────────────────────────────────────────────────────────
      '/categories': {
        get: {
          tags: ['Categories'],
          summary: 'List all categories',
          security: [{ bearerAuth: [] }],
          parameters: [
            { name: 'type', in: 'query', schema: { type: 'string', enum: ['income', 'expense'] } },
          ],
          responses: { 200: { description: 'Array of categories' } },
        },
        post: {
          tags: ['Categories'],
          summary: 'Create a category',
          security: [{ bearerAuth: [] }],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['name', 'type'],
                  properties: {
                    name: { type: 'string' },
                    type: { type: 'string', enum: ['income', 'expense'] },
                    color: { type: 'string' },
                    icon: { type: 'string' },
                  },
                },
              },
            },
          },
          responses: { 201: { description: 'Created category' } },
        },
      },
      '/categories/{id}': {
        put: {
          tags: ['Categories'],
          summary: 'Update a category',
          security: [{ bearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          requestBody: { content: { 'application/json': { schema: { $ref: '#/components/schemas/Category' } } } },
          responses: { 200: { description: 'Updated' } },
        },
        delete: {
          tags: ['Categories'],
          summary: 'Delete a category',
          security: [{ bearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { 200: { description: 'Deleted' } },
        },
      },

      // ── TRANSACTIONS ──────────────────────────────────────────────────────
      '/transactions': {
        get: {
          tags: ['Transactions'],
          summary: 'List transactions with pagination and filters',
          security: [{ bearerAuth: [] }],
          parameters: [
            { name: 'accountId', in: 'query', schema: { type: 'string' } },
            { name: 'categoryId', in: 'query', schema: { type: 'string' } },
            { name: 'type', in: 'query', schema: { type: 'string', enum: ['income', 'expense', 'transfer'] } },
            { name: 'startDate', in: 'query', schema: { type: 'string', format: 'date-time' } },
            { name: 'endDate', in: 'query', schema: { type: 'string', format: 'date-time' } },
            { name: 'page', in: 'query', schema: { type: 'integer', default: 1 } },
            { name: 'limit', in: 'query', schema: { type: 'integer', default: 20 } },
          ],
          responses: { 200: { description: '{ transactions, total, page, pages }' } },
        },
        post: {
          tags: ['Transactions'],
          summary: 'Create a transaction (income / expense / transfer)',
          security: [{ bearerAuth: [] }],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['accountId', 'amount', 'type', 'date'],
                  properties: {
                    accountId: { type: 'string' },
                    toAccountId: { type: 'string', description: 'Required when type=transfer' },
                    categoryId: { type: 'string', description: 'Required when type=income|expense' },
                    amount: { type: 'number' },
                    type: { type: 'string', enum: ['income', 'expense', 'transfer'] },
                    date: { type: 'string', format: 'date-time' },
                    note: { type: 'string' },
                  },
                },
              },
            },
          },
          responses: { 201: { description: 'Created transaction' } },
        },
      },
      '/transactions/{id}': {
        put: {
          tags: ['Transactions'],
          summary: 'Update a transaction',
          security: [{ bearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          requestBody: { content: { 'application/json': { schema: { $ref: '#/components/schemas/Transaction' } } } },
          responses: { 200: { description: 'Updated transaction' } },
        },
        delete: {
          tags: ['Transactions'],
          summary: 'Delete a transaction',
          security: [{ bearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { 200: { description: 'Deleted' } },
        },
      },

      // ── DASHBOARD ─────────────────────────────────────────────────────────
      '/dashboard': {
        get: {
          tags: ['Dashboard'],
          summary: 'Get dashboard stats (accounts, balances, monthly summary, recent transactions)',
          security: [{ bearerAuth: [] }],
          responses: {
            200: {
              description: 'Dashboard data',
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      accounts: { type: 'array', items: { $ref: '#/components/schemas/Account' } },
                      totalBalance: { type: 'number' },
                      balancesByCurrency: { type: 'object', example: { IDR: 5000000, USD: 100 } },
                      thisMonth: { type: 'object', properties: { income: { type: 'number' }, expense: { type: 'number' }, savings: { type: 'number' } } },
                      lastMonth: { type: 'object', properties: { income: { type: 'number' }, expense: { type: 'number' }, savings: { type: 'number' } } },
                      recentTransactions: { type: 'array', items: { $ref: '#/components/schemas/Transaction' } },
                    },
                  },
                },
              },
            },
          },
        },
      },
      '/dashboard/history': {
        get: {
          tags: ['Dashboard'],
          summary: 'Get balance history for the past 12 months',
          security: [{ bearerAuth: [] }],
          responses: {
            200: {
              description: 'Array of { month, balance }',
              content: { 'application/json': { schema: { type: 'array', items: { type: 'object', properties: { month: { type: 'string' }, balance: { type: 'number' } } } } } },
            },
          },
        },
      },

      // ── REPORTS ───────────────────────────────────────────────────────────
      '/reports/download': {
        get: {
          tags: ['Reports'],
          summary: 'Download Excel report',
          security: [{ bearerAuth: [] }],
          parameters: [
            { name: 'period', in: 'query', schema: { type: 'string', enum: ['alltime', '1month', '3months', '1year', '2years'], default: '1month' } },
            { name: 'accountId', in: 'query', schema: { type: 'string' }, description: 'Filter by single account' },
            { name: 'type', in: 'query', schema: { type: 'string', enum: ['income', 'expense', 'all'], default: 'all' } },
          ],
          responses: {
            200: { description: 'Excel file (.xlsx)', content: { 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': {} } },
          },
        },
      },
      '/reports/summary': {
        get: {
          tags: ['Reports'],
          summary: 'Get category breakdown summary',
          security: [{ bearerAuth: [] }],
          parameters: [
            { name: 'period', in: 'query', schema: { type: 'string', default: '1month' } },
          ],
          responses: { 200: { description: 'Array of { categoryId, name, total }' } },
        },
      },

      // ── GOALS ─────────────────────────────────────────────────────────────
      '/goals': {
        get: {
          tags: ['Goals'],
          summary: 'List goals',
          security: [{ bearerAuth: [] }],
          responses: { 200: { description: 'Array of goals' } },
        },
        post: {
          tags: ['Goals'],
          summary: 'Create a goal',
          security: [{ bearerAuth: [] }],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['name', 'targetAmount'],
                  properties: {
                    name: { type: 'string' },
                    targetAmount: { type: 'number' },
                    currentAmount: { type: 'number', default: 0 },
                    deadline: { type: 'string', format: 'date-time' },
                    color: { type: 'string' },
                  },
                },
              },
            },
          },
          responses: { 201: { description: 'Created goal' } },
        },
      },
      '/goals/{id}': {
        patch: {
          tags: ['Goals'],
          summary: 'Update a goal',
          security: [{ bearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          requestBody: { content: { 'application/json': { schema: { $ref: '#/components/schemas/Goal' } } } },
          responses: { 200: { description: 'Updated goal' } },
        },
        delete: {
          tags: ['Goals'],
          summary: 'Delete a goal',
          security: [{ bearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { 200: { description: 'Deleted' } },
        },
      },

      // ── RECURRING ─────────────────────────────────────────────────────────
      '/recurring': {
        get: {
          tags: ['Recurring'],
          summary: 'List recurring transactions',
          security: [{ bearerAuth: [] }],
          responses: { 200: { description: 'Array of recurring transactions' } },
        },
        post: {
          tags: ['Recurring'],
          summary: 'Create a recurring transaction',
          security: [{ bearerAuth: [] }],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['accountId', 'categoryId', 'type', 'amount', 'frequency', 'nextDue'],
                  properties: {
                    accountId: { type: 'string' },
                    categoryId: { type: 'string' },
                    type: { type: 'string', enum: ['income', 'expense'] },
                    amount: { type: 'number' },
                    frequency: { type: 'string', enum: ['daily', 'weekly', 'monthly', 'yearly'] },
                    nextDue: { type: 'string', format: 'date-time' },
                    note: { type: 'string' },
                  },
                },
              },
            },
          },
          responses: { 201: { description: 'Created' } },
        },
      },
      '/recurring/{id}': {
        patch: {
          tags: ['Recurring'],
          summary: 'Update a recurring transaction',
          security: [{ bearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          requestBody: { content: { 'application/json': { schema: { $ref: '#/components/schemas/RecurringTransaction' } } } },
          responses: { 200: { description: 'Updated' } },
        },
        delete: {
          tags: ['Recurring'],
          summary: 'Delete a recurring transaction',
          security: [{ bearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { 200: { description: 'Deleted' } },
        },
      },

      // ── REMINDERS ─────────────────────────────────────────────────────────
      '/reminders': {
        get: {
          tags: ['Reminders'],
          summary: 'List reminders',
          security: [{ bearerAuth: [] }],
          parameters: [
            { name: 'status', in: 'query', schema: { type: 'string', enum: ['upcoming', 'overdue', 'completed'] } },
          ],
          responses: { 200: { description: 'Array of reminders' } },
        },
        post: {
          tags: ['Reminders'],
          summary: 'Create a reminder',
          security: [{ bearerAuth: [] }],
          requestBody: {
            required: true,
            content: {
              'application/json': {
                schema: {
                  type: 'object',
                  required: ['title', 'reminderDate'],
                  properties: {
                    title: { type: 'string' },
                    note: { type: 'string' },
                    reminderDate: { type: 'string', format: 'date-time' },
                    type: { type: 'string', default: 'custom' },
                    repeatType: { type: 'string', enum: ['none', 'daily', 'weekly', 'monthly', 'yearly'], default: 'none' },
                  },
                },
              },
            },
          },
          responses: { 201: { description: 'Created reminder' } },
        },
      },
      '/reminders/{id}': {
        patch: {
          tags: ['Reminders'],
          summary: 'Update a reminder',
          security: [{ bearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          requestBody: { content: { 'application/json': { schema: { $ref: '#/components/schemas/Reminder' } } } },
          responses: { 200: { description: 'Updated reminder' } },
        },
        delete: {
          tags: ['Reminders'],
          summary: 'Delete a reminder',
          security: [{ bearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { 200: { description: 'Deleted' } },
        },
      },
      '/reminders/{id}/complete': {
        patch: {
          tags: ['Reminders'],
          summary: 'Toggle reminder complete status',
          security: [{ bearerAuth: [] }],
          parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
          responses: { 200: { description: 'Toggled reminder' } },
        },
      },

      // ── NOTIFICATIONS ─────────────────────────────────────────────────────
      '/notifications/admin': {
        get: {
          tags: ['Notifications'],
          summary: 'Get unread admin broadcast notifications for the current user',
          security: [{ bearerAuth: [] }],
          responses: { 200: { description: 'Array of admin notifications (one-time marked as read after fetch)' } },
        },
      },

      // ── CRON ──────────────────────────────────────────────────────────────
      '/cron/reminders': {
        get: {
          tags: ['Cron'],
          summary: 'Send FCM push for all reminders due in the next 65 minutes',
          description: 'Called automatically by Vercel Cron (daily 09:00 UTC). Optionally protected by `x-cron-secret` header or `?secret=` query param matching the `CRON_SECRET` env var.',
          parameters: [
            { name: 'x-cron-secret', in: 'header', schema: { type: 'string' } },
            { name: 'secret', in: 'query', schema: { type: 'string' } },
          ],
          responses: {
            200: { description: '{ sent, total }' },
            401: { description: 'Unauthorized (wrong secret)' },
          },
        },
      },

      // ── HEALTH ────────────────────────────────────────────────────────────
      '/health': {
        get: {
          tags: ['Auth'],
          summary: 'Health check — verifies DB connection',
          responses: { 200: { description: '{ status: "ok", db: "postgresql" }' } },
        },
      },
    },
  },
  apis: [],
};

module.exports = swaggerJsdoc(options);
