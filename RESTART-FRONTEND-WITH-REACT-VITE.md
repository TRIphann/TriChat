# TriChat — Kế hoạch Xóa Flutter Frontend & Viết Lại Bằng React + Vite + React Router DOM + Anime.js

> **Tài liệu này dành cho AI/Developer thực thi việc thay thế hoàn toàn thư mục `frontend/` (Flutter mobile/web)** bằng một SPA viết bằng **React 18.3.1** + **Vite 5.4.10** + **React Router DOM 6.26.2** + **Anime.js 4.0.2** với phong cách thiết kế cao cấp, sang trọng, cinematic.
>
> **Lưu ý quan trọng về stack:** Người dùng yêu cầu "React + Next.js" nhưng đồng thời liệt kê **Vite 5.4.10** làm công cụ build. Vì **Next.js** không thể dùng chung với **Vite** (Next.js dùng React bundler riêng dựa trên Turbopack/webpack), tài liệu này tuân theo **danh sách framework cụ thể đã chốt**: **React 18.3.1 + Vite 5.4.10 + React Router DOM 6.26.2 + Anime.js 4.0.2**. Nếu muốn Next.js thật sự, xem mục 14 "Phương án thay thế".

---

## 1. Mục tiêu

1. **Xóa sạch** thư mục `frontend/` (Flutter) — toàn bộ code Dart, native build folders (android/ios/macos/linux/windows/web), assets, build artifacts, `pubspec.*`, `.dart_tool/`, `.flutter-plugins-dependencies`, `analyze_output.txt`, `tools/`, `firebase.json`, `firepit-log.txt`.
2. **Tạo lại frontend dạng SPA** bằng React + Vite, giữ nguyên **tất cả tính năng nghiệp vụ** (auth, chat 1-1/nhóm, gọi thoại/video, bảng tin/stories, bạn bè, hồ sơ, phản hồi) và **kết nối nguyên xi** với backend ASP.NET Core + Firebase + SignalR + Cloudinary hiện có.
3. **Thiết kế lại phong cách** theo hướng **high-end editorial** với Anime.js làm engine animation chính (card reveal, hand arc, fx burst, micro-interactions).
4. **Tối ưu trải nghiệm web** (responsive, PWA-ready, dark/light mode, accessibility, bundle splitting).

---

## 2. Bối cảnh dự án (đã đọc kỹ)

### 2.1. Cấu trúc hiện tại (sau khi đọc toàn bộ project)

```
D:\Bai_tap\btl\pv\
├── .agents/                  # AI skills (giữ nguyên)
├── .vscode/                  # Cấu hình VSCode (giữ nguyên)
├── backend/                  # ASP.NET Core 8 — KHÔNG ĐỔI
│   ├── Controllers/          # Auth, Chat, Feed, Friend, Otp, User
│   ├── Hubs/                 # ChatHub, FriendHub (SignalR)
│   ├── Services/             # Chat, Firebase, Cloudinary, Fcm, Friendship, Redis, …
│   ├── Middleware/           # FirebaseAuthMiddleware, GlobalExceptionHandler
│   ├── dtos/, Enums/, Exceptions/, Mappings/, Validators/, Attributes/, …
│   ├── Program.cs            # JSON SnakeCaseLower + SignalR + CORS
│   ├── appsettings*.json
│   ├── Dockerfile
│   └── backend.csproj
├── frontend/                 # ← SẼ XÓA TOÀN BỘ
│   ├── lib/                  # ~80 file Dart (xem §3)
│   ├── android/, ios/, macos/, linux/, windows/, web/   # ← XÓA
│   ├── assets/, build/, .dart_tool/, test/, tools/
│   ├── pubspec.yaml, pubspec.lock
│   ├── firebase.json, firepit-log.txt
│   └── *.env, *.gitignore, analyze_output.txt, devtools_options.yaml, analysis_options.yaml, .metadata, .flutter-plugins-dependencies
├── functions/                # Cloud Functions (giữ nguyên)
│   └── index.js              # onNotificationCreated → FCM dispatch
├── scripts/                  # PowerShell scripts (giữ nguyên)
├── web_admin/                # Flutter Web Admin Dashboard — KHÔNG ĐỤNG
├── docker-compose.yml, Dockerfile, netlify.toml, README.md, CLAUDE.md, zalo_lite.sln, .gitignore, .env.example, skills-lock.json
```

### 2.2. Stack backend đang dùng (giữ nguyên)

| Thành phần | Chi tiết |
|---|---|
| Runtime | .NET 8 (`backend.csproj`) |
| Auth | Firebase Admin SDK + JWT middleware (header `Authorization: Bearer <Firebase ID token>`) |
| Database | Firestore (collections: `users`, `conversations/{id}/messages`, `friendships`, `feeds`, `admin_notifications`, `feedbacks`, …) |
| Realtime | SignalR — `/hubs/chat` và `/hubs/friend` (snake_case JSON) |
| Cache | Upstash Redis (REST) — `IKeyValueStore` |
| Media upload | Cloudinary (qua `CloudinaryService`) |
| Push | FCM (`FcmService` trong backend + Cloud Function `onNotificationCreated`) |
| SMTP | Gmail SMTP cho OTP |
| Validation | FluentValidation, Mapster mapping |
| Errors | `AppException(ErrorCode.XYZ)` → `GlobalExceptionHandler` |
| Hosting | Render (`https://trichat.onrender.com`) + Netlify frontend |

### 2.3. Tính năng hiện có (phải port đầy đủ)

| Nhóm | Tính năng |
|---|---|
| Auth | Đăng ký email + mật khẩu, đăng nhập, OTP email (quên/đặt lại mật khẩu), cập nhật tên + avatar + ngày sinh + bio |
| Chat 1-1 | Danh sách hội thoại, gửi text/image/audio/file/location, reaction, reply, forward, edit, recall (xóa cho mọi người), ẩn cho tôi, đánh dấu đã đọc/đã nhận, typing indicator, ghim tin nhắn, online status, last seen |
| Chat nhóm | Tạo nhóm, thêm/xóa thành viên, đổi tên/avatar/mô tả nhóm, cài đặt nhóm (chỉ admin gửi, chỉ admin sửa info, cần duyệt vào nhóm), pin/unpin, leave group, đếm thành viên |
| Cuộc gọi | Voice + Video qua WebRTC, signaling bằng SignalR (Initiate/Accept/Reject/End), incoming call screen, lưu log cuộc gọi dạng tin nhắn (`type: 'call'`), cuộc gọi nhỡ |
| Bảng tin (Feed) | Newsfeed (posts của mình + bạn bè), Stories (24h), tạo post (text/image/video), tạo story (image + text overlay), like/unlike, comment, share ẩn |
| Bạn bè | Danh sách bạn, lời mời đến/đi, tìm kiếm user, gửi/chấp nhận/từ chối lời mời, hủy kết bạn, block/unblock, danh sách nhóm, danh sách sinh nhật bạn bè |
| Hồ sơ | Xem/sửa hồ sơ cá nhân, xem hồ sơ người khác, tab bài viết/ảnh/video/bạn bè, đổi avatar, đổi mật khẩu |
| Phản hồi | Modal đánh giá sao + nhập tiêu đề/nội dung, gửi backend, auto-close sau 8s |
| Hệ thống | Dark/Light mode, đa ngôn ngữ (vi/en), thông báo local, FCM push, online heartbeat (3 phút), `AppLifecycleState` resume/pause |

### 2.4. Routing hiện tại (Flutter `go_router` — sẽ chuyển sang React Router)

```
/                            HomeView (splash giới thiệu)
/load                        LoadView (splash + check auth)
/login                       LoginView
/sign-up                     SignUpView
/set-password                ResetPasswordView (email extra)
/reset-password              ResetPasswordView
/enter-name                  EnterNameView
/personal-info               PersonalInfoView
/update-avatar               UpdateAvatarView
/chat-list                   ChatListView (route chính sau login)
/newfeed                     NewfeedScreen
/story-viewer                StoryViewerScreen
/create-story                CreateStoryScreen
/profile                     ProfileScreen (targetUserId extra)
/my-profile                  MyProfileScreen
/demo-profile                UserProfileScreen
```

