# Frontend Tests

Cấu trúc thư mục test cho TriChat frontend (React + Vite + Vitest).

```
@test/
├── setup.js              # Global test setup: mocks Firebase, SignalR, Agora, matchMedia, IntersectionObserver
├── unit/                  # Unit tests — mirror cấu trúc src/, test 1 module độc lập (mock hết dependency)
│   ├── lib/               # Test cho src/lib/* (httpClient, format, ...)
│   ├── services/          # Test cho src/services/* (auth, chat, feed, friend service)
│   └── store/             # Test cho src/store/* (Zustand stores: authStore, uiStore, friendStore, ...)
├── integration/           # Integration tests — nhiều module phối hợp (component + store + service mock ở tầng http)
├── e2e/                   # End-to-end tests — chạy trên trình duyệt thật (Playwright), luồng người dùng đầy đủ
└── fixtures/              # Dữ liệu mẫu / mock response dùng chung giữa các test
```

## Quy ước

- Tên file test: `<tên file gốc>.test.js`, đặt trong thư mục con tương ứng với vị trí file gốc trong `src/`.
  Ví dụ: `src/services/auth.service.js` → `@test/unit/services/auth.service.test.js`.
- Mỗi test file mock toàn bộ dependency bên ngoài (`httpClient`, `firebase`, `signalr`, ...) qua `vi.mock()`, không gọi network thật.
- Dùng alias `@/` (trỏ tới `src/`) khi import module cần test, giống code thật.
- `beforeEach(() => vi.clearAllMocks())` để tránh rò state giữa các test.

## Lệnh chạy test

```bash
npm run test           # watch mode
npm run test:run       # chạy 1 lần (CI)
npm run test:ui        # mở Vitest UI
npm run test:coverage  # chạy kèm coverage report (text + html trong coverage/)
```

## Thêm test mới

1. Xác định file nguồn cần test đang nằm ở đâu trong `src/`.
2. Tạo file `.test.js` cùng tên trong `@test/unit/<đường dẫn tương ứng>/`.
3. Nếu test cần dựng nhiều module cùng lúc (ví dụ store gọi service thật thay vì mock), đặt vào `integration/` thay vì `unit/`.
4. Dữ liệu mock dùng lại nhiều lần thì tách ra `fixtures/` để tránh lặp code giữa các test file.
