import { useEffect, useMemo, useRef, useState } from 'react';
import { useChatStore } from '../../store/chatStore';
import {
  useFriendStore,
  SUGGESTION_INITIAL_SIZE,
  SUGGESTION_PAGE_SIZE,
  REQUESTS_PAGE_SIZE,
} from '../../store/friendStore';
import { useUiStore } from '../../store/uiStore';
import { useAuthStore } from '../../store/authStore';
import { Avatar, Badge } from '../ui';
import { formatLastSeen, formatRelativeShort } from '../../lib/format';
import { staggerCards, pageIn } from '../../lib/anime';
import './leftPanel.css';

export default function LeftPanel() {
  const leftTab = useUiStore((s) => s.leftTab);
  const setLeftTab = useUiStore((s) => s.setLeftTab);
  const openProfileInCenter = useUiStore((s) => s.openProfileInCenter);
  const rootRef = useRef(null);

  useEffect(() => {
    pageIn(rootRef.current?.querySelector('.left-panel__inner'));
  }, [leftTab]);

  return (
    <div className="left-panel" ref={rootRef}>
      {/* User strip — click để mở hồ sơ ở tab giữa */}
      <MyAvatarStrip onProfile={() => openProfileInCenter('me')} />

      {/* Sub-tabs — chỉ 2 lựa chọn: Tin nhắn & Bạn bè */}
      <div className="left-panel__tabs">
        <button
          className={`left-panel__tab ${leftTab === 'chats' ? 'is-active' : ''}`}
          onClick={() => setLeftTab('chats')}
        >
          Tin nhắn
        </button>
        <button
          className={`left-panel__tab ${leftTab === 'friends' ? 'is-active' : ''}`}
          onClick={() => setLeftTab('friends')}
        >
          Bạn bè
        </button>
      </div>

      <div className="left-panel__inner">
        {leftTab === 'chats' && <ChatsList />}
        {leftTab === 'friends' && <FriendsList />}
      </div>
    </div>
  );
}

function MyAvatarStrip({ onProfile }) {
  const profile = useAuthStore((s) => s.profile);
  const user = useAuthStore((s) => s.user);
  const fullName =
    profile?.fullName ||
    `${profile?.firstName || ''} ${profile?.lastName || ''}`.trim() ||
    'Bạn';
  return (
    <button className="left-panel__me" onClick={onProfile}>
      <Avatar src={profile?.avatar} name={fullName} size={40} />
      <div className="left-panel__me-text">
        <div className="left-panel__me-name">{fullName}</div>
      </div>
      <span className="left-panel__me-chev" aria-hidden>›</span>
    </button>
  );
}

/* ============================================================
 *  TAB 1 — TIN NHẮN — có thanh tìm kiếm lọc cuộc trò chuyện
 * ============================================================ */
function ChatsList() {
  const conversations = useChatStore((s) => s.conversations);
  const loading = useChatStore((s) => s.loadingConversations);
  const onlineStatuses = useChatStore((s) => s.onlineStatuses);
  const loadConversations = useChatStore((s) => s.loadConversations);
  const activeConvId = useUiStore((s) => s.activeConvId);
  const openConversation = useUiStore((s) => s.openConversation);
  const setActiveUserId = useUiStore((s) => s.setActiveUserId);
  const listRef = useRef(null);

  const [keyword, setKeyword] = useState('');

  useEffect(() => {
    loadConversations();
    const t = setInterval(loadConversations, 30_000);
    return () => clearInterval(t);
  }, [loadConversations]);

  useEffect(() => {
    if (listRef.current && conversations.length) {
      staggerCards(listRef.current.querySelectorAll('.conv-tile'), { gap: 40, dur: 480, y: 14 });
    }
  }, [conversations.length]);

  const filtered = useMemo(() => {
    if (!keyword.trim()) return conversations;
    const k = keyword.trim().toLowerCase();
    return conversations.filter((c) =>
      (c.displayName || '').toLowerCase().includes(k)
    );
  }, [conversations, keyword]);

  return (
    <>
      {/* Thanh tìm kiếm — chỉ lọc cuộc trò chuyện */}
      <div className="left-panel__search">
        <input
          className="input left-panel__search-input"
          placeholder="Tìm cuộc trò chuyện..."
          value={keyword}
          onChange={(e) => setKeyword(e.target.value)}
        />
        {keyword && (
          <button
            className="left-panel__search-clear"
            onClick={() => setKeyword('')}
            aria-label="Xóa"
          >×</button>
        )}
      </div>

      <div className="left-panel__heading">
        <h2 className="left-panel__title">Tin nhắn</h2>
        <span className="left-panel__count">{filtered.length}</span>
      </div>

      {loading && conversations.length === 0 ? (
        <SkeletonList count={6} />
      ) : filtered.length === 0 ? (
        <div className="empty-state empty-state--compact">
          <h3>{keyword ? 'Không tìm thấy cuộc trò chuyện' : 'Chưa có hội thoại nào'}</h3>
          <p>{keyword ? 'Thử từ khóa khác.' : 'Mời bạn bè để bắt đầu trò chuyện.'}</p>
        </div>
      ) : (
        <ul className="left-panel__items no-scrollbar" ref={listRef}>
          {filtered.map((c) => (
            <li key={c.id}>
              <ConversationTile
                conv={c}
                online={onlineStatuses[c.otherUserId]}
                active={c.id === activeConvId}
                onClick={() => openConversation(c.id)}
                onAvatar={() => {
                  // Right panel chỉ còn 2 tab (Thông tin / Hồ sơ) — không mở feed ở đây nữa
                  setActiveUserId(c.type === 'group' ? c.id : c.otherUserId);
                }}
              />
            </li>
          ))}
        </ul>
      )}
    </>
  );
}

