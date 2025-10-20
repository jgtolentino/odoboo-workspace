# Web App & Mobile Deployment Guide

Complete deployment architecture for Next.js web application and Expo mobile app.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ Deployment Architecture                                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│ Web App (Next.js 14+):                                          │
│   Vercel (atomic-crm.vercel.app)                                │
│   ├─ App Router + Server Components                             │
│   ├─ TypeScript + Tailwind CSS v4                               │
│   ├─ Direct Supabase connection                                 │
│   └─ SSR + ISR + Edge Functions                                 │
│                                                                   │
│ Mobile App (Expo/React Native):                                 │
│   EAS Build + EAS Submit                                        │
│   ├─ Offline-first with SQLite                                  │
│   ├─ Camera integration (receipt capture)                       │
│   ├─ Push notifications (Expo Push)                             │
│   └─ Sync with Supabase on connectivity                         │
│                                                                   │
│ API Layer:                                                       │
│   ├─ Supabase PostgreSQL (spdtwktxdalcfigzeqrz)                │
│   ├─ Supabase Edge Functions (Deno runtime)                     │
│   ├─ OCR Service (DigitalOcean droplet)                         │
│   └─ Task Bus (Supabase task_queue table)                       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Part 1: Web App (Next.js) Deployment

### 1.1 Vercel Setup

**Current Deployment**:

- **URL**: https://atomic-crm.vercel.app
- **Framework**: Next.js 14.2.18
- **Region**: Washington, D.C. (us-east-1)
- **Repository**: GitHub (jgtolentino/odoboo-workspace)

**Project Structure**:

```
odoboo-workspace/
├── app/                    # Next.js 14 App Router
│   ├── (auth)/            # Authentication routes
│   ├── (dashboard)/       # Protected dashboard routes
│   ├── api/               # API routes
│   └── layout.tsx         # Root layout
├── components/            # React components
│   ├── ui/                # UI primitives (shadcn/ui)
│   ├── forms/             # Form components
│   └── charts/            # Data visualization
├── lib/                   # Utility functions
│   ├── supabase/          # Supabase client setup
│   ├── utils.ts           # Shared utilities
│   └── validations.ts     # Zod schemas
├── public/                # Static assets
├── styles/                # Global styles
├── next.config.js         # Next.js configuration
├── tailwind.config.ts     # Tailwind CSS v4 configuration
└── tsconfig.json          # TypeScript configuration
```

### 1.2 Environment Variables

**Vercel Environment Variables** (Project Settings → Environment Variables):

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://spdtwktxdalcfigzeqrz.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...  # Safe for client-side
SUPABASE_SERVICE_ROLE_KEY=eyJhbGci...      # Server-side only

# OCR Service
NEXT_PUBLIC_OCR_API_URL=https://ocr.insightpulseai.net/ocr
OCR_SECRET=<from /etc/ocr/token>            # Server-side only

# Analytics (optional)
NEXT_PUBLIC_GA_MEASUREMENT_ID=G-XXXXXXXXXX
NEXT_PUBLIC_POSTHOG_KEY=phc_xxxxx
NEXT_PUBLIC_POSTHOG_HOST=https://app.posthog.com

# Feature Flags
NEXT_PUBLIC_ENABLE_MOBILE_APP=true
NEXT_PUBLIC_ENABLE_OCR=true
NEXT_PUBLIC_ENABLE_VISUAL_PARITY=true
```

### 1.3 Deployment Configuration

**File**: `vercel.json`

```json
{
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "framework": "nextjs",
  "regions": ["iad1"],
  "env": {
    "NEXT_PUBLIC_SUPABASE_URL": "@supabase_url",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY": "@supabase_anon_key",
    "SUPABASE_SERVICE_ROLE_KEY": "@supabase_service_role_key"
  },
  "build": {
    "env": {
      "NEXT_TELEMETRY_DISABLED": "1"
    }
  },
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Access-Control-Allow-Credentials", "value": "true" },
        { "key": "Access-Control-Allow-Origin", "value": "*" },
        { "key": "Access-Control-Allow-Methods", "value": "GET,POST,PUT,DELETE,OPTIONS" },
        {
          "key": "Access-Control-Allow-Headers",
          "value": "X-Requested-With, Content-Type, Authorization"
        }
      ]
    }
  ]
}
```

**File**: `next.config.js`

```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,

  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'spdtwktxdalcfigzeqrz.supabase.co',
        pathname: '/storage/v1/object/public/**',
      },
    ],
  },

  experimental: {
    serverActions: {
      allowedOrigins: ['atomic-crm.vercel.app'],
    },
  },

  // Environment variable validation
  env: {
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
  },

  // Webpack configuration for Edge Runtime compatibility
  webpack: (config, { isServer }) => {
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
      };
    }
    return config;
  },
};

