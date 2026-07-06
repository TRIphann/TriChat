# 💬 TriChat — Messaging Application

---

## 📝 Project Description

**TriChat** is a real-time messaging application inspired by Zalo, built with a Client-Server architecture. The project consists of 4 main components:

| Component      | Description                         | Technology                   |
| -------------- | ----------------------------------- | ---------------------------- |
| **backend/**   | REST API & WebSocket Server         | ASP.NET Core 8.0 (C#)       |
| **frontend/**  | Mobile Application (Android/iOS)    | Flutter / Dart               |
| **web_admin/** | Admin Dashboard                     | Flutter Web                  |
| **functions/** | Cloud Functions (Push Notification) | Firebase Functions (Node.js) |

---

## 🚀 Key Features

### 📱 Mobile Application (frontend)

- **1-1 & Group Chat:** Send text messages, images, videos, audio, and file attachments
- **Real-time:** Receive instant messages via SignalR WebSocket
- **Calls:** Voice/Video calls via Agora RTC Engine
- **Friends:** Send/receive friend requests, scan QR codes for quick friend adding
- **NewsFeed & Story:** Post feeds and stories (auto-expire after 24 hours)
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Message Interactions:** Reply, forward, react with emoji, recall, and edit messages
- **Status:** Online/Offline, typing indicator, read/delivered receipts

### 🖥️ Admin Dashboard (web_admin)

- Overview statistics dashboard
- Manage users, posts (Feed), and violation reports
- Manage friendships
- Send push notifications to users
- Manage feedback

---

## 🔧 Tech Stack

### Backend (ASP.NET Core)

| Technology / Package   | Version   | Purpose                                         |
| ---------------------- | --------- | ----------------------------------------------- |
| .NET SDK               | 8.0       | Backend Runtime                                 |
| ASP.NET Core           | 8.0       | Web API Framework                               |
| SignalR                | 8.0.15    | Real-time WebSocket (Chat, Friend)              |
| Google.Cloud.Firestore | 4.2.0     | NoSQL Database                                  |
| FirebaseAdmin          | 3.5.0     | Firebase Authentication & FCM                   |
| StackExchange.Redis    | 2.12.14   | Caching (online status, OTP, search)            |
| CloudinaryDotNet       | 1.29.1    | Upload & manage images/videos                   |
| FluentValidation       | 11.3.1    | Input data validation                           |
| Mapster                | 10.0.7    | Object mapping (DTO ↔ Model)                    |
| Serilog                | 10.0.0    | Structured Logging                              |
| Swashbuckle (Swagger)  | 6.6.2     | API Documentation                               |
| Scrutor                | 7.0.0     | Auto DI Registration                            |
| Groq API               | —         | AI Content Moderation (LLaMA 3.1)               |

### Frontend Mobile (Flutter)

| Technology / Package       | Version   | Purpose                              |
| -------------------------- | --------- | ------------------------------------ |
| Flutter                    | 3.41.9    | Mobile UI Framework                  |
| Dart                       | 3.11.5    | Programming Language                 |
| firebase_core              | ^2.31.0   | Firebase SDK                         |
| firebase_auth              | ^4.19.0   | User Authentication                  |
| cloud_firestore            | ^4.17.5   | Firestore Queries                    |
| firebase_messaging         | ^14.9.4   | Push Notification                    |
| dio                        | ^5.7.0    | HTTP Client                          |
| signalr_netcore            | ^1.4.4    | WebSocket Connection to Backend      |
| agora_rtc_engine           | ^6.3.2    | Voice/Video Call                     |
| provider                   | ^6.1.1    | State Management                     |
| go_router                  | ^17.1.0   | Routing / Navigation                 |
| image_picker               | ^1.1.2    | Pick images from Gallery/Camera      |
| camera                     | ^0.10.5+5 | Direct camera capture                |
| qr_flutter                 | ^4.1.0    | Generate QR Code                     |
| mobile_scanner             | ^5.2.3    | Scan QR Code                         |
| table_calendar             | ^3.1.2    | Calendar                             |
| flutter_dotenv             | ^6.0.1    | Read environment variables from `.env` |
| flutter_local_notifications| ^17.2.4   | Local Notifications                  |
| flutter_callkeep           | ^1.0.0    | Display incoming call UI             |
| permission_handler         | ^11.3.1   | Manage permissions (Camera, Mic,...) |

### Web Admin (Flutter Web)

| Technology / Package | Version   | Purpose                              |
| -------------------- | --------- | ------------------------------------ |
| Flutter Web          | 3.41.9    | Web UI Framework                     |
| firebase_core        | ^3.6.0    | Firebase SDK                         |
| firebase_auth        | ^5.3.1    | Admin Authentication                 |
| cloud_firestore      | ^5.4.3    | Firestore Queries                    |
| flutter_riverpod     | ^2.6.1    | State Management                     |
| go_router            | ^14.3.0   | Routing                              |
| google_fonts         | ^6.2.1    | Typography                           |
| fl_chart             | ^0.69.0   | Statistics Charts                    |
| cached_network_image | ^3.4.1    | Load & cache images                  |
| flutter_dotenv       | ^6.0.1    | Read environment variables from `.env` |

### Third-party Services

| Service                                              | Purpose                                     |
| ---------------------------------------------------- | ------------------------------------------- |
| **Firebase** (Firestore, Auth, FCM, Cloud Functions) | Database, authentication, push notification |
| **Redis**                                            | Caching online status, storing OTP          |
| **Cloudinary**                                       | Media storage & management (images, videos) |
| **Groq (LLaMA 3.1 8B)**                             | AI content moderation for posts             |
| **Agora**                                            | Voice/Video Call Engine                     |
| **Gmail SMTP**                                       | Send OTP verification emails                |

---

## 📋 Prerequisites

Before installation, make sure the following software is installed:

| Software                          | Minimum Version | Download Link                                                            |
| --------------------------------- | --------------- | ------------------------------------------------------------------------ |
| Flutter SDK                       | 3.41.9          | [flutter.dev](https://flutter.dev/docs/get-started/install)              |
| Dart SDK                          | 3.11.5          | (Bundled with Flutter SDK)                                               |
| .NET SDK                          | 8.0             | [dotnet.microsoft.com](https://dotnet.microsoft.com/download/dotnet/8.0) |
| Docker Desktop                    | 4.x             | [docker.com](https://www.docker.com/products/docker-desktop/)            |
| Android Studio / VS Code          | Latest          | Development IDE                                                          |
| Android Emulator or physical device | Android 6.0+  | Run mobile application                                                   |

### Quick choice — local dev with Docker (recommended)

If you only have Docker installed, you can bring up the backend + Redis with one command:

```bash
# Generate a base64 of your firebase key once:
pwsh scripts/encode-firebase-key.ps1
# create a .env with the variables listed in the Docker Compose section below
docker compose up --build
```

### Quick choice — Flutter Web on desktop

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5244
```

### Quick choice — local dev with Docker Compose

If you don't want to install the .NET SDK or Redis on your host, the entire
backend runs in a single command from the **repo root**. First create a `.env`
file at the repo root with these variables (the entrypoint reads them at
container start):

```env
Firebase__ProjectId=<your firebase project id>
Firebase__CredentialsBase64=<base64 from scripts/encode-firebase-key.ps1>
Redis__ConnectString=redis:6379
Cloudinary__CloudName=<your cloudinary cloud>
Cloudinary__ApiKey=<your api key>
Cloudinary__ApiSecret=<your api secret>
Groq__ApiKey=<your groq api key>
Smtp__Host=smtp.gmail.com
Smtp__Port=587
Smtp__Username=<your gmail address>
Smtp__Password=<your gmail app password 16 chars>
Smtp__From=<your gmail address>
```

Then:

```bash
pwsh scripts/encode-firebase-key.ps1   # base64-encode your serviceAccountKey.json
docker compose up --build
```

- Backend ↦ `http://localhost:5244` (Swagger: `/swagger`)
- Redis ↦ `localhost:6379`
- Same code path as production; the entrypoint synthesises `appsettings.json`
  from environment variables.

### Production-style deployment to the public web

The backend ships with a production-ready `Dockerfile` and `docker-compose.yml`
that work identically in local dev and on any container host (Render, Railway,
Fly.io, a $4 VPS, etc.). Bring the stack up locally with:

```bash
docker compose up --build
```

For cloud-specific walkthroughs, see the commit history or contact the
maintainer — the exact steps depend on which platform you pick.

---

## ⚙️ Installation & Setup Guide

### Step 1: Clone the project

```bash
git clone https://github.com/TRIphann/ZaloLite.git
cd ZaloLite
```

### Step 2: Configure required environment variables (the project will not run without these)

Configure the necessary files for each component:

1. Add **appsettings.json** and the **FirebaseCredentials** folder to the root of the `backend/` directory

2. Add **.env** file to the root of the `frontend/` directory

3. Add **.env** file to the root of the `web_admin/` directory

## 📂 Project Structure After Setup

```
ZaloLite/
│
├── backend/                          # Backend API (ASP.NET Core 8.0)
│   ├── Controllers/                  # API Controllers
│   ├── FirebaseCredentials/          # Contains JSON file for Firebase connection
│   │   └── serviceAccountKey.json    # Firebase Service Account Key
│   ├── appsettings.json              # Application configuration
│   └── Program.cs                    # Entry point
│
├── frontend/                         # Mobile App (Flutter)
│   ├── lib/
│   ├── .env                          # API URL configuration
│   └── pubspec.yaml                  # Dependencies
│
├── web_admin/                        # Admin Dashboard (Flutter Web)
│   ├── lib/
│   ├── .env                          # Admin account configuration
│   └── pubspec.yaml                  # Dependencies
│
├── functions/                        # Firebase Cloud Functions (Node.js)
│
├── docs/                             # Technical documentation
│
└── README.md                         # This file
```

### Step 3: Run Backend (ASP.NET Core)

```bash
# Navigate to backend directory
cd backend

# Restore NuGet packages
dotnet restore

# Build the project
dotnet build

# Run the application
dotnet run
```

> Backend will run at: `http://localhost:5244`  
> Swagger UI: `http://localhost:5244/swagger/index.html`

**⚠️ Note:** Make sure Redis Server is running before starting the Backend.

### Step 4: Run Frontend Mobile (Flutter)

```bash
# Navigate to frontend directory
cd frontend

# Install Dart packages
flutter pub get
```

**Run on Android Emulator:**

```bash
flutter run
```

**Run on a physical Android device (via Wi-Fi on the same network):**

1. Open `frontend/.env`
2. Change `API_BASE_URL` to your network IP:
   ```env
   API_BASE_URL=http://192.168.1.xxx:5244
   ```
3. Run:
   ```bash
   flutter run
   ```

### Step 5: Run Web Admin (Flutter Web)

```bash
# Navigate to web_admin directory
cd web_admin

# Install Dart packages
flutter pub get

# Run on Chrome browser
flutter run -d chrome
```

> Web Admin will open at: `http://localhost:xxxx` (port is automatically assigned by Flutter)

---

## 🔑 Test Accounts

### Mobile Application (frontend)

| Description    | Email               | Password   |
| -------------- | ------------------- | ---------- |
| Test account 1 | `dinhnhan@gmai.com` | `Aa@12345` |
| Test account 2 | `khanhha@gmail.com` | `Aa@12345` |

> **Note:** The above accounts are pre-registered on Firebase Authentication. You can register new accounts directly in the application.

### Web Admin Dashboard

| Description   | Email                | Password       |
| ------------- | -------------------- | -------------- |
| Admin account | `admin123@gmail.com` | `admin123@456` |

---

## 📂 Full Project Directory Structure

```
ZaloLite/
│
├── backend/                          # Backend API (ASP.NET Core 8.0)
│   ├── Controllers/                  # API Controllers
│   │   ├── AuthController.cs         #   Authentication (Login/Register)
│   │   ├── ChatController.cs         #   1-1 & Group Chat
│   │   ├── FeedController.cs         #   Posts & Stories
│   │   ├── FriendController.cs       #   Friend Management
│   │   ├── OtpController.cs          #   OTP Verification via Email
│   │   └── UserController.cs         #   User Management
│   ├── Hubs/                         # SignalR WebSocket Hubs
│   │   ├── ChatHub.cs                #   Real-time Chat
│   │   └── FriendHub.cs              #   Real-time Friend Requests
│   ├── Services/                     # Business Logic Layer
│   ├── Models/                       # Data Models
│   ├── dtos/                         # Data Transfer Objects
│   ├── Middleware/                    # Custom Middleware (Auth, Exception)
│   ├── FirebaseCredentials/          # Firebase Service Account Key
│   ├── appsettings.json              # Application configuration
│   └── Program.cs                    # Entry point
│
├── frontend/                         # Mobile App (Flutter)
│   ├── lib/
│   │   ├── config/                   # Configuration (API URL, Theme)
│   │   ├── models/                   # Data Models
│   │   ├── views/                    # UI Screens
│   │   │   ├── auth/                 #   Login / Register
│   │   │   ├── chat/                 #   Chat Screen
│   │   │   ├── call/                 #   Voice/Video Calls
│   │   │   ├── contacts/            #   Contacts & Friends
│   │   │   ├── home/                 #   Home Page
│   │   │   └── settings/            #   Settings
│   │   ├── features/                 # Feature Modules
│   │   │   ├── calling/              #   Voice/Video Call
│   │   │   ├── friends/              #   Friend Management
│   │   │   ├── newfeed/              #   NewsFeed & Story
│   │   │   ├── feedback/             #   Feedback
│   │   │   └── profile/              #   User Profile
│   │   ├── services/                 # API & SignalR Services
│   │   ├── providers/                # State Management
│   │   └── main.dart                 # Entry point
│   ├── .env                          # API URL configuration
│   └── pubspec.yaml                  # Dependencies
│
├── web_admin/                        # Admin Dashboard (Flutter Web)
│   ├── lib/
│   │   ├── core/                     # Theme, Router, Constants
│   │   ├── features/                 # Admin Modules
│   │   └── main.dart                 # Entry point
│   ├── .env                          # Admin account configuration
│   └── pubspec.yaml                  # Dependencies
│
├── functions/                        # Firebase Cloud Functions (Node.js)
│   └── index.js                      # Push Notification dispatcher
│
├── docs/                             # Technical Documentation
│   ├── CHAT_SYSTEM_GUIDE.md
│   ├── ARCHITECTURE_DIAGRAM.md
│   ├── COMPLETE_SYSTEM_OVERVIEW.md
│   ├── FLUTTER_INTEGRATION_EXAMPLE.md
│   └── Chat_API.postman_collection.json
│
└── README.md                         # This file
```

---

## ⚠️ Important Notes

### 1. Required Configuration Files

The following files are **REQUIRED** for the project to work. If missing, the application will crash:

| File                     | Location                       | Description                                           |
| ------------------------ | ------------------------------ | ----------------------------------------------------- |
| `serviceAccountKey.json` | `backend/FirebaseCredentials/` | Firebase authentication key (do not push to Git)      |
| `appsettings.json`       | `backend/`                     | Backend config (Redis, Cloudinary, Email, Groq)       |
| `.env`                   | `frontend/`                    | Contains `API_BASE_URL` — Backend API address         |
| `.env`                   | `web_admin/`                   | Contains `ADMIN_EMAIL` and `ADMIN_PASSWORD`           |

### 2. Redis Server Must Be Running

The backend uses Redis to store online/offline status, OTP, and cache. If Redis is not running, the backend will throw a connection error on startup.

### 3. API Address for Device Testing

| Device                        | API_BASE_URL                |
| ----------------------------- | --------------------------- |
| Android Emulator              | `http://10.0.2.2:5244`     |
| Physical device (same Wi-Fi)  | `http://<your-PC-IP>:5244` |

### 4. Recommended Startup Order

1. **Redis Server** → start first
2. **Backend** (`dotnet run`) → start after Redis
3. **Frontend** (`flutter run`) → start after Backend
4. **Web Admin** (`flutter run -d chrome`) → can run independently (connects directly to Firestore)

---

## 📚 References

- [Flutter Documentation](https://docs.flutter.dev/)
- [ASP.NET Core Documentation](https://learn.microsoft.com/aspnet/core/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [SignalR Documentation](https://learn.microsoft.com/aspnet/core/signalr/)
- [Agora RTC Documentation](https://docs.agora.io/en/)

---

## 📄 License

This project was built for educational purposes.