### 2.5. SignalR events (giữ nguyên contract)

**ChatHub** — client → server: `SendMessage, UserTyping, MarkAsRead, MarkAsDelivered, ReactToMessage, DeleteMessage, UpdateMessage, CreateConversation, AddParticipants, RemoveParticipant, UpdateGroup, InitiateCall, AcceptCall, RejectCall, EndCall, Heartbeat, SetOnline, SetOffline`

**ChatHub** — server → client: `ReceiveMessage, MessageSent, UserTyping, MessageRead, MessageDelivered, MessageReactionUpdated, MessageDeleted, MessageUpdated, UserStatusChanged, ConversationCreated, GroupUpdated, ParticipantsAdded, ParticipantRemoved, RemovedFromConversation, IncomingCall, CallAccepted, CallRejected, CallEnded, Error`

**FriendHub** — server → client: `FriendRequestReceived, FriendRequestAccepted, FriendRequestDeclined, FriendRequestCancelled, FriendUnfriended`

### 2.6. Endpoints backend đang dùng (giữ nguyên URL)

```
POST /api/otp/generate                # public
POST /api/otp/verify                  # public
POST /api/user                        # public (register) / fallback uid từ body
GET  /api/user/me                     # current user
GET  /api/user/{id}                   # by id
GET  /api/user                        # all
PUT  /api/user/me                     # update
PUT  /api/user/{id}                   # admin update
PATCH /api/user/avatar                # multipart file
DELETE /api/user/{id}                 # admin
GET  /api/user/search?q=              # search

POST /api/user/fcm-token              # body {Token}
GET  /api/friends
GET  /api/friends/user/{userId}
GET  /api/friends/requests/received
GET  /api/friends/requests/sent
GET  /api/friends/blocked
GET  /api/friends/status/{targetUserId}
POST /api/friends/requests            # body {AddresseeId, SourceType}
PATCH /api/friends/requests/{fid}     # body {Accept}
DELETE /api/friends/requests/{fid}
DELETE /api/friends/{targetUserId}
POST /api/friends/block/{targetUserId}
DELETE /api/friends/block/{targetUserId}

GET  /api/chat/conversations
GET  /api/chat/conversations/{id}
POST /api/chat/conversations
PUT  /api/chat/conversations/group
POST /api/chat/conversations/participants
DELETE /api/chat/conversations/{id}
PUT  /api/chat/conversations/{id}/group-settings
POST /api/chat/conversations/{id}/join-requests
GET  /api/chat/conversations/{id}/join-requests
POST /api/chat/conversations/{id}/join-requests/{uid}/approve
POST /api/chat/conversations/{id}/join-requests/{uid}/reject

GET  /api/chat/conversations/{cid}/messages
POST /api/chat/messages
PUT  /api/chat/messages
DELETE /api/chat/conversations/{cid}/messages/{mid}
POST /api/chat/messages/react
POST /api/chat/conversations/{cid}/messages/{mid}/read
POST /api/chat/conversations/{cid}/messages/{mid}/delivered
POST /api/chat/conversations/{cid}/messages/{mid}/hide
POST /api/chat/conversations/{cid}/pin/{mid}
DELETE /api/chat/conversations/{cid}/pin

POST /api/chat/upload                 # multipart: ConversationId + file
PUT  /api/chat/conversations/{id}/settings
GET  /api/chat/conversations/{id}/settings
PUT  /api/chat/conversations/{id}/settings/disappearing
PUT  /api/chat/conversations/{cid}/members/{uid}/nickname

GET  /api/feed
GET  /api/feed/newsfeed
GET  /api/feed/stories
... (post/comment/like/share/hide CRUD đầy đủ trong FeedController)

SignalR: /hubs/chat?userId=<uid>&access_token=<firebase>
         /hubs/friend?access_token=<firebase>
```

> Tất cả payload mặc định là **snake_case** (do `JsonNamingPolicy.SnakeCaseLower`). Một vài DTO nội bộ (UpdateUserRequest, SendMessageRequest, …) được client truyền **PascalCase** theo C# binding — xem chi tiết trong từng service. Logic này được giữ nguyên trong React.

---

## 3. Phạm vi cần xóa trong `frontend/`

### 3.1. Files & folders xóa tuyệt đối

```bash
# Toàn bộ thư mục
rm -rf d:/Bai_tap/btl/pv/frontend/

# Hoặc nếu muốn giữ lại từng phần (khuyến nghị xóa nguyên folder để tránh sót)
rm -rf d:/Bai_tap/btl/pv/frontend/lib/
rm -rf d:/Bai_tap/btl/pv/frontend/android/
rm -rf d:/Bai_tap/btl/pv/frontend/ios/
rm -rf d:/Bai_tap/btl/pv/frontend/macos/
rm -rf d:/Bai_tap/btl/pv/frontend/linux/
rm -rf d:/Bai_tap/btl/pv/frontend/windows/
rm -rf d:/Bai_tap/btl/pv/frontend/web/
rm -rf d:/Bai_tap/btl/pv/frontend/assets/
rm -rf d:/Bai_tap/btl/pv/frontend/build/
rm -rf d:/Bai_tap/btl/pv/frontend/test/
rm -rf d:/Bai_tap/btl/pv/frontend/tools/
rm -rf d:/Bai_tap/btl/pv/frontend/.dart_tool/
rm -rf d:/Bai_tap/btl/pv/frontend/pubspec.yaml
rm -rf d:/Bai_tap/btl/pv/frontend/pubspec.lock
rm -rf d:/Bai_tap/btl/pv/frontend/.flutter-plugins-dependencies
rm -rf d:/Bai_tap/btl/pv/frontend/firebase.json
rm -rf d:/Bai_tap/btl/pv/frontend/firepit-log.txt
rm -rf d:/Bai_tap/btl/pv/frontend/.metadata
rm -rf d:/Bai_tap/btl/pv/frontend/analysis_options.yaml
rm -rf d:/Bai_tap/btl/pv/frontend/devtools_options.yaml
rm -rf d:/Bai_tap/btl/pv/frontend/.env
rm -rf d:/Bai_tap/btl/pv/frontend/analyze_output.txt
```

### 3.2. Mapping các file Dart hiện có → module React tương ứng

| File Flutter | React module |
|---|---|
| `lib/main.dart` + `lib/main_mobile.dart` + `lib/main_stub.dart` | `src/main.jsx` + `src/App.jsx` |
| `lib/apps/router.dart` | `src/router/index.jsx` |
| `lib/config/app_colors.dart`, `app_theme.dart`, `app_typography.dart`, `app_spacing.dart`, `dark_mode_config.dart`, `tri_chat_logo.dart` | `src/theme/tokens.js`, `src/theme/Provider.jsx`, `src/theme/global.css` |
| `lib/config/api_config.dart` | `src/lib/apiConfig.js` |
| `lib/services/dio_client.dart` | `src/lib/httpClient.js` |
| `lib/services/auth_service.dart` | `src/services/auth.service.js` |
| `lib/services/chat/chat_service.dart`, `signalr_service.dart` | `src/services/chat.service.js`, `src/realtime/signalr.js` |
| `lib/services/chat/chat_service_web.dart` | merge vào `chat.service.js` |
| `lib/services/call_notification_service*.dart`, `message_notification_service*.dart` | `src/realtime/notifications.js` (gộp) |
| `lib/services/flutter_callkeep*.dart`, `file_helper*`, `file_ops*`, `geolocator*`, `permission_handler*`, `record*`, `platform*` | không cần (web) → xóa |
| `lib/services/feature/friend_service.dart`, `friend_hub_service.dart` | `src/services/friend.service.js`, `src/realtime/friendHub.js` |
| `lib/services/feature/feedback_service.dart` | `src/services/feedback.service.js` |
| `lib/services/feature/feed_service.dart`, `story_service.dart` | `src/services/feed.service.js` |
| `lib/services/profile/profile_service.dart` | `src/services/profile.service.js` |
| `lib/providers/chat_provider.dart` | `src/store/chatStore.js` (zustand) |
| `lib/providers/call_provider.dart` | `src/store/callStore.js` |
| `lib/providers/friends/friend_provider.dart` | `src/store/friendStore.js` |
| `lib/providers/newfeed/feed_provider.dart`, `story_provider.dart` | `src/store/feedStore.js` |
| `lib/providers/profile/profile_provider.dart` | `src/store/profileStore.js` |
| `lib/views/home/load_view.dart`, `home_view.dart` | `src/pages/Splash.jsx`, `src/pages/Home.jsx` |
| `lib/views/auth/*.dart` (login, sign_up, otp_verify, enter_name, personal_info, set_password, update_avatar) | `src/pages/auth/*.jsx` |
| `lib/views/chat/chat_list_view.dart`, `chat_screen.dart`, `chat_content_panel.dart`, `new_conversation_screen.dart`, `group_info_screen.dart`, `location_map_screen.dart` | `src/pages/chat/*.jsx` |
| `lib/views/contacts/contacts_view.dart` | `src/pages/contacts/*.jsx` |
| `lib/features/calling/*.dart` (call_screen, incoming_call_screen, call_screen_native, call_screen_web) | `src/pages/call/*.jsx` |
| `lib/features/feedback/*.dart` | `src/features/feedback/*.jsx` |
| `lib/features/friends/*.dart` (screens + widgets + providers + services) | `src/features/friends/*.jsx` |
| `lib/features/newfeed/*.dart` | `src/features/feed/*.jsx` |
| `lib/features/profile/*.dart` | `src/features/profile/*.jsx` |
| `lib/widgets/chat/*.dart` | `src/components/chat/*.jsx` |
| `lib/component/*.dart` | `src/components/ui/*.jsx` |
| `lib/models/*.dart` | `src/types/*.js` (JSDoc) |
| `lib/utils/app_localizations.dart`, `validator.dart` | `src/i18n/*.js` |