function ConversationTile({ conv, online, active, onClick, onAvatar }) {
  const lastMsg = conv.lastMessage;
  const preview =
    lastMsg?.content ||
    (lastMsg?.type === 'image'
      ? 'Hình ảnh'
      : lastMsg?.type === 'audio'
      ? 'Tin nhắn thoại'
      : 'Chưa có tin nhắn');
  return (
    <div className={`conv-tile ${active ? 'is-active' : ''}`}>
      <Avatar
        src={conv.otherUserAvatar || conv.groupAvatarUrl}
        name={conv.displayName}
        size={48}
        online={conv.type === 'private' ? online : undefined}
        onClick={onAvatar}
      />
      <button className="conv-tile__body" onClick={onClick}>
        <div className="conv-tile__row1">
          <span className="conv-tile__name">{conv.displayName}</span>
          <span className="conv-tile__time">
            {lastMsg ? formatRelativeShort(lastMsg.createdAt) : ''}
          </span>
        </div>
        <div className="conv-tile__row2">
          <span className="conv-tile__preview">{preview}</span>
          {conv.unreadCount > 0 && (
            <span className="conv-tile__badge">{conv.unreadCount}</span>
          )}
        </div>
      </button>
    </div>
  );
}

/* ============================================================
 *  TAB 2 — BẠN BÈ — 3 hàng xổ xuống + thanh tìm kiếm tìm người
 * ============================================================ */
