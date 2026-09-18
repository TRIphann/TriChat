# TriChat Test Suite

Thư mục này chứa toàn bộ test cho dự án TriChat, bao gồm cả frontend (Flutter) và backend (ASP.NET Core 8).

## Cấu trúc

```
test/
├── frontend/           # Frontend tests (Vitest)
│   ├── unit/          # Unit tests
│   │   ├── lib/       # Library utilities
│   │   ├── services/  # API services
│   │   └── store/     # Zustand stores
│   ├── integration/   # Integration tests (chưa có)
│   ├── e2e/           # End-to-end tests (chưa có)
│   └── fixtures/      # Test fixtures & mock data
│
├── backend/           # Backend tests (xUnit)
│   ├── unit/          # Unit tests
│   └── integration/   # Integration tests (chưa có)
│
└── README.md          # File này
```

## Frontend Tests

**Framework:** Vitest + @testing-library/react  
**Language:** JavaScript (ES modules)  
**Test count:** 214 tests

### Chạy tests

```bash
# Từ thư mục gốc dự án
cd test/frontend
npm test              # Run với watch mode
npm run test:run      # Run một lần
npm run test:coverage # Run với coverage report

# Hoặc từ thư mục frontend/ (proxy script)
cd frontend
npm run test:run
```

### Test coverage hiện tại

- **Store** (authStore, friendStore, uiStore): 96.3% statements
- **Services** (auth, chat, feed, friend): 89% statements  
- **Lib** (httpClient, format utils): 80.9% statements

### Test suites

- `unit/lib/httpClient.test.js` (22 tests) — HTTP client core, auth header, 401 refresh logic
- `unit/lib/format.test.js` (29 tests) — Format thời gian, kích thước file, debounce, đọc file
- `unit/services/auth.service.test.js` (30 tests) — Firebase Auth login/register, error mapping
- `unit/services/chat.service.test.js` (21 tests) — Conversations, messages, upload media
- `unit/services/feed.service.test.js` (19 tests) — Feed/story CRUD, like/comment
- `unit/services/friend.service.test.js` (26 tests) — Friend requests, suggestions, blocking
- `unit/store/authStore.test.js` (8 tests) — Auth lifecycle, load profile, sign out
- `unit/store/friendStore.test.js` (32 tests) — Friend state management, real-time updates
- `unit/store/uiStore.test.js` (29 tests) — Layout, toast, locale, localStorage persistence

## Backend Tests

**Framework:** xUnit  
**Language:** C# (.NET 8)  
**Test count:** 44 tests

### Chạy tests

```bash
cd test/backend
dotnet test           # Run tất cả tests
dotnet test --logger "console;verbosity=detailed"  # Chi tiết hơn
```

### Test suites

- `unit/FriendshipServiceTests.cs` (44 tests) — FriendshipService business logic với in-memory data store

## Quy ước

### Frontend

- **Naming:** `<module>.test.js` (e.g. `authStore.test.js`)
- **Structure:** `describe` → `describe` (nested context) → `it`
- **Mocking:** `vi.mock()` cho external dependencies, `vi.fn()` cho callbacks
- **Async:** Dùng `await` với `waitFor()` hoặc `findBy*` queries
- **Cleanup:** Tự động với `@testing-library` và `afterEach(() => { vi.clearAllMocks() })`

### Backend

- **Naming:** `<Service>Tests.cs` (e.g. `FriendshipServiceTests.cs`)
- **Structure:** Class → Method (Fact/Theory)
- **Mocking:** In-memory implementations hoặc mocking framework (chưa dùng)
- **Async:** Suffix `Async` cho test methods, return `Task`
- **Assertions:** xUnit built-in (`Assert.Equal`, `Assert.True`, etc.)

## Thêm tests mới

### Frontend

1. Tạo file trong `test/frontend/unit/` hoặc `integration/`
2. Import module cần test và các utilities: `describe`, `it`, `expect`, `vi`
3. Mock external dependencies (Firebase, API calls) bằng `vi.mock()`
4. Viết test cases
5. Chạy `npm test` để verify

### Backend

1. Tạo file `*.cs` trong `test/backend/unit/` hoặc `integration/`
2. Kế thừa từ base class nếu cần (hoặc standalone)
3. Inject dependencies qua constructor (hoặc tạo in-memory implementations)
4. Viết test methods với `[Fact]` hoặc `[Theory]` attribute
5. Chạy `dotnet test` để verify

## CI/CD

Chưa có GitHub Actions / CI pipeline. Khi setup:

```yaml
# .github/workflows/test.yml (draft)
- name: Frontend tests
  run: |
    cd test/frontend
    npm ci
    npm run test:run

- name: Backend tests
  run: |
    cd test/backend
    dotnet test --no-build --verbosity normal
```

## Roadmap

- [ ] Integration tests cho frontend (API mocking với MSW)
- [ ] E2E tests với Playwright hoặc Cypress
- [ ] Backend integration tests với TestContainers (Firestore emulator)
- [ ] Code coverage enforcement (min 80%)
- [ ] CI pipeline tự động chạy tests trên mỗi PR

---

**Tổng số tests:** 258 (214 frontend + 44 backend)  
**Last updated:** 2026-09-18