> **Tổng cộng ~80 file Dart cần được thay thế bằng ~120 file JS/JSX/CSS.**

---

## 4. Stack mới (đã chốt)

| Layer | Công nghệ | Phiên bản |
|---|---|---|
| UI Framework | **React** | **18.3.1** |
| Build tool / Dev server | **Vite** + `@vitejs/plugin-react` | **5.4.10** |
| Routing | **React Router DOM** | **6.26.2** |
| Animation | **Anime.js** v4 | **4.0.2** |
| State management | Zustand + TanStack Query | 4.5 / 5.51 |
| Styling | CSS Modules + CSS variables + PostCSS + Autoprefixer | (latest stable) |
| Forms | react-hook-form + zod | 7.52 / 3.23 |
| HTTP | native `fetch` wrapped trong interceptor tương tự Dio | – |
| Realtime | `@microsoft/signalr` 8.x | 8.0.7 |
| Firebase | `firebase` SDK modular | 10.13 |
| Maps | `leaflet` + `react-leaflet` (thay cho flutter_map) | 1.9 / 4.2 |
| Audio recording | `mediarecorder-polyfill` + Web Audio API | – |
| QR | `qrcode` + `html5-qrcode` | 1.5 / 2.3 |
| Calendar | FullCalendar React | 6.1 |
| i18n | `i18next` + `react-i18next` | 23 / 14 |
| PWA | `vite-plugin-pwa` | 0.20 |
| Lint | ESLint + Prettier | 9 / 3.3 |
| Test (optional) | Vitest + React Testing Library | 2 / 16 |

> **Anime.js 4.0.2** dùng cho: page transitions, card reveal stagger, hand-arc của FAB, fx burst khi gửi tin nhắn, micro-interactions trên reaction/avatar ripple, skeleton shimmer thay vì keyframe CSS, scroll-linked reveals, modal/sheet springy entrance.

---

## 5. Hướng dẫn thực thi — Từng bước

### Bước 1 — Sao lưu & dọn dẹp Flutter

```bash
# 1. Commit trạng thái hiện tại trước khi xóa
cd d:/Bai_tap/btl/pv
git add -A && git commit -m "chore: snapshot before flutter frontend removal"

# 2. Xóa toàn bộ frontend Flutter
rm -rf frontend/

# 3. Cập nhật .gitignore gốc — bỏ các rule frontend-specific
# Mở .gitignore ở root và xóa các dòng:
#   frontend/build/
#   frontend/.dart_tool/
#   frontend/tools/replace_neutral_colors.dart
#   frontend/tools/replace_grey_colors.dart
#   frontend/tools/add_import.js
#   frontend/analyze_output.txt
```

### Bước 2 — Khởi tạo Vite project mới

```bash
cd d:/Bai_tap/btl/pv
npm create vite@latest frontend -- --template react          # React 18.3.1 + Vite 5.4.10
cd frontend
npm install
```

> Nếu CLI hỏi "directory not empty" (vì folder đã xóa nhưng `.gitignore` còn track) thì chạy `git rm -r --cached frontend` trước.

### Bước 3 — Cài dependencies đúng phiên bản chốt

```bash
npm install react@18.3.1 react-dom@18.3.1
npm install react-router-dom@6.26.2
npm install animejs@4.0.2
npm install zustand@4.5.4 @tanstack/react-query@5.51.23
npm install react-hook-form@7.52.2 zod@3.23.8
npm install firebase@10.13.2
npm install @microsoft/signalr@8.0.7
npm install leaflet@1.9.4 react-leaflet@4.2.1
npm install qrcode@1.5.4 html5-qrcode@2.3.8
npm install @fullcalendar/react@6.1.15 @fullcalendar/daygrid@6.1.15
npm install i18next@23.15.1 react-i18next@14.1.3
npm install -D vite@5.4.10 @vitejs/plugin-react@4.3.2
npm install -D vite-plugin-pwa@0.20.5
npm install -D postcss@8.4.47 autoprefixer@10.4.20
npm install -D eslint@9.10.0 prettier@3.3.3
```

### Bước 4 — Cấu trúc thư mục React đề xuất

