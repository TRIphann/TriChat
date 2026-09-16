# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TriChat is a Zalo-like chat application with 1-1 and group messaging, built with an ASP.NET Core 8 backend and a **React 18.3.1 + Vite 5.4.10 + Anime.js 4.0.2** frontend. Real-time communication uses SignalR; data is stored in Firestore; media uploads go through Cloudinary; and Redis is used for caching. A separate `web_admin/` Flutter Web app provides an admin dashboard that reads/writes Firestore directly (no backend API involved). A small `functions/` Node.js Firebase Cloud Function dispatches FCM push notifications when the admin dashboard creates a notification document.

**Brand:** The app's visual identity uses a warm palette — amber `#D97706`, ember `#EA580C`, rose `#E11D48`, plasma `#7C3AED`, bone cream `#FAF8F5`, noir `#0A0907` — defined centrally in `frontend/src/theme/tokens.js` and `frontend/src/theme/global.css`. To re-theme the app, edit those constants. All UI files import colors from there, so a single edit propagates everywhere.

## Commands

### Backend (from `backend/`)

```bash
dotnet restore          # Install packages
dotnet build            # Build
dotnet run              # Run (http://localhost:5244 / https://localhost:7000)
dotnet watch run        # Run with hot reload
```

Backend requires `appsettings.json` with `Firebase.ProjectId`, `Firebase.CredentialsFilePath`, `Redis.ConnectString`, and `Cloudinary` config. The Firebase service account key goes in `backend/FirebaseCredentials/serviceAccountKey.json`.

Swagger UI is available at `https://localhost:7000/swagger` in Development mode.

There is no backend test project in this repo currently.

### Frontend (from `frontend/`)

```bash
npm install            # Install dependencies (React 18 + Vite + Anime.js + ...)
npm run dev            # Dev server (http://localhost:5173, auto-reload)
npm run build          # Production build → dist/
npm run preview        # Serve dist/ (port 4173)
```

Frontend requires a `.env` file in `frontend/` with:
- `VITE_API_BASE_URL` (default `http://localhost:5244`)
- `VITE_AGORA_APP_ID`, `VITE_AGORA_APP_CERTIFICATE` (Agora RTC)
- `VITE_FB_*` (Firebase Web SDK config)
- `VITE_FB_VAPID_KEY` (FCM Web Push — lấy từ Firebase Console)

### Admin dashboard (from `web_admin/`)

```bash
flutter pub get         # Install packages
flutter run -d chrome   # Run as a web app
flutter build web       # Build for deployment
flutter analyze         # Lint
```

Requires a `.env` file in `web_admin/` with `ADMIN_EMAIL` and `ADMIN_PASSWORD` (see `web_admin/env.example.json` for reference). Firebase options are in `web_admin/lib/firebase_options.dart`.

## Architecture

### Backend

```
Controllers/ → Services/ → Firestore (via FirebaseService)
                         ↘ Redis (via RedisService)
                         ↘ Cloudinary (via CloudinaryService)
Hubs/ (SignalR)         → ChatHub, FriendHub
Middleware/             → FirebaseAuthMiddleware, GlobalExceptionHandler
```

**Auth flow:** `FirebaseAuthMiddleware` extracts and verifies the Firebase ID token from `Authorization: Bearer <token>`, then stores the decoded `FirebaseToken` in `HttpContext.Items["User"]`. Controllers use `[FirebaseAuthorize]` (a custom `IAuthorizationFilter` in `Utils/FirebaseAuthorizeAttribute.cs`) — not ASP.NET's built-in `[Authorize]`. Endpoints that should be public use `[AllowAnonymous]`.

**Service registration:** Services decorated with `[ScopedService]` are auto-registered via Scrutor's assembly scan in `Program.cs`. `UserService` and `FirebaseService` are registered explicitly. `FirebaseService` is a singleton and is warmed up immediately on startup.

**Error handling:** Throw `AppException(ErrorCode.XYZ)` to return structured error responses. `GlobalExceptionHandler` middleware maps `AppException` → error metadata, `ValidationException` → 422, and unhandled exceptions → 500. All responses use `ApiResponse<T>` with `Success`, `Code`, `Message`, and `Result` fields.

**Error codes** are defined as enum values in `backend/Enums/ErrorCode.cs` with `[ErrorMeta(code, message, httpStatus)]` attributes. Error ranges: 1xxx = auth, 2xxx = user, 3xxx = message, 4xxx = conversation, 5xxx = feed, 9xxx = common.

**DTOs and mapping:** Request DTOs live in `dtos/Request/`, response DTOs in `dtos/Response/`. Mapster handles mapping; configs are in `Mappings/`. FluentValidation validators are in `Validators/` and auto-registered.