module.exports = nextConfig;
```

### 1.4 Supabase Integration

**File**: `lib/supabase/client.ts`

```typescript
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs';
import { Database } from '@/types/supabase';

export function createClient() {
  return createClientComponentClient<Database>();
}
```

**File**: `lib/supabase/server.ts`

```typescript
import { createServerComponentClient } from '@supabase/auth-helpers-nextjs';
import { cookies } from 'next/headers';
import { Database } from '@/types/supabase';

export function createServerClient() {
  return createServerComponentClient<Database>({ cookies });
}
```

**File**: `lib/supabase/middleware.ts`

```typescript
import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs';
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export async function middleware(req: NextRequest) {
  const res = NextResponse.next();
  const supabase = createMiddlewareClient({ req, res });

  const {
    data: { session },
  } = await supabase.auth.getSession();

  // Protect dashboard routes
  if (req.nextUrl.pathname.startsWith('/dashboard') && !session) {
    return NextResponse.redirect(new URL('/login', req.url));
  }

  return res;
}

export const config = {
  matcher: ['/dashboard/:path*'],
};
```

### 1.5 Deployment Workflow

**Automatic Deployment** (Git Push):

```bash
# Development branch → Preview deployment
git checkout develop
git add .
git commit -m "feat: add expense form"
git push origin develop
# Vercel automatically deploys to preview URL

# Production branch → Production deployment
git checkout main
git merge develop
git push origin main
# Vercel automatically deploys to atomic-crm.vercel.app
```

**Manual Deployment** (Vercel CLI):

```bash
# Install Vercel CLI
npm i -g vercel

# Login
vercel login

# Deploy to preview
vercel

# Deploy to production
vercel --prod

# Check deployment status
vercel ls

# View logs
vercel logs atomic-crm.vercel.app
```

### 1.6 Performance Optimization

**Image Optimization**:

```typescript
import Image from 'next/image'

export function ReceiptImage({ url }: { url: string }) {
  return (
    <Image
      src={url}
      alt="Receipt"
      width={400}
      height={600}
      placeholder="blur"
      blurDataURL="data:image/png;base64,..."
      priority
    />
  )
}
```

**Route Caching**:

```typescript
// app/expenses/[id]/page.tsx
export const revalidate = 60; // Revalidate every 60 seconds

export async function generateStaticParams() {
  const expenses = await getExpenses();
  return expenses.map((expense) => ({
    id: expense.id.toString(),
  }));
}
```

**Edge Functions**:

```typescript
// app/api/ocr/route.ts
export const runtime = 'edge';

