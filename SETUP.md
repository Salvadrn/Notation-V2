# Notation V2 - Complete Setup Guide

## 1. Xcode Project Setup

### Create the Project
1. Open Xcode 15.3+
2. File > New > Project
3. Choose **App** (Multiplatform)
4. Product Name: `Notation`
5. Team: Your Apple Developer Team
6. Organization Identifier: `com.notation` (or your domain)
7. Bundle Identifier: `com.notation.app`
8. Interface: **SwiftUI**
9. Storage: **None** (we use Supabase)
10. Save to a location, then close it

### Add Files
1. Drag the entire `Notation/` folder from this repo into your Xcode project
2. Make sure "Copy items if needed" is checked
3. Add to target: `Notation`

### Add SPM Dependency
1. File > Add Package Dependencies
2. Search: `https://github.com/supabase/supabase-swift.git`
3. Version Rule: **Up to Next Major Version** from `2.0.0`
4. Add to target: `Notation`

### Configure Targets
1. Select the project in the navigator
2. Select the **Notation** target
3. General tab:
   - Minimum Deployments: **iOS 17.0**, **macOS 14.0**
4. Signing & Capabilities:
   - Add **In-App Purchase** capability
   - Add **Push Notifications** (optional, for future use)

### Info.plist Keys
Add these to your Info.plist (or target's Info tab):
```xml
<key>NSCameraUsageDescription</key>
<string>Take photos of slides to generate AI notes</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Select slide images to generate AI notes</string>
```

---

## 2. Supabase Setup

### Create Project
1. Go to https://supabase.com and sign in
2. Click "New Project"
3. Choose your organization
4. Project name: `notation-v2`
5. Database password: (save this securely)
6. Region: Choose closest to your users
7. Wait for project to initialize

### Run Migration
1. Go to **SQL Editor** in your Supabase dashboard
2. Copy the entire contents of `Notation/Database/migration.sql`
3. Paste and click **Run**
4. Verify all tables are created in the **Table Editor**

### Configure Auth
1. Go to **Authentication > Providers**
2. Ensure **Email** is enabled
3. Optionally disable "Confirm email" for development
4. Go to **Authentication > URL Configuration**
5. Site URL: `com.notation.app://` (for deep links)

### Verify Storage Buckets
The migration SQL creates these buckets automatically:
- `avatars` (public)
- `glyphs` (private)
- `attachments` (private)
- `exports` (private)

Verify in **Storage** section of dashboard.

### Enable Realtime
The migration SQL enables realtime on `pages`, `page_layers`, `notebooks`, `sections`.
Verify in **Database > Replication** that these tables are in the publication.

### Get Your Keys
1. Go to **Settings > API**
2. Copy:
   - **Project URL** (e.g., `https://xxxx.supabase.co`)
   - **anon public** key

### Insert Keys in Code
Open `Notation/Config/AppConfig.swift` and replace:
```swift
static let supabaseURL = URL(string: "https://YOUR_PROJECT_REF.supabase.co")!
static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
```

---

## 3. Claude API Setup

### Get API Key
1. Go to https://console.anthropic.com
2. Create an API key
3. Copy it

### Insert Key in Code
Open `Notation/Config/AppConfig.swift` and replace:
```swift
static let claudeAPIKey = "YOUR_CLAUDE_API_KEY"
```

**Security Note:** For production, the Claude API key should NOT be in the client app. Instead, create a Supabase Edge Function that proxies requests to Claude. The current setup is for development/MVP only.

---

## 4. In-App Purchase Setup

### App Store Connect
1. Go to https://appstoreconnect.apple.com
2. Create your app if not already done
3. Go to **Monetization > Subscriptions**
4. Create a Subscription Group: "Notation Pro"
5. Add subscriptions:
   - `com.notation.pro.monthly` - Monthly Pro
   - `com.notation.pro.yearly` - Yearly Pro
6. Go to **Monetization > In-App Purchases**
7. Add consumables:
   - `com.notation.tokens.100` - 100 Tokens
   - `com.notation.tokens.500` - 500 Tokens
   - `com.notation.tokens.1000` - 1000 Tokens
8. Set prices for each product

### StoreKit Testing
1. In Xcode, create a StoreKit Configuration File:
   - File > New > File > StoreKit Configuration File
   - Name: `NotationStore.storekit`
2. Add your products with the same IDs
3. In scheme settings, set the StoreKit Configuration to your file
4. This allows testing purchases in the simulator

---

## 5. TestFlight Deployment

1. In Xcode: Product > Archive
2. In Organizer: Distribute App > App Store Connect
3. In App Store Connect: Go to TestFlight
4. Add internal/external testers
5. Submit build for review (external testers only)

---

## 6. App Store Submission

### Privacy Description (for App Store Connect)
```
Notation collects and stores the following data:
- Email address (for account authentication)
- User-created content (notebooks, notes, handwriting data)
- Usage data (for improving the app experience)

All data is stored securely in our cloud infrastructure and can be deleted upon request.

AI features send image data to Anthropic's Claude API for text extraction and note generation. No personal data is shared with third parties beyond what is necessary for the AI processing feature.
```

### Subscription Explanation Text
```
Notation Pro - Unlock unlimited notebooks, AI-powered note generation, real-time collaboration, and priority cloud sync.

- Monthly: $X.XX/month
- Yearly: $XX.XX/year (save XX%)

Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. You can manage and cancel your subscription in your Apple ID account settings.
```

### Marketing Description
```
Notation - The Intelligent Notebook

Transform how you take notes. Notation combines the power of handwriting with the efficiency of digital tools.

Features:
- Create unlimited notebooks organized in folders
- Write with Apple Pencil on fixed A4/Letter pages
- Create your own handwriting font from your actual handwriting
- Convert typed text to your personal handwriting style
- AI-powered slide analysis - snap a photo, get organized notes
- Real-time collaboration with friends and colleagues
- Export to PDF
- Beautiful, minimal interface

Available on iPad and Mac.
```

---

## 7. Project Structure Overview

```
Notation/
  NotationApp.swift           -- App entry point
  Config/                     -- Configuration (3 files)
  Core/
    Models/                   -- Data models (10 files)
    Services/                 -- Supabase + business logic (13 files)
    Extensions/               -- Swift extensions (4 files)
    Utilities/                -- Helpers (3 files)
  Features/
    Auth/                     -- Login/signup (4 files)
    Workspace/                -- Folders + notebook grid (9 files)
    Notebook/                 -- Sections + page nav (5 files)
    Page/                     -- Page editing (6 files)
    Drawing/                  -- PencilKit [iPad] (4 files)
    Handwriting/              -- Alphabet Studio [iPad] (6 files)
    AI/                       -- Claude integration (4 files)
    Settings/                 -- Profile + monetization (5 files)
  SharedUI/                   -- Reusable components (6 files)
  Database/                   -- SQL migration (1 file)
```

**Total: ~75 Swift files + 1 SQL file**

---

## 8. Token Pricing Logic

Edit `Notation/Config/Constants.swift` to adjust:
```swift
enum Tokens {
    static let costPerAIGeneration = 10      // tokens per AI use
    static let costPerHandwritingConversion = 2  // tokens per conversion
    static let starterPackAmount = 100       // free tokens on signup
}
```

Set actual dollar prices in App Store Connect for:
- `com.notation.tokens.100`
- `com.notation.tokens.500`
- `com.notation.tokens.1000`