**JSON naming:** Both REST controllers and SignalR hub are configured with `SnakeCaseLower` — all payloads use `snake_case` in transit. The `SignalRService` event handlers accept both snake_case and PascalCase keys (e.g. `data['conversation_id'] ?? data['ConversationId']`) to handle both directions.

**Background services:** `StoryExpirationService` and `DisappearingMessageService` run as hosted services.

**In-memory cache in ChatService:** `ConversationResponse` and user objects are cached for 5 minutes in static `ConcurrentDictionary` fields — mutations must invalidate or update these caches to stay consistent.

### Frontend (React 18 + Vite + Anime.js)

```
src/
├── lib/             # apiConfig, httpClient, signalr, firebase, anime, agora, mediaRecorder, fcm, geolocation, format
├── theme/           # tokens.js, ThemeProvider.jsx, global.css (design tokens + dark/light)
├── i18n/            # i18next + vi.json, en.json
├── services/        # auth.service, chat.service, friend.service, feed.service, profile.service, feedback.service
├── store/           # Zustand stores: auth, ui, chat, friend, feed, call, profile
├── hooks/           # useAppBootstrap, useFx
├── components/
│   ├── ui/          # Button, Input, Card, Modal, Avatar, Badge, Toast, Spinner
│   ├── layout/      # AppShell, TopBar, BottomNav (page transition với Anime.js)
│   ├── chat/        # MessageBubble, ChatComposer
│   ├── feed/        # (đang phát triển thêm)
│   └── friends/     # (đang phát triển thêm)
├── pages/
│   ├── auth/        # Login, SignUp, OtpVerify, SetPassword, EnterName, PersonalInfo, UpdateAvatar
│   ├── chat/        # ChatList, ChatRoom, NewConversation, GroupInfo
│   ├── feed/        # Newsfeed, CreatePost, CreateStory, StoryViewer
│   ├── friends/     # FriendList, FriendRequests, AddFriend, Contacts
│   ├── profile/     # Profile, MyProfile
│   ├── call/        # CallRoom
│   ├── Home.jsx, NotFound.jsx
└── router/          # React Router DOM 6.26.2 với auth guards (RequireAuth, RedirectIfAuth)
```

**Routing:** React Router DOM 6.26.2 với auth-guard redirect logic trong `src/router/index.jsx`. `RequireAuth` chỉ render `<Outlet />` nếu user đã đăng nhập; `RedirectIfAuth` đẩy user đã login ra khỏi auth routes về `/chat-list`.

**State management:** Zustand (`store/*Store.js`) — thay thế Provider/BLoC pattern cũ. Mỗi store là một hook với state + actions; components subscribe qua selector.

**API calls:** `httpClient.js` (wrapper quanh `fetch`) — tự động gắn Firebase ID token vào header `Authorization: Bearer <token>`, tự refresh + retry khi 401. Base URL cấu hình qua `VITE_API_BASE_URL`. Proxy `/api` + `/hubs` qua Vite dev server sang `http://localhost:5244`.

**Realtime:** `@microsoft/signalr` 8.0.7. `signalr.js` cung cấp `createChatConnection({userId})` cho `/hubs/chat` và `createFriendConnection()` cho `/hubs/friend`. `accessTokenFactory` tự lấy Firebase ID token. Auto-reconnect với delays `[2000, 5000, 10000, 30000]` ms.

**ChatStore lifecycle:** `useChatStore.init(uid)` được gọi sau login từ `useAppBootstrap`. Nó kết nối SignalR, load conversations, bắt đầu heartbeat 3 phút, lưu FCM token. Store lắng nghe `visibilitychange` để gọi `SetOnline` / `SetOffline`.

**Online presence:** Redis (backend) lưu online status với TTL. Frontend refresh mỗi 3 phút qua SignalR `Heartbeat`. App resume → `SetOnline`; pause → `SetOffline`. `ChatHub` track `_onlineUsers` và `_connections` in-memory.

**Optimistic UI for messages:** `useChatStore.sendMessage()` tạo message tạm với id `_pending_<timestamp>` + status `sending`. Khi server echo `MessageSent` với `clientTempId`, message tạm được replace in-place.

**Animation:** Anime.js 4.0.2 — presets trong `src/lib/anime.js`: `staggerCards` (reveal list), `handArc` (FAB menu), `fxBurst` (send message), `ripple` (button press), `pageIn` (page transition), `likeBounce`, `sheetIn`. Tôn trọng `prefers-reduced-motion`.

### Admin dashboard (`web_admin/`)

`web_admin` is a standalone Flutter Web app — it does **not** call the ASP.NET backend. It talks to Firebase Auth and Firestore directly via the `firebase_auth`/`cloud_firestore` SDKs, using `flutter_riverpod` for state and `go_router` for routing.