export async function POST(request: Request) {
  const formData = await request.formData();
  const file = formData.get('file') as File;

  // Call OCR service
  const response = await fetch(process.env.OCR_API_URL!, {
    method: 'POST',
    headers: {
      'X-OCR-Secret': process.env.OCR_SECRET!,
    },
    body: formData,
  });

  return Response.json(await response.json());
}
```

---

## Part 2: Mobile App (Expo) Deployment

### 2.1 Expo Setup

**Project Structure**:

```
mobile-app/
├── app/                    # Expo Router (file-based routing)
│   ├── (tabs)/            # Bottom tabs navigator
│   │   ├── index.tsx      # Home screen
│   │   ├── expenses.tsx   # Expenses list
│   │   ├── camera.tsx     # Receipt capture
│   │   └── profile.tsx    # User profile
│   ├── _layout.tsx        # Root layout
│   └── +not-found.tsx     # 404 screen
├── components/            # React Native components
│   ├── ui/                # UI primitives
│   ├── Camera.tsx         # Camera component
│   └── ExpenseForm.tsx    # Expense form
├── lib/                   # Utilities
│   ├── supabase.ts        # Supabase client
│   ├── sqlite.ts          # Local SQLite database
│   └── sync.ts            # Offline sync logic
├── assets/                # Images, fonts
├── app.json               # Expo configuration
├── eas.json               # EAS Build configuration
├── babel.config.js        # Babel configuration
└── tsconfig.json          # TypeScript configuration
```

### 2.2 Expo Configuration

**File**: `app.json`

```json
{
  "expo": {
    "name": "Atomic CRM",
    "slug": "atomic-crm-mobile",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "userInterfaceStyle": "automatic",
    "splash": {
      "image": "./assets/splash.png",
      "resizeMode": "contain",
      "backgroundColor": "#ffffff"
    },
    "assetBundlePatterns": ["**/*"],
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.insightpulseai.atomiccrm",
      "buildNumber": "1.0.0",
      "infoPlist": {
        "NSCameraUsageDescription": "This app uses the camera to capture receipts for expense tracking.",
        "NSPhotoLibraryUsageDescription": "This app needs access to your photo library to select receipts."
      }
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#ffffff"
      },
      "package": "com.insightpulseai.atomiccrm",
      "versionCode": 1,
      "permissions": ["CAMERA", "READ_EXTERNAL_STORAGE", "WRITE_EXTERNAL_STORAGE"]
    },
    "web": {
      "favicon": "./assets/favicon.png"
    },
    "plugins": ["expo-router", "expo-camera", "expo-sqlite", "expo-notifications"],
    "extra": {
      "eas": {
        "projectId": "your-project-id"
      }
    }
  }
}
```

**File**: `eas.json`

```json
{
  "cli": {
    "version": ">= 5.9.0"
  },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "env": {
        "EXPO_PUBLIC_SUPABASE_URL": "https://spdtwktxdalcfigzeqrz.supabase.co",
        "EXPO_PUBLIC_SUPABASE_ANON_KEY": "eyJhbGci..."
      }
    },
    "preview": {
      "distribution": "internal",
      "env": {
        "EXPO_PUBLIC_SUPABASE_URL": "https://spdtwktxdalcfigzeqrz.supabase.co",
        "EXPO_PUBLIC_SUPABASE_ANON_KEY": "eyJhbGci..."
      }
    },
    "production": {
      "env": {
        "EXPO_PUBLIC_SUPABASE_URL": "https://spdtwktxdalcfigzeqrz.supabase.co",
        "EXPO_PUBLIC_SUPABASE_ANON_KEY": "eyJhbGci..."
      }
    }
  },
  "submit": {
    "production": {
      "ios": {
        "appleId": "your-email@example.com",
        "ascAppId": "1234567890",
        "appleTeamId": "ABCDE12345"
      },
      "android": {
        "serviceAccountKeyPath": "./android-service-account.json",
        "track": "internal"
      }
    }
  }
}
```

### 2.3 Offline-First Architecture

**SQLite Local Database**:

```typescript
// lib/sqlite.ts
import * as SQLite from 'expo-sqlite';

const db = SQLite.openDatabase('atomic-crm.db');

export function initializeDatabase() {
  db.transaction((tx) => {
    // Create expenses table
    tx.executeSql(
      `CREATE TABLE IF NOT EXISTS expenses (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        amount REAL NOT NULL,
        vendor TEXT,
        date TEXT NOT NULL,
        tax REAL,
        receipt_url TEXT,
        synced INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )`
    );

    // Create sync_queue table
    tx.executeSql(
      `CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        operation TEXT NOT NULL,
        record_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )`
    );
  });
}

export function createExpense(expense: Expense) {
  return new Promise((resolve, reject) => {
    db.transaction((tx) => {
      tx.executeSql(
        'INSERT INTO expenses (id, user_id, amount, vendor, date, tax, receipt_url) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          expense.id,
          expense.user_id,
          expense.amount,
          expense.vendor,
          expense.date,
          expense.tax,
          expense.receipt_url,
        ],
        (_, result) => resolve(result),
        (_, error) => reject(error)
      );
    });
  });
}
```

**Sync Logic**:

```typescript
// lib/sync.ts
import { createClient } from './supabase';
import { db } from './sqlite';
import NetInfo from '@react-native-community/netinfo';