```
frontend/
├── index.html
├── vite.config.js
├── package.json
├── .env                                # API_BASE_URL, AGORA_APP_ID, AGORA_APP_CERTIFICATE, FIREBASE_*
├── .env.example
├── public/
│   ├── icons/                          # favicon, splash
│   └── manifest.webmanifest
├── src/
│   ├── main.jsx
│   ├── App.jsx
│   ├── router/
│   │   ├── index.jsx
│   │   ├── ProtectedRoute.jsx
│   │   └── guards.jsx
│   ├── theme/
│   │   ├── tokens.js                   # toàn bộ AppColors / AppSpacing / AppTypography
│   │   ├── ThemeProvider.jsx           # dark/light
│   │   ├── global.css                  # reset + CSS variables + keyframes
│   │   └── animations.css              # base @keyframes (shimmer, handArc, fxBurst)
│   ├── i18n/
│   │   ├── index.js
│   │   ├── vi.json
│   │   └── en.json
│   ├── lib/
│   │   ├── apiConfig.js                # baseUrl resolution
│   │   ├── httpClient.js               # fetch wrapper + auth interceptor + 401 retry
│   │   ├── signalr.js                  # ChatHub + FriendHub factories
│   │   ├── firebase.js                 # initApp + auth
│   │   ├── fcm.js                      # FCM web push
│   │   ├── agora.js                    # RTC client + token gen
│   │   ├── geolocation.js              # navigator.geolocation
│   │   ├── mediaRecorder.js            # audio capture
│   │   ├── filePicker.js               # <input type="file">
│   │   ├── imagePreview.js
│   │   ├── pwa.js
│   │   └── anime.js                    # presets: staggerCard, handArc, fxBurst, ripple
│   ├── types/
│   │   ├── user.js
│   │   ├── conversation.js
│   │   ├── message.js
│   │   ├── friendship.js
│   │   ├── feed.js
│   │   ├── story.js
│   │   └── call.js
│   ├── services/
│   │   ├── auth.service.js
│   │   ├── user.service.js
│   │   ├── friend.service.js
│   │   ├── chat.service.js
│   │   ├── feed.service.js
│   │   ├── story.service.js
│   │   ├── profile.service.js
│   │   ├── feedback.service.js
│   │   └── notification.service.js
│   ├── store/
│   │   ├── authStore.js
│   │   ├── chatStore.js
│   │   ├── callStore.js
│   │   ├── friendStore.js
│   │   ├── feedStore.js
│   │   ├── profileStore.js
│   │   └── uiStore.js                  # dark mode, locale, layout
│   ├── hooks/
│   │   ├── useAuth.js
│   │   ├── useChat.js
│   │   ├── useFriends.js
│   │   ├── useFeed.js
│   │   ├── useSignalR.js
│   │   ├── useFcm.js
│   │   ├── useAgora.js
│   │   ├── useVoiceRecorder.js
│   │   ├── useScrollPosition.js
│   │   └── useReducedMotion.js
│   ├── components/
│   │   ├── ui/                         # Button, Input, Card, Modal, Sheet, Toast, Avatar, Badge, Skeleton, …
│   │   ├── layout/                     # AppShell, TopBar, SideRail, BottomNav, RightPanel
│   │   ├── chat/                       # MessageBubble, ChatComposer, ConversationTile, TypingDots, ReactionPicker, PinnedBanner, …
│   │   ├── feed/                       # PostCard, StoryRail, StoryViewer, CommentSheet, MediaGrid
│   │   ├── friends/                    # FriendGridCard, FriendListRow, RequestRow
│   │   └── call/                       # CallSurface, IncomingCallSheet, CallControls
│   ├── pages/
│   │   ├── Splash.jsx                  # /load
│   │   ├── Home.jsx                    # / (landing)
│   │   ├── auth/
│   │   │   ├── Login.jsx
│   │   │   ├── SignUp.jsx
│   │   │   ├── OtpVerify.jsx
│   │   │   ├── EnterName.jsx
│   │   │   ├── PersonalInfo.jsx
│   │   │   ├── SetPassword.jsx
│   │   │   └── UpdateAvatar.jsx
│   │   ├── chat/
│   │   │   ├── ChatList.jsx            # /chat-list (route chính)
│   │   │   ├── ChatRoom.jsx            # /chat-list/:id
│   │   │   ├── NewConversation.jsx
│   │   │   ├── GroupInfo.jsx
│   │   │   └── LocationMap.jsx
│   │   ├── feed/
│   │   │   ├── Newsfeed.jsx
│   │   │   ├── CreatePost.jsx
│   │   │   ├── CreateStory.jsx
│   │   │   └── StoryViewer.jsx
│   │   ├── friends/
│   │   │   ├── FriendList.jsx
│   │   │   ├── FriendRequests.jsx
│   │   │   ├── AddFriend.jsx
│   │   │   └── Contacts.jsx
│   │   ├── profile/
│   │   │   ├── Profile.jsx
│   │   │   └── MyProfile.jsx
│   │   ├── call/
│   │   │   ├── CallRoom.jsx
│   │   │   └── IncomingCall.jsx
│   │   ├── Feedback.jsx
│   │   └── NotFound.jsx
│   └── styles/
│       ├── tokens.css
│       ├── reset.css
│       └── animations.css
└── README.md
```

### Bước 5 — Cấu hình `vite.config.js`

```js
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      manifest: {
        name: 'TriChat',
        short_name: 'TriChat',
        theme_color: '#0C0A09',
        background_color: '#FAF8F5',
        display: 'standalone',
        icons: [{ src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png' }],
      },
    }),
  ],
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:5244',
      '/hubs': { target: 'http://localhost:5244', ws: true, changeOrigin: true },
    },
  },
  build: {
    target: 'es2022',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          firebase: ['firebase/app', 'firebase/auth', 'firebase/messaging'],
          signalr: ['@microsoft/signalr'],
          maps: ['leaflet', 'react-leaflet'],
          calendar: ['@fullcalendar/react', '@fullcalendar/daygrid'],
        },
      },
    },
  },
});
```

### Bước 6 — Cấu hình `.env`

```ini
# Backend (production: https://trichat.onrender.com — local: http://localhost:5244)
VITE_API_BASE_URL=https://trichat.onrender.com
VITE_AGORA_APP_ID=
VITE_AGORA_AGORA_APP_CERTIFICATE=
# Firebase Web SDK config
VITE_FB_API_KEY=AIzaSyBKUaWo01Sbz4tWevWseHLbbaHkB9mAd2s
VITE_FB_AUTH_DOMAIN=zalo-lite-f2d28.firebaseapp.com
VITE_FB_PROJECT_ID=zalo-lite-f2d28
VITE_FB_STORAGE_BUCKET=zalo-lite-f2d28.firebasestorage.app
VITE_FB_MESSAGING_SENDER_ID=704895954808
VITE_FB_APP_ID=1:704895954808:web:e3e92bc82bdfac0933228d
VITE_FB_MEASUREMENT_ID=G-E5XRXFLN9B
```

### Bước 7 — `src/lib/apiConfig.js`

```js
const fromEnv = (import.meta.env.VITE_API_BASE_URL || '').trim();
const fallback = typeof window !== 'undefined' ? window.location.origin : 'http://localhost:5244';

export const API_BASE_URL = fromEnv || fallback;
export const HUB_BASE_URL = API_BASE_URL;
export const IS_DEV = import.meta.env.DEV;
```

### Bước 8 — `src/lib/httpClient.js`

```js
import { API_BASE_URL } from './apiConfig';
import { auth } from './firebase';

async function refreshToken() {
  const u = auth.currentUser;
  return u ? u.getIdToken(true) : null;
}

async function authHeader(retried = false) {
  const u = auth.currentUser;
  if (!u) return {};
  const tok = await u.getIdToken(false);
  return { Authorization: `Bearer ${tok}` };
}

export async function api(path, { method = 'GET', body, headers = {}, isForm = false } = {}) {
  const finalHeaders = { ...(await authHeader()), ...headers };
  if (!isForm && body && !(body instanceof FormData)) {
    finalHeaders['Content-Type'] = 'application/json';
  }
  let res;
  try {
    res = await fetch(`${API_BASE_URL}${path}`, {
      method,
      headers: finalHeaders,
      body: isForm ? body : (body ? JSON.stringify(body) : undefined),
    });
  } catch (e) {
    throw new Error('network_error');
  }
  if (res.status === 401 && !retried) {
    const tok = await refreshToken();
    if (tok) {
      finalHeaders.Authorization = `Bearer ${tok}`;
      return api(path, { method, body, headers: finalHeaders, isForm });
    }
  }
  const text = await res.text();
  let data; try { data = text ? JSON.parse(text) : null; } catch { data = text; }
  if (!res.ok) {
    const message = (data && typeof data === 'object' && (data.message || data.Message)) || `HTTP ${res.status}`;
    const err = new Error(message);
    err.status = res.status; err.payload = data; throw err;
  }
  return data;
}

export const http = {
  get:    (p, q)         => api(p + (q ? `?${new URLSearchParams(q)}` : '')),
  post:   (p, b, h)      => api(p, { method: 'POST',   body: b, headers: h }),
  put:    (p, b, h)      => api(p, { method: 'PUT',    body: b, headers: h }),
  patch:  (p, b, h)      => api(p, { method: 'PATCH',  body: b, headers: h }),
  delete: (p, h)         => api(p, { method: 'DELETE', headers: h }),
  upload: (p, fd)        => api(p, { method: 'POST', body: fd, isForm: true }),
};
```

### Bước 9 — `src/router/index.jsx` (auth guard)