function FriendsList() {
  const friends           = useFriendStore((s) => s.friends);
  const friendsTotal      = useFriendStore((s) => s.friendsTotal);
  const friendsHasMore    = useFriendStore((s) => s.friendsHasMore);
  const friendsState      = useFriendStore((s) => s.friendsState);

  const pendingReceived     = useFriendStore((s) => s.pendingReceived);
  const pendingReceivedTotal = useFriendStore((s) => s.pendingReceivedTotal);
  const pendingReceivedHasMore = useFriendStore((s) => s.pendingReceivedHasMore);
  const pendingReceivedState = useFriendStore((s) => s.pendingReceivedState);

  const pendingSent         = useFriendStore((s) => s.pendingSent);
  const pendingSentTotal    = useFriendStore((s) => s.pendingSentTotal);
  const pendingSentHasMore  = useFriendStore((s) => s.pendingSentHasMore);
  const pendingSentState    = useFriendStore((s) => s.pendingSentState);

  const searchResults = useFriendStore((s) => s.searchResults);
  const searchState = useFriendStore((s) => s.searchState);

  const loadAll                  = useFriendStore((s) => s.loadAll);
  const loadPendingReceivedPage  = useFriendStore((s) => s.loadPendingReceivedPage);
  const loadPendingSentPage      = useFriendStore((s) => s.loadPendingSentPage);
  const loadFriendsPage          = useFriendStore((s) => s.loadFriendsPage);
  const search                   = useFriendStore((s) => s.search);
  const sendRequest              = useFriendStore((s) => s.sendRequest);
  const respond                  = useFriendStore((s) => s.respond);
  const cancelRequest            = useFriendStore((s) => s.cancelRequest);

  const setActiveUserId = useUiStore((s) => s.setActiveUserId);
  const startChat = useChatStore((s) => s.startChatWithUser);
  const openConversation = useUiStore((s) => s.openConversation);
  const setCenterMode = useUiStore((s) => s.setCenterMode);

  const [keyword, setKeyword] = useState('');
  const [openReceived, setOpenReceived] = useState(true);
  const [openSent, setOpenSent] = useState(false);
  const [openFriends, setOpenFriends] = useState(true);

  // Local "showCount" cho các list button-based (3 + 10 mỗi lần bấm)
  const [receivedShow, setReceivedShow] = useState(REQUESTS_PAGE_SIZE);
  const [sentShow, setSentShow]         = useState(REQUESTS_PAGE_SIZE);

  // Infinite scroll sentinel cho "Bạn bè"
  const friendsSentinelRef = useRef(null);
  const friendsLoadingRef  = useRef(false);

  useEffect(() => {
    loadAll();
  }, [loadAll]);

  // Reset showCount khi total đổi (realtime events có thể thay đổi total)
  useEffect(() => { setReceivedShow(REQUESTS_PAGE_SIZE); }, [pendingReceivedTotal]);
  useEffect(() => { setSentShow(REQUESTS_PAGE_SIZE); },     [pendingSentTotal]);

  // Debounce search
  useEffect(() => {
    const id = setTimeout(() => search(keyword), 300);
    return () => clearTimeout(id);
  }, [keyword, search]);

  // Infinite scroll cho Bạn bè — khi sentinel vào viewport, load page tiếp theo
  useEffect(() => {
    const node = friendsSentinelRef.current;
    if (!node) return;
    const observer = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting && friendsHasMore && !friendsLoadingRef.current &&
              friendsState !== 'loading') {
            friendsLoadingRef.current = true;
            loadFriendsPage({ reset: false }).finally(() => {
              friendsLoadingRef.current = false;
            });
          }
        }
      },
      { rootMargin: '200px 0px' },
    );
    observer.observe(node);
    return () => observer.disconnect();
  }, [friendsHasMore, friendsState, loadFriendsPage]);

  const showSearchResults = keyword.trim().length >= 2;
  const visibleReceived = pendingReceived.slice(0, receivedShow);
  const visibleSent     = pendingSent.slice(0, sentShow);

  function handleShowMoreReceived() {
    if (receivedShow >= pendingReceivedTotal) {
      loadPendingReceivedPage({ reset: true, limit: REQUESTS_PAGE_SIZE });
      return;
    }
    if (pendingReceivedHasMore || pendingReceived.length < pendingReceivedTotal) {
      loadPendingReceivedPage({ reset: false, limit: REQUESTS_PAGE_SIZE });
    }
    setReceivedShow((n) => n + REQUESTS_PAGE_SIZE);
  }

  function handleShowMoreSent() {
    if (sentShow >= pendingSentTotal) {
      loadPendingSentPage({ reset: true, limit: REQUESTS_PAGE_SIZE });
      return;
    }
    if (pendingSentHasMore || pendingSent.length < pendingSentTotal) {
      loadPendingSentPage({ reset: false, limit: REQUESTS_PAGE_SIZE });
    }
    setSentShow((n) => n + REQUESTS_PAGE_SIZE);
  }

  return (
    <>
      {/* Thanh tìm kiếm — tìm người để kết bạn */}
      <div className="left-panel__search">
        <input
          className="input left-panel__search-input"
          placeholder="Tìm người để kết bạn..."
          value={keyword}
          onChange={(e) => setKeyword(e.target.value)}
        />
        {keyword && (
          <button
            className="left-panel__search-clear"
            onClick={() => setKeyword('')}
            aria-label="Xóa"
          >×</button>
        )}
      </div>

      {/* Kết quả tìm kiếm */}
      {showSearchResults && (
        <SearchResults
          results={searchResults}
          state={searchState}
          keyword={keyword}
          friends={friends}
          pendingReceived={pendingReceived}
          pendingSent={pendingSent}
          onSend={sendRequest}
          onRespond={respond}
          onCancel={cancelRequest}
          onOpenProfile={(id) => setActiveUserId(id)}
        />
      )}

      {!showSearchResults && (
        <div className="left-panel__friends-groups">
          {/* Hàng 0 — Gợi ý kết bạn (chỉ khi chưa có bạn) */}
          {friendsTotal === 0 && <SuggestionList />}

          {/* Hàng 1 — Lời mời kết bạn (đã nhận) — 3 đầu + nút Xem thêm +10 */}
          <CollapsibleRow
            title="Lời mời kết bạn"
            count={pendingReceivedTotal}
            open={openReceived}
            onToggle={() => setOpenReceived((v) => !v)}
            empty={pendingReceivedTotal === 0}
            emptyText="Không có lời mời nào."
          >
            <ul className="left-panel__items">
              {visibleReceived.map((req) => {
                const name = req.senderName || req.senderId;
                return (
                  <li key={req.id}>
                    <div className="conv-tile">
                      <Avatar
                        src={req.senderAvatar}
                        name={name}
                        size={44}
                        onClick={() => setActiveUserId(req.senderId)}
                      />
                      <div className="conv-tile__body">
                        <div className="conv-tile__row1">
                          <span className="conv-tile__name">{name}</span>
                        </div>
                        <div className="conv-tile__row2">
                          <div className="request-actions">
                            <button
                              className="btn btn--primary btn--sm"
                              onClick={() => respond(req.id, true)}
                            >
                              Chấp nhận
                            </button>
                            <button
                              className="btn btn--ghost btn--sm"
                              onClick={() => respond(req.id, false)}
                            >
                              Từ chối
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </li>
                );
              })}
            </ul>
            {(pendingReceivedHasMore || visibleReceived.length < pendingReceivedTotal) && (
              <button
                type="button"
                className="friend-group__more"
                onClick={handleShowMoreReceived}
                disabled={pendingReceivedState === 'loading'}
              >
                {pendingReceivedState === 'loading' ? 'Đang tải…' : 'Xem thêm'}
              </button>
            )}
          </CollapsibleRow>

          {/* Hàng 2 — Lời mời đã gửi — 3 đầu + nút Xem thêm +10 */}
          <CollapsibleRow
            title="Lời mời đã gửi"
            count={pendingSentTotal}
            open={openSent}
            onToggle={() => setOpenSent((v) => !v)}
            empty={pendingSentTotal === 0}
            emptyText="Chưa gửi lời mời nào."
          >
            <ul className="left-panel__items">
              {visibleSent.map((req) => {
                const name = req.addresseeName || req.addresseeId;
                return (
                  <li key={req.id}>
                    <div className="conv-tile">
                      <Avatar
                        src={req.addresseeAvatar}
                        name={name}
                        size={44}
                        onClick={() => setActiveUserId(req.addresseeId)}
                      />
                      <div className="conv-tile__body">
                        <div className="conv-tile__row1">
                          <span className="conv-tile__name">{name}</span>
                        </div>
                        <div className="conv-tile__row2">
                          <div className="request-actions">
                            <button
                              className="btn btn--ghost btn--sm"
                              onClick={() => cancelRequest(req.id)}
                            >
                              Thu hồi
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </li>
                );
              })}
            </ul>
            {(pendingSentHasMore || visibleSent.length < pendingSentTotal) && (
              <button
                type="button"
                className="friend-group__more"
                onClick={handleShowMoreSent}
                disabled={pendingSentState === 'loading'}
              >
                {pendingSentState === 'loading' ? 'Đang tải…' : 'Xem thêm'}
              </button>
            )}
          </CollapsibleRow>

          {/* Hàng 3 — Danh sách bạn bè (infinite scroll 20/lần, sort: bạn nhắn gần đây) */}
          <CollapsibleRow
            title="Bạn bè"
            count={friendsTotal}
            open={openFriends}
            onToggle={() => setOpenFriends((v) => !v)}
            empty={friendsTotal === 0}
            emptyText="Chưa có bạn bè nào."
          >
            <ul className="left-panel__items">
              {friends.map((f) => {
                const name = f.fullName || `${f.firstName || ''} ${f.lastName || ''}`.trim();
                return (
                  <li key={f.friendId}>
                    <div className="conv-tile">
                      <Avatar
                        src={f.avatar}
                        name={name}
                        size={44}
                        onClick={() => setActiveUserId(f.friendId)}
                      />
                      <button
                        className="conv-tile__body"
                        onClick={async () => {
                          const conv = await startChat(f.friendId);
                          openConversation(conv.id);
                          setCenterMode('chat');
                        }}
                      >
                        <div className="conv-tile__row1">
                          <span className="conv-tile__name">{name}</span>
                        </div>
                        <div className="conv-tile__row2">
                          <span className="conv-tile__preview">Bấm để nhắn tin</span>
                        </div>
                      </button>
                    </div>
                  </li>
                );
              })}
            </ul>
            {friendsHasMore && (
              <div
                ref={friendsSentinelRef}
                className="friend-group__sentinel"
                aria-hidden="true"
              >
                {friendsState === 'loading' ? 'Đang tải…' : ''}
              </div>
            )}
            {!friendsHasMore && friendsTotal > 0 && (
              <p className="friend-group__end">— Đã hết danh sách bạn bè —</p>
            )}
          </CollapsibleRow>
        </div>
      )}
    </>
  );
}