export async function syncWithServer() {
  const { isConnected } = await NetInfo.fetch();

  if (!isConnected) {
    console.log('No internet connection, skipping sync');
    return;
  }

  const supabase = createClient();

  // Get unsync records from local database
  const unsyncedExpenses = await getUnsyncedExpenses();

  for (const expense of unsyncedExpenses) {
    try {
      // Upload to Supabase
      const { error } = await supabase.from('expenses').upsert(expense, { onConflict: 'id' });

      if (error) throw error;

      // Mark as synced in local database
      await markExpenseAsSynced(expense.id);
    } catch (error) {
      console.error('Sync failed for expense:', expense.id, error);
    }
  }

  // Download new records from server
  const { data: remoteExpenses } = await supabase
    .from('expenses')
    .select('*')
    .gt('updated_at', await getLastSyncTimestamp());

  for (const expense of remoteExpenses || []) {
    await upsertLocalExpense(expense);
  }

  await updateLastSyncTimestamp();
}

// Auto-sync every 5 minutes when online
setInterval(syncWithServer, 5 * 60 * 1000);
```

### 2.4 Camera Integration

**Receipt Capture Component**:

```typescript
// components/Camera.tsx
import { Camera, CameraType } from 'expo-camera'
import { useState } from 'react'
import { Button, View, StyleSheet } from 'react-native'

export function ReceiptCamera({ onCapture }: { onCapture: (uri: string) => void }) {
  const [type, setType] = useState(CameraType.back)
  const [permission, requestPermission] = Camera.useCameraPermissions()
  const [cameraRef, setCameraRef] = useState<Camera | null>(null)

  if (!permission) {
    return <View />
  }

  if (!permission.granted) {
    return (
      <View style={styles.container}>
        <Button title="Grant Camera Permission" onPress={requestPermission} />
      </View>
    )
  }

  async function takePicture() {
    if (cameraRef) {
      const photo = await cameraRef.takePictureAsync({
        quality: 0.8,
        base64: true,
        skipProcessing: false,
      })

      // Upload to Supabase Storage
      const fileName = `receipt_${Date.now()}.jpg`
      const { data, error } = await supabase.storage
        .from('receipts')
        .upload(fileName, photo.base64, {
          contentType: 'image/jpeg',
        })

      if (error) {
        console.error('Upload failed:', error)
        return
      }

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('receipts')
        .getPublicUrl(fileName)

      onCapture(publicUrl)
    }
  }

  return (
    <View style={styles.container}>
      <Camera style={styles.camera} type={type} ref={setCameraRef}>
        <View style={styles.buttonContainer}>
          <Button title="Capture Receipt" onPress={takePicture} />
        </View>
      </Camera>
    </View>
  )
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  camera: { flex: 1 },
  buttonContainer: { position: 'absolute', bottom: 20, alignSelf: 'center' },
})
```

### 2.5 Push Notifications

**Setup**:

```typescript
// lib/notifications.ts
import * as Notifications from 'expo-notifications';
import Constants from 'expo-constants';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

export async function registerForPushNotificationsAsync() {
  let token;

  if (Constants.isDevice) {
    const { status: existingStatus } = await Notifications.getPermissionsAsync();
    let finalStatus = existingStatus;

    if (existingStatus !== 'granted') {
      const { status } = await Notifications.requestPermissionsAsync();
      finalStatus = status;
    }

    if (finalStatus !== 'granted') {
      alert('Failed to get push token for push notification!');
      return;
    }

    token = (await Notifications.getExpoPushTokenAsync()).data;
    console.log('Push token:', token);

    // Save token to Supabase
    const supabase = createClient();
    await supabase.from('user_devices').upsert({ push_token: token }, { onConflict: 'user_id' });
  } else {
    alert('Must use physical device for Push Notifications');
  }

  return token;
}

// Send notification when OCR completes
export async function sendOCRCompleteNotification(
  expenseId: string,
  vendor: string,
  amount: number
) {
  await Notifications.scheduleNotificationAsync({
    content: {
      title: 'Receipt Processed!',
      body: `${vendor}: $${amount.toFixed(2)} - Ready to approve`,
      data: { expenseId },
    },
    trigger: null, // Send immediately
  });
}
```

### 2.6 Build & Deployment

**EAS Build** (Cloud Build):

```bash
# Install EAS CLI
npm install -g eas-cli

# Login to Expo
eas login

# Configure project
eas build:configure

# Build for iOS (development)
eas build --platform ios --profile development

# Build for Android (development)
eas build --platform android --profile development

# Build for production
eas build --platform all --profile production

# Submit to App Store
eas submit --platform ios

# Submit to Google Play
eas submit --platform android
```

**Local Build** (Deprecated, use EAS):

```bash
# iOS
expo run:ios