```jsx
import { createBrowserRouter, Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import AppShell from '../components/layout/AppShell';

const RequireAuth = () => {
  const { user, ready } = useAuth();
  if (!ready) return null;
  return user ? <Outlet /> : <Navigate to="/" replace />;
};

const RedirectIfAuth = () => {
  const { user, ready } = useAuth();
  if (!ready) return null;
  return user ? <Navigate to="/chat-list" replace /> : <Outlet />;
};

export const router = createBrowserRouter([
  { path: '/load', element: <Splash /> },
  { path: '/', element: <Home /> },
  {
    element: <RedirectIfAuth />,
    children: [
      { path: '/login', element: <Login /> },
      { path: '/sign-up', element: <SignUp /> },
      { path: '/set-password', element: <SetPassword /> },
      { path: '/reset-password', element: <SetPassword /> },
      { path: '/enter-name', element: <EnterName /> },
      { path: '/personal-info', element: <PersonalInfo /> },
      { path: '/update-avatar', element: <UpdateAvatar /> },
    ],
  },
  {
    element: <RequireAuth />,
    children: [
      {
        element: <AppShell />,
        children: [
          { path: '/chat-list', element: <ChatList /> },
          { path: '/chat-list/:id', element: <ChatRoom /> },
          { path: '/newfeed', element: <Newsfeed /> },
          { path: '/story-viewer', element: <StoryViewer /> },
          { path: '/create-story', element: <CreateStory /> },
          { path: '/profile', element: <Profile /> },
          { path: '/my-profile', element: <MyProfile /> },
          { path: '/demo-profile', element: <Profile /> },
          { path: '/contacts', element: <Contacts /> },
        ],
      },
    ],
  },
  { path: '*', element: <NotFound /> },
]);
```

### Bước 10 — `src/lib/anime.js` (presets dùng Anime.js 4)

```js
import { animate, createTimeline, stagger, utils } from 'animejs';

/** Card stagger reveal — dùng cho Newsfeed, FriendList, ConversationList */
export function staggerCards(els, { gap = 60, dur = 600, y = 24 } = {}) {
  animate(utils.set(els, { opacity: 0, translateY: y }), {
    opacity: [0, 1],
    translateY: [y, 0],
    delay: stagger(gap),
    duration: dur,
    ease: 'out(3)',
  });
}

/** Hand-arc FAB — khi mở SpeedDial / NewChat menu */
export function handArc(els, { radius = 72, origin = { x: 0, y: 0 } } = {}) {
  animate(els, {
    translateX: (_, i) => Math.cos((Math.PI / 6) * (i + 1)) * radius - origin.x,
    translateY: (_, i) => -Math.sin((Math.PI / 6) * (i + 1)) * radius - origin.y,
    scale: [0.6, 1],
    opacity: [0, 1],
    delay: stagger(40),
    duration: 520,
    ease: 'out(4)',
  });
}

/** FX burst — khi gửi message / like / react */
export function fxBurst(targetEl) {
  const rect = targetEl.getBoundingClientRect();
  const cx = rect.left + rect.width / 2;
  const cy = rect.top + rect.height / 2;
  const burst = document.createElement('div');
  burst.className = 'fx-burst';
  burst.style.cssText = `left:${cx}px;top:${cy}px`;
  document.body.appendChild(burst);
  animate(burst, {
    scale: [0, 1.6, 0],
    opacity: [0, 1, 0],
    duration: 720,
    ease: 'out(3)',
    onComplete: () => burst.remove(),
  });
}

/** Ripple — avatar click, button press */
export function ripple(targetEl, { color = 'rgba(217,119,6,0.35)' } = {}) {
  const r = document.createElement('span');
  const rect = targetEl.getBoundingClientRect();
  const size = Math.max(rect.width, rect.height);
  r.style.cssText = `position:absolute;border-radius:999px;pointer-events:none;background:${color};width:${size}px;height:${size}px;left:${rect.width / 2 - size / 2}px;top:${rect.height / 2 - size / 2}px;`;
  targetEl.style.position ||= 'relative';
  targetEl.style.overflow = 'hidden';
  targetEl.appendChild(r);
  animate(r, {
    scale: [0, 2.4],
    opacity: [0.6, 0],
    duration: 700,
    ease: 'out(3)',
    onComplete: () => r.remove(),
  });
}

/** Page transition timeline */
export function pageIn(el) {
  animate(el, {
    opacity: [0, 1],
    translateY: [12, 0],
    duration: 480,
    ease: 'out(3)',
  });
}
```

### Bước 11 — Thiết kế hệ thống token (`src/theme/tokens.js`)

> Mục tiêu: nâng cấp `AppColors` của Flutter thành một bộ design token **high-end editorial** + **glass/aurora accent**. Tone vàng hổ phách (amber) giữ làm CTA chính, bổ sung thêm **deep noir** + **plasma violet** cho dark mode, **bone cream** + **ash brown** cho light mode, **glass blur** cho card cao cấp.

```js
export const tokens = {
  brand: {
    amber:       '#D97706',
    amberSoft:   '#FEF3C7',
    amberDeep:   '#92400E',
    ember:       '#EA580C',
    emberSoft:   '#FFEDD5',
    rose:        '#E11D48',
    roseSoft:    '#FFE4E6',
    plasma:      '#7C3AED',
    plasmaSoft:  '#EDE9FE',
    ink:         '#0C0A09',
    bone:        '#FAF8F5',
  },
  surface: {
    canvasLight: '#FAF8F5',
    cardLight:   '#FFFFFF',
    elevatedLight: '#FFFCF9',
    surfaceLight: '#F4EFE8',
    canvasDark:  '#0A0907',
    cardDark:    '#161412',
    elevatedDark:'#1F1B17',
    surfaceDark: '#221D18',
    glassLight:  'rgba(255,255,255,0.66)',
    glassDark:   'rgba(22,20,18,0.62)',
  },
  text: {
    primaryLight: '#1C1917',
    secondaryLight:'#57534E',
    tertiaryLight:'#A8A29E',
    primaryDark:  '#FAF8F5',
    secondaryDark:'#A8A29E',
    tertiaryDark: '#57534E',
  },
  border: {
    hairline: 'rgba(28,25,23,0.08)',
    divider:  '#F0EBE3',
    strong:   '#D6D3D1',
    hairDark: 'rgba(250,248,245,0.08)',
  },
  state: {
    success: '#16A34A', successSoft: '#DCFCE7',
    warning: '#D97706', warningSoft: '#FEF3C7',
    danger:  '#DC2626', dangerSoft:  '#FEE2E2',
    info:    '#2563EB', infoSoft:    '#DBEAFE',
  },
  chat: {
    bubbleMineLight: 'linear-gradient(135deg,#D97706 0%,#B45309 100%)',
    bubbleTheirsLight: '#F4EFE8',
    bubbleMineDark:  'linear-gradient(135deg,#292524 0%,#1C1917 100%)',
    bubbleTheirsDark: '#161412',
    textOnMine: '#FFFFFF',
  },
  radius: {
    xs: 6, sm: 10, md: 14, lg: 20, xl: 28, xxl: 36, pill: 999,
  },
  space: {
    1: 4, 2: 8, 3: 12, 4: 16, 5: 20, 6: 24, 8: 32, 10: 40, 12: 48, 16: 64, 20: 80, 24: 96,
  },
  font: {
    sans: '"InterVariable","SF Pro Display","Inter",system-ui,sans-serif',
    serif: '"Fraunces","Source Serif Pro",Georgia,serif',
    mono: '"JetBrains Mono",ui-monospace,SFMono-Regular,monospace',
  },
  shadow: {
    soft:   '0 1px 2px rgba(28,25,23,0.04), 0 8px 24px rgba(28,25,23,0.06)',
    glass:  '0 1px 0 rgba(255,255,255,0.6) inset, 0 24px 60px rgba(28,25,23,0.18)',
    aurora: '0 24px 80px rgba(217,119,6,0.18), 0 8px 24px rgba(124,58,237,0.18)',
    inner:  'inset 0 1px 0 rgba(255,255,255,0.5), inset 0 -1px 0 rgba(0,0,0,0.05)',
  },
  ease: {
    spring:   'cubic-bezier(0.22,1,0.36,1)',
    overshoot:'cubic-bezier(0.34,1.56,0.64,1)',
    soft:     'cubic-bezier(0.4,0,0.2,1)',
  },
};
```

### Bước 12 — `src/theme/global.css` (token → :root, base + utility)