/* ---------- Sub components ---------- */
function CollapsibleRow({ title, count, open, onToggle, empty, emptyText, children }) {
  return (
    <div className={`friend-group ${open ? 'is-open' : ''}`}>
      <button className="friend-group__head" onClick={onToggle}>
        <span className="friend-group__head-left">
          <span className="friend-group__chev" aria-hidden>{open ? '▾' : '▸'}</span>
          <span className="friend-group__title">{title}</span>
          {count > 0 && <Badge variant="primary">{count}</Badge>}
        </span>
      </button>
      {open && (
        <div className="friend-group__body">
          {empty ? (
            <p className="friend-group__empty">{emptyText}</p>
          ) : (
            children
          )}
        </div>
      )}
    </div>
  );
}

/* ---------- Gợi ý kết bạn (3 đầu, "Xem thêm" +10) ---------- */
function SuggestionList() {
  const suggestions       = useFriendStore((s) => s.suggestions);
  const suggestionsState  = useFriendStore((s) => s.suggestionsState);
  const suggestionsTotal  = useFriendStore((s) => s.suggestionsTotal);
  const suggestionsHasMore = useFriendStore((s) => s.suggestionsHasMore);
  const loadSuggestions = useFriendStore((s) => s.loadSuggestions);
  const sendRequest = useFriendStore((s) => s.sendRequest);
  const setActiveUserId = useUiStore((s) => s.setActiveUserId);

  // Hiển thị tuỳ theo local showCount — 3 lần đầu, +10 mỗi lần bấm.
  const [showCount, setShowCount] = useState(SUGGESTION_INITIAL_SIZE);
  const listRef = useRef(null);

  // Reset về 3 khi store reload
  useEffect(() => { setShowCount(SUGGESTION_INITIAL_SIZE); }, [suggestionsTotal]);

  // Lần đầu vào — fetch 3 item
  useEffect(() => {
    if (suggestionsState === 'idle') {
      loadSuggestions({ reset: true, limit: SUGGESTION_INITIAL_SIZE });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function handleShowMore() {
    loadSuggestions({ reset: false, limit: SUGGESTION_PAGE_SIZE });
    setShowCount((n) => n + SUGGESTION_PAGE_SIZE);
  }

  const visible = suggestions.slice(0, showCount);

  return (
    <div className="friend-suggest">
      <div className="friend-suggest__head">
        <h3 className="friend-suggest__title">Gợi ý kết bạn</h3>
        {suggestionsTotal > 0 && (
          <span className="friend-suggest__count">
            {visible.length}/{suggestionsTotal}
          </span>
        )}
      </div>

      {suggestionsState === 'loading' && suggestions.length === 0 ? (
        <p className="friend-group__empty">Đang tải gợi ý...</p>
      ) : suggestionsTotal === 0 ? (
        <p className="friend-group__empty">Chưa có gợi ý nào.</p>
      ) : (
        <>
          <ul className="left-panel__items" ref={listRef}>
            {visible.map((u) => {
              const name =
                u.fullName ||
                `${u.firstName || ''} ${u.lastName || ''}`.trim() ||
                u.email ||
                u.id;
              const mutual = typeof u.mutual_count === 'number' ? u.mutual_count : null;
              return (
                <li key={u.id}>
                  <div className="conv-tile">
                    <Avatar
                      src={u.avatar}
                      name={name}
                      size={48}
                      onClick={() => setActiveUserId(u.id)}
                    />
                    <div className="conv-tile__body">
                      <div className="conv-tile__row1">
                        <span className="conv-tile__name">{name}</span>
                      </div>
                      <div className="conv-tile__row2">
                        {mutual !== null && mutual > 0 ? (
                          <span className="conv-tile__preview conv-tile__preview--mutual">
                            {mutual} bạn chung
                          </span>
                        ) : (
                          <span className="conv-tile__preview">Gợi ý cho bạn</span>
                        )}
                        <div className="request-actions">
                          <button
                            className="btn btn--primary btn--sm"
                            onClick={() => sendRequest(u.id)}
                          >
                            Kết bạn
                          </button>
                          <button
                            className="btn btn--ghost btn--sm"
                            onClick={() => setActiveUserId(u.id)}
                          >
                            Xem
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                </li>
              );
            })}
          </ul>

          {(suggestionsHasMore || visible.length < suggestions.length) &&
            visible.length < suggestionsTotal && (
              <button
                type="button"
                className="friend-group__more"
                onClick={handleShowMore}
                disabled={suggestionsState === 'loading'}
              >
                {suggestionsState === 'loading' ? 'Đang tải…' : 'Xem thêm'}
              </button>
            )}
        </>
      )}
    </div>
  );
}

function SearchResults({ results, state, keyword, friends, pendingReceived, pendingSent, onSend, onRespond, onCancel, onOpenProfile }) {
  if (state === 'loading') {
    return <p className="left-panel__search-status">Đang tìm "{keyword}"...</p>;
  }
  if (!results || results.length === 0) {
    return (
      <div className="empty-state empty-state--compact">
        <h3>Không tìm thấy</h3>
        <p>Thử từ khóa khác.</p>
      </div>
    );
  }
  return (
    <div className="left-panel__search-results">
      <h3 className="left-panel__search-heading">Kết quả cho "{keyword}"</h3>
      <ul className="left-panel__items">
        {results.map((u) => {
          const name = u.fullName || `${u.firstName || ''} ${u.lastName || ''}`.trim() || u.email || u.id;
          const isFriend = friends.some((f) => f.friendId === u.id);
          const sentReq = pendingSent.find((r) => r.addresseeId === u.id);
          const receivedReq = pendingReceived.find((r) => r.senderId === u.id);
          return (
            <li key={u.id}>
              <div className="conv-tile">
                <Avatar
                  src={u.avatar}
                  name={name}
                  size={44}
                  onClick={() => onOpenProfile(u.id)}
                />
                <div className="conv-tile__body">
                  <div className="conv-tile__row1">
                    <span className="conv-tile__name">{name}</span>
                  </div>
                  <div className="conv-tile__row2">
                    {isFriend ? (
                      <span className="conv-tile__preview">Đã là bạn bè</span>
                    ) : sentReq ? (
                      <div className="request-actions">
                        <button
                          className="btn btn--ghost btn--sm"
                          onClick={() => onCancel(sentReq.id)}
                        >
                          Thu hồi lời mời
                        </button>
                      </div>
                    ) : receivedReq ? (
                      <div className="request-actions">
                        <button
                          className="btn btn--primary btn--sm"
                          onClick={() => onRespond(receivedReq.id, true)}
                        >
                          Chấp nhận
                        </button>
                      </div>
                    ) : (
                      <div className="request-actions">
                        <button
                          className="btn btn--primary btn--sm"
                          onClick={() => onSend(u.id)}
                        >
                          Kết bạn
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </li>
          );
        })}
      </ul>
    </div>
  );
}

function SkeletonList({ count = 6 }) {
  return (
    <ul className="left-panel__items">
      {Array.from({ length: count }).map((_, i) => (
        <li key={i} className="conv-tile">
          <span
            className="skeleton"
            style={{ width: 48, height: 48, borderRadius: '50%' }}
          />
          <div style={{ flex: 1 }}>
            <span
              className="skeleton"
              style={{ width: '40%', height: 14, marginBottom: 8, display: 'block' }}
            />
            <span
              className="skeleton"
              style={{ width: '70%', height: 12, display: 'block' }}
            />
          </div>
        </li>
      ))}
    </ul>
  );
}