# Android
expo run:android
```

### 2.7 Environment-Specific Configuration

**Development**:

```bash
# .env.development
EXPO_PUBLIC_API_URL=http://localhost:3000/api
EXPO_PUBLIC_SUPABASE_URL=https://spdtwktxdalcfigzeqrz.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
EXPO_PUBLIC_OCR_API_URL=http://127.0.0.1:8000/ocr
```

**Production**:

```bash
# .env.production
EXPO_PUBLIC_API_URL=https://atomic-crm.vercel.app/api
EXPO_PUBLIC_SUPABASE_URL=https://spdtwktxdalcfigzeqrz.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=eyJhbGci...
EXPO_PUBLIC_OCR_API_URL=https://ocr.insightpulseai.net/ocr
```

---

## Part 3: Integration & Testing

### 3.1 End-to-End Flow

**Receipt Processing Flow**:

1. **Mobile App**: User captures receipt with camera
2. **Upload**: Photo uploaded to Supabase Storage
3. **Trigger**: Task enqueued in `task_queue` table
4. **OCR**: Service processes receipt via DigitalOcean droplet
5. **Extract**: Vendor, amount, date, tax extracted
6. **Store**: Data saved to Supabase `expenses` table
7. **Notify**: Push notification sent to mobile app
8. **Sync**: Web app receives real-time update via Supabase Realtime
9. **Review**: User reviews and approves expense
10. **Export**: Optional export to Concur or other systems

### 3.2 Visual Parity Testing

**GitHub Actions Workflow** (`.github/workflows/visual-parity.yml`):

```yaml
name: Visual Parity Testing

on:
  pull_request:
    paths:
      - 'app/**'
      - 'components/**'
      - 'styles/**'

jobs:
  visual-parity:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright
        run: npx playwright install --with-deps chromium

      - name: Build Next.js app
        run: npm run build

      - name: Start preview server
        run: npm start &

      - name: Wait for server
        run: npx wait-on http://localhost:3000

      - name: Capture screenshots
        run: node scripts/snap.js --routes="/expenses,/tasks,/dashboard" --base-url="http://localhost:3000" --output="./screenshots"

      - name: Compare with baselines
        run: node scripts/ssim.js --routes="/expenses,/tasks,/dashboard" --screenshots="./screenshots"

      - name: Upload screenshots
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: visual-diffs
          path: screenshots/diffs/
```

### 3.3 Performance Monitoring

**Web Vitals Tracking**:

```typescript
// app/layout.tsx
import { Analytics } from '@vercel/analytics/react'
import { SpeedInsights } from '@vercel/speed-insights/next'

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        {children}
        <Analytics />
        <SpeedInsights />
      </body>
    </html>
  )
}
```

**Custom Performance Tracking**:

```typescript
// lib/analytics.ts
export function trackPerformance(metric: string, value: number) {
  if (typeof window !== 'undefined' && window.gtag) {
    window.gtag('event', 'timing_complete', {
      name: metric,
      value: Math.round(value),
      event_category: 'Performance',
    });
  }
}

// Usage
trackPerformance('ocr_processing', 2500); // 2.5 seconds
```

---

## Quick Reference

### Web App Commands

```bash
# Development
npm run dev                  # Start dev server (localhost:3000)
npm run build                # Production build
npm run start                # Start production server
npm run lint                 # Run ESLint

# Deployment
vercel                       # Deploy to preview
vercel --prod                # Deploy to production
vercel logs                  # View deployment logs
```

### Mobile App Commands

```bash
# Development
npm start                    # Start Expo dev server
npm run ios                  # Run on iOS simulator
npm run android              # Run on Android emulator

# Build
eas build --platform ios --profile development
eas build --platform android --profile development
eas build --platform all --profile production

# Submit
eas submit --platform ios
eas submit --platform android
```

### Configuration Files

| File             | Purpose                                   |
| ---------------- | ----------------------------------------- |
| `vercel.json`    | Vercel deployment configuration           |
| `next.config.js` | Next.js build configuration               |
| `app.json`       | Expo app configuration                    |
| `eas.json`       | EAS Build configuration                   |
| `.env.local`     | Local environment variables (git-ignored) |

---

**Last Updated**: 2025-10-20
**Web App**: https://atomic-crm.vercel.app
**Mobile App**: In Development (EAS Build)
**Repository**: https://github.com/jgtolentino/odoboo-workspace