```css
:root {
  --amber:#D97706; --amber-soft:#FEF3C7; --amber-deep:#92400E;
  --ember:#EA580C; --rose:#E11D48; --plasma:#7C3AED; --ink:#0C0A09;
  --canvas:#FAF8F5; --card:#FFFFFF; --elevated:#FFFCF9; --surface:#F4EFE8;
  --text:#1C1917; --text-2:#57534E; --text-3:#A8A29E;
  --hairline:rgba(28,25,23,0.08); --divider:#F0EBE3; --strong:#D6D3D1;
  --shadow-soft:0 1px 2px rgba(28,25,23,0.04), 0 8px 24px rgba(28,25,23,0.06);
  --shadow-glass:0 1px 0 rgba(255,255,255,0.6) inset, 0 24px 60px rgba(28,25,23,0.18);
  --shadow-aurora:0 24px 80px rgba(217,119,6,0.18), 0 8px 24px rgba(124,58,237,0.18);
}
[data-theme='dark'] {
  --canvas:#0A0907; --card:#161412; --elevated:#1F1B17; --surface:#221D18;
  --text:#FAF8F5; --text-2:#A8A29E; --text-3:#57534E;
  --hairline:rgba(250,248,245,0.08); --divider:#1F1B17;
  --shadow-soft:0 1px 2px rgba(0,0,0,0.4), 0 12px 32px rgba(0,0,0,0.5);
  --shadow-glass:0 1px 0 rgba(255,255,255,0.04) inset, 0 24px 60px rgba(0,0,0,0.6);
  --shadow-aurora:0 24px 80px rgba(217,119,6,0.32), 0 8px 24px rgba(124,58,237,0.32);
}

* { box-sizing: border-box; }
html, body, #root { height: 100%; margin: 0; }
body {
  font-family: var(--font-sans,'InterVariable',system-ui,sans-serif);
  background: var(--canvas); color: var(--text);
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}
button { font: inherit; cursor: pointer; }
a { color: inherit; text-decoration: none; }

.glass { background: color-mix(in srgb, var(--card) 70%, transparent); backdrop-filter: blur(20px) saturate(140%); }
.surface-card { background: var(--card); border-radius: 28px; box-shadow: var(--shadow-soft); }
.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { scrollbar-width: none; }
```

### Bước 13 — Mapping chi tiết các service Flutter → React

Mỗi service dưới đây sử dụng `http.*` và **giữ nguyên JSON shape** (snake_case hoặc PascalCase theo từng endpoint mà backend đã commit).

#### 13.1 `src/services/auth.service.js`

```js
import { auth } from '../lib/firebase';
import { http } from '../lib/httpClient';

export const authService = {
  async login(email, password) {
    const cred = await auth.signInWithEmailAndPassword(email, password);
    return cred.user.getIdToken();
  },
  async logout() { await auth.signOut(); },
  async register(req) {
    const cred = await auth.createUserWithEmailAndPassword(req.email, req.password);
    const uid = cred.user.uid;
    await http.post('/api/user', {
      id: uid,
      first_name: req.firstName, last_name: req.lastName,
      email: req.email, password: req.password,
      date_of_birth: req.dateOfBirth, bio: req.bio || '',
    });
    return uid;
  },
  async sendOtp(email) { return http.post('/api/otp/generate', { email }); },
  async verifyOtp(email, otp, cachedOtp) {
    return http.post('/api/otp/verify', { email, otp, cached_otp: cachedOtp });
  },
  async getUserById(id) { return (await http.get(`/api/user/${id}`)).result; },
  async updateMe(payload) { return http.put('/api/user/me', payload); }, // PascalCase từ FE
  async updateAvatar(file) {
    const fd = new FormData(); fd.append('File', file);
    return http.upload('/api/user/avatar', fd);
  },
};
```

#### 13.2 `src/services/chat.service.js`

```js
import { http } from '../lib/httpClient';

export const chatService = {
  conversations:        () => http.get('/api/chat/conversations'),
  conversation:    (id) => http.get(`/api/chat/conversations/${id}`),
  create: (body)        => http.post('/api/chat/conversations', body), // PascalCase
  updateGroup: (body)   => http.put('/api/chat/conversations/group', body),
  addParticipants:(b)   => http.post('/api/chat/conversations/participants', b),
  messages: (id, q={})  => http.get(`/api/chat/conversations/${id}/messages`, q),
  send: (body)          => http.post('/api/chat/messages', body),
  deleteMsg: (cid,mid)  => http.delete(`/api/chat/conversations/${cid}/messages/${mid}`),
  updateMsg:(body)       => http.put('/api/chat/messages', body),
  react:(body)           => http.post('/api/chat/messages/react', body),
  read:(cid,mid)         => http.post(`/api/chat/conversations/${cid}/messages/${mid}/read`),
  delivered:(cid,mid)    => http.post(`/api/chat/conversations/${cid}/messages/${mid}/delivered`),
  hide:(cid,mid)         => http.post(`/api/chat/conversations/${cid}/messages/${mid}/hide`),
  pin:(cid,mid)          => http.post(`/api/chat/conversations/${cid}/pin/${mid}`),
  unpin:(cid)            => http.delete(`/api/chat/conversations/${cid}/pin`),
  uploadMedia: async (cid, file) => {
    const fd = new FormData(); fd.append('ConversationId', cid); fd.append('file', file);
    return http.upload('/api/chat/upload', fd);
  },
};
```

#### 13.3 `src/lib/signalr.js` (ChatHub + FriendHub)

```js
import * as signalR from '@microsoft/signalr';
import { HUB_BASE_URL } from './apiConfig';
import { auth } from './firebase';

export const chatConnection = () => {
  const conn = new signalR.HubConnectionBuilder()
    .withUrl(`${HUB_BASE_URL}/hubs/chat`, {
      skipNegotiation: true,
      transport: signalR.HttpTransportType.WebSockets,
      accessTokenFactory: () => auth.currentUser?.getIdToken() ?? Promise.reject(),
    })
    .withAutomaticReconnect([2000, 5000, 10000, 30000])
    .configureLogging(signalR.LogLevel.Warning)
    .build();
  return conn;
};

export const friendConnection = () => {
  const conn = new signalR.HubConnectionBuilder()
    .withUrl(`${HUB_BASE_URL}/hubs/friend`, {
      skipNegotiation: true,
      transport: signalR.HttpTransportType.WebSockets,
      accessTokenFactory: () => auth.currentUser?.getIdToken() ?? Promise.reject(),
    })
    .withAutomaticReconnect([2000, 5000, 10000, 30000])
    .build();
  return conn;
};
```

> Lưu ý: Flutter dùng `?userId=<uid>&access_token=<firebase>` cho ChatHub. SignalR JS chỉ cần truyền `access_token` qua `accessTokenFactory`; nếu backend yêu cầu `userId` trong query string, dùng `withUrl(url + '?userId=' + auth.currentUser.uid, options)`.

### Bước 14 — AppShell với Anime.js page transition

```jsx
// src/components/layout/AppShell.jsx
import { useEffect, useRef } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { pageIn } from '../../lib/anime';
import TopBar from './TopBar';
import BottomNav from './BottomNav';
import './appShell.css';

export default function AppShell() {
  const ref = useRef(null);
  const loc = useLocation();
  useEffect(() => { ref.current && pageIn(ref.current); }, [loc.pathname]);
  return (
    <div className="app-shell">
      <TopBar />
      <main ref={ref} className="app-shell__main">
        <Outlet />
      </main>
      <BottomNav />
    </div>
  );
}
```

### Bước 15 — Newsfeed dùng `staggerCards` của Anime.js

```jsx
// src/pages/feed/Newsfeed.jsx
import { useEffect, useRef } from 'react';
import { staggerCards } from '../../lib/anime';
import PostCard from '../../components/feed/PostCard';
import StoryRail from '../../components/feed/StoryRail';

export default function Newsfeed() {
  const listRef = useRef(null);
  useEffect(() => {
    const cards = listRef.current?.querySelectorAll('.post-card');
    if (cards?.length) staggerCards(cards, { gap: 70, dur: 640, y: 28 });
  }, [posts.length]);

  return (
    <div className="newsfeed">
      <StoryRail />
      <div ref={listRef} className="newsfeed__list">
        {posts.map(p => <PostCard key={p.id} post={p} />)}
      </div>
    </div>
  );
}
```

### Bước 16 — MessageBubble high-end editorial