**Auth:** there's a single hardcoded admin account, not Firebase user records. `AuthRepositoryImpl.signIn()` (`lib/features/auth/data/auth_repository_impl.dart`) checks the entered email/password against `ADMIN_EMAIL`/`ADMIN_PASSWORD` from `.env`, then signs into Firebase Auth with those same credentials just to obtain a valid token for Firestore security rules. `routerProvider` (`lib/core/router/router.dart`) redirects based on `authStateProvider`.

**Feature structure:** each feature under `lib/features/<feature>/` follows `domain/` (repository interface + models), `data/` (Firestore-backed repository impl), `presentation/` (Riverpod providers + pages) — no code generation, repositories are constructed by hand. Features: `admins`, `auth`, `dashboard`, `feedbacks`, `feeds`, `friendships`, `hidden_posts`, `notifications`, `reports`, `users`.

**Firestore collection names** are centralized in `lib/core/constants/app_constants.dart` (`AppConstants.usersCollection`, etc.) — add new collection names there rather than inlining strings.

This app reads/writes the *same* Firestore collections the backend and mobile app use (`users`, `feeds`, `friendships`), plus admin-only collections (`admin_notifications`, `feedbacks`, `hidden_posts`, `reports`, `admins`). Since there's no backend layer here, any business-rule validation the backend normally enforces (e.g. via `AppException`) is **not** applied to writes made from this app — be careful when adding mutations.

### Cloud Functions (`functions/`)

A single Firebase Cloud Function in `functions/index.js` (`onNotificationCreated`) triggers on creation of an `admin_notifications/{notifId}` document and dispatches the FCM push: to the `all_users` topic when `target_audience === 'all'`, or to the specific user's `fcm_token` (looked up from `users/{target_user_id}`) when `target_audience === 'specific'`. It only fires when the document's `status` field is `'sent'` — this is the actual delivery mechanism behind notifications created in `web_admin`'s `notifications` feature. Deploy with `firebase deploy --only functions` from the repo root (requires `cd functions && npm install` first).

## Call Flow

Voice/video calls use Agora RTC for media and SignalR for signaling. The Agora token is generated **client-side** in `AgoraConfig.generateToken()` using the app certificate from `.env`. Channel name is deterministic: sorted `[uid1, uid2].join('_')`.

Signaling sequence:
1. Caller → `InitiateCall` (SignalR) → backend pushes `IncomingCall` to callee via SignalR group, and sends FCM to callee if offline.
2. Callee accepts → `AcceptCall` → backend pushes `CallAccepted` to caller.
3. Both sides join the Agora channel independently using the same generated channel name.
4. Either side ends → `EndCall` → backend pushes `CallEnded` to the other side.
5. `ChatProvider.saveCallMessage()` saves the call record as a `type: 'call'` message via REST API.

The `CallProvider` manages call state (`dialing → active → ended/rejected/missed`) and a live duration timer. `ChatProvider._onIncomingCall()` bridges the SignalR event to `CallProvider.receiveIncomingCall()`.

## SignalR Hub Events

**ChatHub** (client → server):
`SendMessage`, `UserTyping`, `MarkAsRead`, `MarkAsDelivered`, `ReactToMessage`, `DeleteMessage`, `UpdateMessage`, `CreateConversation`, `AddParticipants`, `RemoveParticipant`, `UpdateGroup`, `InitiateCall`, `AcceptCall`, `RejectCall`, `EndCall`, `Heartbeat`, `SetOnline`, `SetOffline`

**ChatHub** (server → client):
`ReceiveMessage`, `MessageSent`, `UserTyping`, `MessageRead`, `MessageDelivered`, `MessageReactionUpdated`, `MessageDeleted`, `MessageUpdated`, `UserStatusChanged`, `ConversationCreated`, `GroupUpdated`, `ParticipantsAdded`, `ParticipantRemoved`, `RemovedFromConversation`, `IncomingCall`, `CallAccepted`, `CallRejected`, `CallEnded`, `Error`

**FriendHub** pushes friendship events to `user_{uid}` groups from `FriendshipService` via `IHubContext<FriendHub>`.

## Key Conventions

- Controllers extract `uid` by casting `HttpContext.Items["User"]` to `FirebaseToken` — use the existing `GetUserIdFromToken()` pattern.
- New services that need request scope: add `[ScopedService]` attribute instead of registering manually in `Program.cs`.
- Flutter feature modules in `lib/features/` follow the pattern: `screens/`, `providers/` (BLoC), `widgets/`, `services/`.
- The `.env` file in `frontend/` must be listed under `assets:` in `pubspec.yaml` (already present).
- FCM push is fire-and-forget inside `Task.Run()` in `ChatHub` — it must not block the hub method.
- When adding a new Firestore query that filters by membership, follow the `WhereArrayContains("participant_ids", userId)` pattern used in `ChatService`.
