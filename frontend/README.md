# TriChat Frontend (React + Vite + Anime.js)

High-end editorial chat UI — bản port hoàn toàn từ Flutter sang React 18.3.1 + Vite 5.4.10 + React Router DOM 6.26.2 + Anime.js 4.0.2.

## Lệnh

```bash
npm install          # cài đặt deps
npm run dev          # chạy dev server (http://localhost:5173)
npm run build        # build production ra dist/
npm run preview      # serve dist/
```

## Stack

- **React 18.3.1** + **Vite 5.4.10** + `@vitejs/plugin-react`
- **React Router DOM 6.26.2** — auth guard routing
- **Anime.js 4.0.2** — card stagger, hand-arc FAB, fx burst, ripple, page transition
- **Zustand 4.5** — state management (thay cho Provider/BLoC)
- **@microsoft/signalr 8.0.7** — realtime
- **Firebase 10.13** — Auth + FCM
- **agora-rtc-sdk-ng 4.21** — voice/video call
- **react-leaflet 4.2** — maps (thay flutter_map)
- **i18next + react-i18next** — đa ngôn ngữ

## Cấu trúc

```
src/
├── main.jsx                  # entry
├── App.jsx                   # root với providers
├── router/                   # React Router + guards
├── theme/                    # tokens, ThemeProvider, global.css
├── i18n/                     # vi.json, en.json
├── lib/                      # httpClient, signalr, firebase, anime, ...
├── services/                 # auth, chat, friend, feed, profile, feedback
├── store/                    # zustand stores
├── hooks/                    # useAuth, useChat, useFriends, ...
├── components/
│   ├── ui/                   # Button, Input, Avatar, Card, Modal, ...
│   ├── layout/               # AppShell, TopBar, BottomNav
│   ├── chat/                 # MessageBubble, ChatComposer, ConversationTile
│   ├── feed/                 # PostCard, StoryRail, CommentSheet
│   ├── friends/              # FriendGridCard, RequestRow
│   └── call/                 # CallSurface, IncomingCallSheet
├── pages/
│   ├── auth/                 # Login, SignUp, Otp, ...
│   ├── chat/                 # ChatList, ChatRoom, NewConversation, GroupInfo
│   ├── feed/                 # Newsfeed, CreatePost, StoryViewer, ...
│   ├── friends/              # FriendList, AddFriend, Requests, Contacts
│   ├── profile/              # Profile, MyProfile
│   └── call/                 # CallRoom, IncomingCall
└── styles/                   # tokens.css, reset.css, animations.css
```

## Env

Copy `.env.example` thành `.env` và điền:

```
VITE_API_BASE_URL=https://trichat.onrender.com
VITE_AGORA_APP_ID=
VITE_AGORA_APP_CERTIFICATE=
VITE_FB_API_KEY=
VITE_FB_PROJECT_ID=zalo-lite-f2d28
VITE_FB_APP_ID=
VITE_FB_MESSAGING_SENDER_ID=704895954808
VITE_FB_VAPID_KEY=
```

## Thiết kế

- Amber `#D97706` + Bone cream `#FAF8F5` (light) / Noir `#0A0907` (dark)
- InterVariable sans-serif + Fraunces serif (cho hero/quote)
- Squircle radii ≥ 20px, glass blur, hairline borders
- Anime.js v4 presets: staggerCards, handArc, fxBurst, ripple, pageIn
- Tôn trọng `prefers-reduced-motion`