```jsx
// src/components/chat/MessageBubble.jsx
import { useState } from 'react';
import { fxBurst, ripple } from '../../lib/anime';
import './messageBubble.css';

export default function MessageBubble({ msg, onReact, onReply, onEdit, onDelete, onRetry }) {
  const onDouble = (e) => { fxBurst(e.currentTarget); onReact?.('❤️'); };
  const onPress = (e) => ripple(e.currentTarget);
  return (
    <article className={`bubble ${msg.isMine ? 'mine' : 'theirs'}`} onDoubleClick={onDouble} onMouseDown={onPress}>
      <div className="bubble__surface">{msg.content}</div>
      <footer className="bubble__meta">
        <time>{fmt(msg.createdAt)}</time>
        {msg.isMine && <StatusIcon status={msg.status} onRetry={onRetry} />}
      </footer>
    </article>
  );
}
```

### Bước 17 — Cuộc gọi WebRTC (gọi thoại + video)

> Phần này Flutter dùng `flutter_webrtc`. Web build dùng native `RTCPeerConnection`. Token Agora vẫn sinh client-side như cũ (`VITE_AGORA_APP_*`). Signaling vẫn đi qua SignalR (Initiate/Accept/Reject/End, Offer/Answer/IceCandidate).

```js
// src/lib/agora.js
import AgoraRTC from 'agora-rtc-sdk-ng';

export async function joinChannel(channel, uid, token) {
  const client = AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' });
  await client.join(import.meta.env.VITE_AGORA_APP_ID, channel, token, uid);
  return client;
}
```

### Bước 18 — FCM Web Push

```js
// src/lib/fcm.js
import { getMessaging, getToken, onMessage } from 'firebase/messaging';
import { messaging } from './firebase';

export async function initFcm() {
  const permission = await Notification.requestPermission();
  if (permission !== 'granted') return null;
  return getToken(messaging, { vapidKey: import.meta.env.VITE_FB_VAPID_KEY });
}

export function onFcmMessage(handler) {
  return onMessage(messaging, handler);
}
```

> TriChat hiện không có VAPID key công khai — cần thêm `VITE_FB_VAPID_KEY` (lấy từ Firebase Console → Project Settings → Cloud Messaging → Web Push certificates).

### Bước 19 — Voice recorder (thay cho `record`)

```js
// src/lib/mediaRecorder.js
export async function recordAudio() {
  const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
  const rec = new MediaRecorder(stream);
  const chunks = [];
  rec.ondataavailable = e => chunks.push(e.data);
  rec.start();
  return {
    stop: () => new Promise(res => {
      rec.onstop = () => res(new Blob(chunks, { type: 'audio/webm' }));
      rec.stop();
      stream.getTracks().forEach(t => t.stop());
    }),
  };
}
```

### Bước 20 — Maps (thay cho `flutter_map`)

```jsx
import { MapContainer, TileLayer, Marker } from 'react-leaflet';
<MapContainer center={[lat, lng]} zoom={15} className="map">
  <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
  <Marker position={[lat, lng]} />
</MapContainer>
```

### Bước 21 — Build & chạy

```bash
cd d:/Bai_tap/btl/pv/frontend
npm run dev          # http://localhost:5173
npm run build        # dist/
npm run preview      # serve dist/
```

### Bước 22 — Cập nhật Netlify config & Docker

```toml
# netlify.toml (root)
[build]
  base    = "frontend"
  command = "npm run build"
  publish = "frontend/dist"

[[redirects]]
  from = "/api/*"
  to   = "https://trichat.onrender.com/api/:splat"
  status = 200

[[redirects]]
  from = "/hubs/*"
  to   = "https://trichat.onrender.com/hubs/:splat"
  status = 200
```

> Nếu Netlify không proxy được WebSocket thì deploy trên **Vercel/Cloudflare Pages + Render Web Service** hoặc host thẳng trên Render static site (`render.yaml` đã có `netlify.toml` cũ — xem lại).

---

## 6. Mapping thiết kế (high-end editorial + Anime.js)

| Yếu tố | Trước (Flutter) | Sau (React + Anime.js) |
|---|---|---|
| Tông màu chính | Amber `#D97706` + Cream `#FAF8F5` | Amber + Bone cream + Glass tint + Aurora accent |
| Typography | Roboto system | InterVariable + Fraunces (serif cho logo/hero) |
| Card | Border + soft shadow | **Glass** (backdrop blur 20px) + hairline border + soft shadow |
| Page transition | FadeTransition/ScaleTransition | Anime.js `pageIn` (translateY + opacity + ease spring) |
| List reveal | ListView implicit | Anime.js `staggerCards` (stagger delay + translateY) |
| FAB menu | AnimatedContainer | `handArc` (cosine arc, scale + opacity) |
| Send message | None | `fxBurst` (radial scale 0→1.6→0) |
| Avatar click | None | `ripple` (scale 0→2.4 + opacity 0.6→0) |
| Reaction picker | BottomSheet grid | Anime.js stagger scale-up + haptic |
| Story viewer | PageView swipe | Anime.js cross-fade + scale |
| Like button | Scale animation | Anime.js elastic bounce |
| Loading | CircularProgressIndicator | Anime.js shimmer bar + skeleton blocks |
| Modal/Sheet | SlideTransition | Anime.js translateY 24→0 + spring overshoot |

### 6.1. Nguyên tắc thiết kế bắt buộc

1. **Editorial whitespace** — section gap ≥ 64px, card padding ≥ 20px.
2. **Squircle radii** ≥ 20px cho mọi card; pill (999) cho avatar/badge.
3. **Hairline border** 0.5–1px với màu `color-mix(in srgb, currentColor 8%, transparent)`.
4. **Soft shadow** mặc định — đổi sang `aurora` khi hover/focus.
5. **Dark mode** dùng cùng token nhưng override surface — không hardcode.
6. **Reduce motion** — `prefers-reduced-motion` phải được tôn trọng (skip Anime.js transforms, chỉ opacity).
7. **Accessibility** — focus ring 2px amber, ARIA roles, semantic HTML.

---

## 7. Service khác — ghi chú đặc biệt

- **OTP**: Backend có fallback trả OTP trong response khi email fail (`OtpResponse.Otp`). FE phải cache lại và forward `cached_otp` khi verify (giống Flutter `AuthService._lastFallbackOtp`).
- **PascalCase payload**: UpdateUser, SendMessage, CreateConversation, UpdateGroup, AddParticipants, ReactToMessage, SendFriendRequest, RespondFriendRequest, DisappearingSetting, ConversationSettings, UpdateGroupSettings — phải gửi đúng PascalCase theo DTO mà backend bind. Phần còn lại là snake_case. Service layer sẽ có hàm `payloadFor(endpoint, body)` để chuyển đổi tự động dựa vào danh sách whitelist.
- **PascalCase query param**: `beforeMessageId` cho `GET /api/chat/conversations/{id}/messages?beforeMessageId=...` (giữ nguyên).
- **Self-chat guard**: trước khi gọi create conversation, kiểm tra `targetUserId !== currentUid`.
- **Optimistic message**: `_pending_<timestamp>` cho text; `_pending_<timestamp>` kèm `localFilePath` cho image/audio.
- **Heartbeat**: setInterval 3 phút gọi `conn.invoke('Heartbeat')`.
- **Lifecycle**: `document.addEventListener('visibilitychange')` — khi `visible` gọi `SetOnline`, khi `hidden` gọi `SetOffline`.
- **FCM topic**: app subscribe `all_users` sau login.
- **Agora**: channel name = `[uid1, uid2].sort().join('_')`.
- **firebase_options.dart** đã có sẵn → copy sang `src/lib/firebase.js` dùng Firebase Web modular SDK.

---

## 8. Triển khai thực thi (gantt đề xuất)

| Ngày | Việc |
|---|---|
| 1 | Xóa frontend, scaffold Vite, cài deps, copy theme tokens, dark/light provider, AppShell với page transition |
| 2 | `lib/httpClient.js`, `lib/signalr.js`, `services/auth.service.js`, `pages/auth/*` (Login, SignUp, OTP, ForgotPassword) |
| 3 | `pages/Home`, `pages/Splash`, Firebase init, FCM web push subscribe |
| 4 | ChatService + ChatStore + ChatList + ConversationTile + ChatRoom + MessageBubble + Composer + typing |
| 5 | SignalR wiring (`useSignalR`), reaction/reply/edit/delete, media upload qua Cloudinary |
| 6 | Group create/info/join-request, pin, search, voice recorder, location share |
| 7 | Newsfeed + StoryRail + PostCard + CommentSheet + StoryViewer + CreatePost + CreateStory |
| 8 | FriendService + FriendStore + FriendList (grid/list) + AddFriend + FriendRequests + block |
| 9 | Profile (self/other) + update avatar + tab posts/media/friends + my-profile |
| 10 | CallKit replacement: Agora web SDK + CallRoom + IncomingCallSheet + signaling qua SignalR |
| 11 | Feedback modal, dark mode polish, i18n (vi/en), accessibility |
| 12 | PWA manifest, SEO meta, build, deploy Netlify/Render, smoke test |

---

## 9. Cập nhật tài liệu liên quan

| File | Cần sửa |
|---|---|
| `CLAUDE.md` | Đổi toàn bộ phần Frontend (Flutter, go_router, Provider/BLoC, signalr_netcore, FlutterFire) → React + Vite + Router DOM + Zustand + @microsoft/signalr + Firebase modular SDK |
| `README.md` | Đổi hướng dẫn chạy frontend sang `cd frontend && npm install && npm run dev` |
| `.gitignore` | Bỏ rule `frontend/build/`, `frontend/.dart_tool/`, `frontend/tools/…`, `frontend/analyze_output.txt`, thêm `frontend/node_modules/`, `frontend/dist/` |
| `netlify.toml` | Đổi `command`, `publish` sang React/Vite |
| `docker-compose.yml` | Cập nhật lại service frontend (nếu có) sang Node 20 |
| `.env.example` (root) | Thay biến Flutter bằng `VITE_API_BASE_URL`, `VITE_FB_*`, `VITE_AGORA_*` |

---

## 10. Rủi ro & giảm thiểu

| Rủi ro | Giải pháp |
|---|---|
| WebSocket không proxy qua Netlify | Dùng Render Web Service hoặc Cloudflare Pages + custom routing |
| Agora Web SDK cần HTTPS | Localhost OK; production bắt buộc HTTPS |
| FCM Web Push cần VAPID | Lấy từ Firebase Console và lưu `VITE_FB_VAPID_KEY` |
| MediaRecorder chỉ hỗ trợ webm/opus | Encode lại qua Cloudinary hoặc đổi container trên backend |
| `signalr_netcore` access_token được gắn vào URL query `?access_token=` ở server, nhưng Web SDK dùng header — đã được xử lý qua `accessTokenFactory` | Nếu backend từ chối, ép `transport: WebSockets` và kiểm tra middleware `FirebaseAuthMiddleware` chấp nhận `access_token` query |
| `flutter_webrtc` ↔ Web `RTCPeerConnection` không đồng nhất codec/hint | Khi 2 bên là web thì OK; nếu sau này mở lại mobile app cần đối chiếu lại |
| Token Firebase hết hạn 1h | `accessTokenFactory` sẽ tự lấy token mới mỗi invoke |
| Backend JSON `SnakeCaseLower` cho controller REST nhưng SignalR cho phép cả PascalCase | Đã giữ nguyên trong `services/chat.service.js` |

---

## 11. Acceptance criteria (Definition of Done)

1. ✅ `frontend/` chỉ còn React/Vite, không còn bất kỳ file `.dart`, `.yaml` của Flutter, không còn `pubspec.*`, không còn folder `android/ios/…`.
2. ✅ `npm run dev` mở `http://localhost:5173`, login → chat-list → chọn hội thoại → gửi text, image, audio, location đều hoạt động.
3. ✅ Realtime SignalR: gửi tin từ 2 tab/2 browser khác nhau → cả hai thấy tin trong < 1 giây.
4. ✅ Cuộc gọi voice + video giữa 2 browser hoạt động, có log "call" message.
5. ✅ Bảng tin + stories tạo/xem/like/comment hoạt động.
6. ✅ Friend request realtime qua FriendHub.
7. ✅ Dark mode + i18n (vi/en) + reduced-motion đều tôn trọng.
8. ✅ `npm run build` ra `dist/` < 1.5 MB (gzipped) và Lighthouse Performance ≥ 90.
9. ✅ Bundle tách: `firebase`, `signalr`, `maps`, `calendar` là các chunk riêng.
10. ✅ Anime.js dùng cho: page transition, stagger card reveal, hand-arc FAB, fx burst khi send, ripple trên avatar.
11. ✅ Không còn lỗi runtime, không còn warning React keys, không còn dependency Flutter nào trong lock files.

---

## 12. Phụ lục — Snippets tiện ích

### 12.1. `src/components/ui/Avatar.jsx`

```jsx
export default function Avatar({ src, name, size = 40, ring }) {
  const letter = (name || '?').trim()[0]?.toUpperCase();
  return (
    <span className={`avatar ${ring ? 'avatar--ring' : ''}`} style={{ width: size, height: size }}>
      {src
        ? <img src={src} alt={name} loading="lazy" />
        : <span className="avatar__letter">{letter}</span>}
    </span>
  );
}
```

### 12.2. `src/components/ui/Button.jsx`

```jsx
export default function Button({ variant = 'primary', children, ...rest }) {
  return <button className={`btn btn--${variant}`} {...rest}>{children}</button>;
}
```

### 12.3. CSS cho Button (trích)

```css
.btn {
  display: inline-flex; align-items: center; justify-content: center; gap: 8px;
  padding: 10px 18px; border-radius: 999px; border: 1px solid transparent;
  font-weight: 600; letter-spacing: 0.2px; transition: all .25s var(--ease-soft);
}
.btn--primary { background: linear-gradient(135deg, var(--amber), var(--amber-deep)); color: white; box-shadow: var(--shadow-aurora); }
.btn--ghost { background: transparent; color: var(--text); border-color: var(--hairline); }
.btn:hover { transform: translateY(-1px); }
```

### 12.4. Lệnh PowerShell xóa nhanh

```powershell
Remove-Item -Recurse -Force 'D:\Bai_tap\btl\pv\frontend'
```

---

## 13. Checklist sau khi hoàn tất

- [ ] Đã xóa `frontend/` cũ
- [ ] Đã tạo `frontend/` mới (React + Vite)
- [ ] Đã port xong tất cả tính năng
- [ ] Đã cập nhật `CLAUDE.md`, `README.md`, `.gitignore`, `netlify.toml`, `.env.example`
- [ ] Đã thêm `VITE_FB_VAPID_KEY` thật
- [ ] Đã build production thành công
- [ ] Đã deploy staging + smoke test với backend Render
- [ ] Đã bàn giao tài liệu cho team

---

## 14. Phương án thay thế — Next.js (nếu user thật sự muốn)

Nếu user muốn **Next.js thật sự** thay vì Vite:

```bash
npx create-next-app@latest frontend --ts --app --src-dir --tailwind --eslint
cd frontend
npm install animejs@4.0.2 firebase @microsoft/signalr zustand @tanstack/react-query
```

- Vẫn dùng Anime.js 4 cho animation (Client Component).
- Routing: Next.js App Router (`app/login/page.tsx`, `app/chat-list/page.tsx`, …) + `middleware.ts` cho auth guard thay vì React Router.
- Phải dùng **Server Actions** cẩn thận — mọi gọi backend phải qua route handler trung gian để tránh lộ Firebase token ra client.
- Vite không dùng chung với Next.js — bỏ `vite.config.js`, dùng `next.config.mjs`.
- Phần còn lại (services, components, theme, anime presets) giữ nguyên.

> **Khuyến nghị**: Vì dự án là **SPA-only** (mọi logic đều chạy client vì cần Firebase ID token, SignalR realtime, Agora media), **Vite + React + React Router** phù hợp và nhẹ hơn Next.js. Chỉ chuyển sang Next.js nếu sau này cần SSR/SEO cho landing page.

---

**Kết thúc tài liệu. Áp dụng tuần tự từ Bước 1 → Bước 22, port đầy đủ tính năng theo bảng §2.3, dùng design tokens §11 + Anime.js presets §B10 để có giao diện high-end editorial nhất quán với backend hiện tại.**