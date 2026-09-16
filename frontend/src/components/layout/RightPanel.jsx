import { useEffect, useRef, useState } from 'react';
import { useChatStore } from '../../store/chatStore';
import { useUiStore } from '../../store/uiStore';
import { useAuthStore } from '../../store/authStore';
import { useProfileStore } from '../../store/profileStore';
import { useFriendStore } from '../../store/friendStore';
import { Avatar, Button, Modal } from '../ui';
import NewsfeedView from './NewsfeedView';
import { formatLastSeen } from '../../lib/format';
import { chatService } from '../../services/chat.service';
import { friendService } from '../../services/friend.service';
import './rightPanel.css';

export default function RightPanel() {
  const rightTab = useUiStore((s) => s.rightTab);
  const setRightTab = useUiStore((s) => s.setRightTab);
  const activeConvId = useUiStore((s) => s.activeConvId);
  const activeUserId = useUiStore((s) => s.activeUserId);
  const rightFeedId = useUiStore((s) => s.rightFeedId);
  const conversations = useChatStore((s) => s.conversations);
  const activeConv = useChatStore((s) => s.activeConversation);
  const me = useAuthStore((s) => s.user);
  const myProfile = useAuthStore((s) => s.profile);

  // Auto-resolve right panel content nếu user chưa chọn cụ thể
  const conv =
    conversations.find((c) => c.id === activeConvId) || activeConv;

  let resolvedTab = rightTab;
  let resolvedUserId = activeUserId;
  let resolvedFeedId = rightFeedId;

  if (rightTab === 'info') {
    if (!conv && activeUserId !== 'me' && !activeUserId) {
      // No context — show my profile by default
      resolvedTab = 'profile';
      resolvedUserId = 'me';
    }
  }

  if (rightTab === 'profile' && !resolvedUserId) {
    if (conv?.type === 'private') resolvedUserId = conv.otherUserId;
    else if (me) resolvedUserId = 'me';
  }

  if (rightTab === 'feed' && !resolvedFeedId) {
    if (conv?.type === 'group') resolvedFeedId = conv.id;
    else if (resolvedUserId) resolvedFeedId = resolvedUserId;
  }

  return (
    <div className="right-panel">
      <div className="right-panel__tabs">
        <button
          className={`right-panel__tab ${rightTab === 'info' ? 'is-active' : ''}`}
          onClick={() => setRightTab('info')}
          disabled={!conv}
        >
          Thông tin
        </button>
        <button
          className={`right-panel__tab ${rightTab === 'profile' ? 'is-active' : ''}`}
          onClick={() => {
            setRightTab('profile');
            // default to conv other user
            if (!activeUserId && conv?.type === 'private') {
              useUiStore.setState({ activeUserId: conv.otherUserId });
            } else if (!activeUserId) {
              useUiStore.setState({ activeUserId: 'me' });
            }
          }}
        >
          Hồ sơ
        </button>
        <button
          className={`right-panel__tab ${rightTab === 'feed' ? 'is-active' : ''}`}
          onClick={() => {
            setRightTab('feed');
            if (!rightFeedId && conv?.type === 'group') {
              useUiStore.setState({ rightFeedId: conv.id });
            } else if (!rightFeedId && activeUserId) {
              useUiStore.setState({ rightFeedId: activeUserId });
            }
          }}
        >
          Bảng tin
        </button>
      </div>

      <div className="right-panel__body">
        {rightTab === 'info' && conv && <InfoSection conv={conv} />}
        {rightTab === 'info' && !conv && (
          <div className="right-panel__empty">
            <div className="right-panel__empty-icon">ℹ️</div>
            <p>Chọn một cuộc trò chuyện để xem thông tin.</p>
          </div>
        )}

        {rightTab === 'profile' && (
          <ProfileSection
            userId={resolvedUserId}
            onChangeUser={(id) =>
              useUiStore.setState({ activeUserId: id, rightTab: 'profile' })
            }
          />
        )}

        {rightTab === 'feed' && (
          <FeedSection
            feedId={resolvedFeedId}
            isGroup={conv?.type === 'group'}
          />
        )}
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/*  INFO SECTION — chi tiết cuộc trò chuyện (Zalo-style)               */
/* ------------------------------------------------------------------ */

function InfoSection({ conv }) {
  const [muted, setMuted] = useState(false);
  const [readReceipts, setReadReceipts] = useState(true);
  const [nickname, setNickname] = useState('');
  const [editingNick, setEditingNick] = useState(false);
  const [showLeaveGroup, setShowLeaveGroup] = useState(false);
  const [showReport, setShowReport] = useState(false);
  const [showAddMember, setShowAddMember] = useState(false);
  const [showMedia, setShowMedia] = useState(false);
  const [mediaTab, setMediaTab] = useState('media');
  const isGroup = conv.type === 'group';

  async function saveNick() {
    if (!conv.otherUserId) return;
    try {
      await chatService.setNickname(conv.id, conv.otherUserId, nickname.trim());
      setEditingNick(false);
      // refresh conv in store
      await chatService.getConversation(conv.id).then((c) =>
        useChatStore.setState({ activeConversation: c }),
      );
    } catch (e) {
      alert('Không lưu được biệt danh: ' + e.message);
    }
  }

  async function toggleMute() {
    const next = !muted;
    setMuted(next);
    try {
      await chatService.updateSettings(conv.id, { MuteNotifications: next });
    } catch {}
  }

  async function toggleReadReceipts() {
    const next = !readReceipts;
    setReadReceipts(next);
    try {
      await chatService.updateSettings(conv.id, { ReadReceipts: next });
    } catch {}
  }

  async function leaveGroup() {
    setShowLeaveGroup(false);
    try {
      await chatService.deleteConversation(conv.id);
      useChatStore.setState((s) => ({
        conversations: s.conversations.filter((c) => c.id !== conv.id),
        activeConversation: null,
        messages: [],
      }));
      useUiStore.getState().closeConversation();
    } catch (e) {
      alert('Không rời được nhóm: ' + e.message);
    }
  }

  const displayName = isGroup ? conv.groupName : (conv.nickname || conv.displayName);
  const subtitle = isGroup
    ? `${conv.participants?.length || 0} thành viên`
    : (conv.otherUserOnline
        ? 'Đang hoạt động'
        : (conv.otherUserLastSeen ? `Hoạt động ${formatLastSeen(conv.otherUserLastSeen)}` : 'Ngoại tuyến'));

  return (
    <div className="info-section">
      {/* Header card */}
      <div className="info-section__head">
        <Avatar
          src={isGroup ? conv.groupAvatarUrl : conv.otherUserAvatar}
          name={displayName}
          size={88}
          ring
        />
        <h2 className="info-section__name">{displayName}</h2>
        <p className="info-section__sub">{subtitle}</p>

        {isGroup ? (
          <div className="info-section__quick-actions">
            <button className="qa-btn" onClick={() => setMuted((m) => !m)}>
              <span className="qa-btn__icon">{muted ? '🔕' : '🔔'}</span>
              <span>{muted ? 'Bật lại' : 'Tắt tiếng'}</span>
            </button>
            <button className="qa-btn">
              <span className="qa-btn__icon">🔍</span>
              <span>Tìm kiếm</span>
            </button>
          </div>
        ) : (
          <div className="info-section__quick-actions">
            <button className="qa-btn" onClick={toggleMute}>
              <span className="qa-btn__icon">{muted ? '🔕' : '🔔'}</span>
              <span>{muted ? 'Bật lại' : 'Tắt tiếng'}</span>
            </button>
            <button className="qa-btn">
              <span className="qa-btn__icon">🔍</span>
              <span>Tìm kiếm</span>
            </button>
            <button className="qa-btn">
              <span className="qa-btn__icon">📞</span>
              <span>Cuộc gọi</span>
            </button>
          </div>
        )}
      </div>

      {!isGroup && (
        <Collapsible title="Thông tin về đoạn chat" defaultOpen>
          <InfoRow label="Biệt danh">
            {editingNick ? (
              <div className="info-inline-edit">
                <input
                  className="input"
                  value={nickname}
                  onChange={(e) => setNickname(e.target.value)}
                  placeholder="Đặt biệt danh..."
                  autoFocus
                />
                <div className="info-inline-edit__actions">
                  <Button variant="primary" size="sm" onClick={saveNick}>
                    Lưu
                  </Button>
                  <Button variant="ghost" size="sm" onClick={() => setEditingNick(false)}>
                    Hủy
                  </Button>
                </div>
              </div>
            ) : (
              <div className="info-edit-row">
                <span>{conv.nickname || '—'}</span>
                <button onClick={() => {
                  setNickname(conv.nickname || '');
                  setEditingNick(true);
                }}>Sửa</button>
              </div>
            )}
          </InfoRow>
          <InfoRow label="Tên gốc">
            {conv.otherUserFullName || conv.displayName || '—'}
          </InfoRow>
        </Collapsible>
      )}

      {!isGroup && (
        <Collapsible title="Tùy chỉnh đoạn chat" defaultOpen>
          <InfoRow label="Chủ đề">
            <span className="info-muted">Mặc định</span>
          </InfoRow>
          <InfoRow label="Hình nền">
            <span className="info-muted">Mặc định</span>
          </InfoRow>
          <InfoRow label="Biệt danh của tôi">
            <span className="info-muted">—</span>
          </InfoRow>
        </Collapsible>
      )}

      <Collapsible title={`Thành viên${isGroup ? ` (${conv.participants?.length || 0})` : ''}`} defaultOpen>
        {!isGroup ? (
          <InfoRow label={conv.displayName}>
            <Avatar
              src={conv.otherUserAvatar}
              name={conv.displayName}
              size={36}
            />
          </InfoRow>
        ) : (
          <div className="info-members">
            {(conv.participants || []).map((p) => (
              <button
                key={p.userId || p.id}
                className="info-member-row"
                onClick={() =>
                  useUiStore.getState().setActiveUserId(p.userId)
                }
              >
                <Avatar src={p.avatar} name={p.fullName || p.userId} size={40} />
                <div className="info-member-row__text">
                  <div>{p.fullName || p.userId}</div>
                  {p.role === 'admin' && (
                    <span className="info-badge">Quản trị viên</span>
                  )}
                </div>
              </button>
            ))}
            <button
              className="info-add-member"
              onClick={() => setShowAddMember(true)}
            >
              + Thêm thành viên
            </button>
          </div>
        )}
      </Collapsible>

      <Collapsible
        title="File phương tiện, file và liên kết"
        rightAction={
          <button
            className="info-toggle"
            onClick={() => setShowMedia((v) => !v)}
          >
            {showMedia ? '−' : '+'}
          </button>
        }
      >
        {showMedia && (
          <div className="info-media">
            <div className="info-media__tabs">
              {['media', 'files', 'links'].map((t) => (
                <button
                  key={t}
                  className={`info-media__tab ${mediaTab === t ? 'is-active' : ''}`}
                  onClick={() => setMediaTab(t)}
                >
                  {t === 'media' ? 'File phương tiện' : t === 'files' ? 'File' : 'Liên kết'}
                </button>
              ))}
            </div>
            <div className="info-media__grid">
              {/* Stub grid — sẽ load thật từ API */}
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="info-media__cell">
                  <span>📷</span>
                </div>
              ))}
            </div>
            <p className="info-media__hint">
              Tính năng đang phát triển — sẽ hiển thị ảnh/file/link đã chia sẻ.
            </p>
          </div>
        )}
      </Collapsible>

      <Collapsible title="Quyền riêng tư và hỗ trợ" defaultOpen>
        <InfoRow label="Thông báo về đoạn chat">
          <Switch checked={!muted} onChange={toggleMute} />
        </InfoRow>
        <InfoRow label="Thông báo đã đọc">
          <Switch checked={readReceipts} onChange={toggleReadReceipts} />
        </InfoRow>
        <InfoRow label="Báo cáo">
          <button className="info-link" onClick={() => setShowReport(true)}>
            Báo cáo
          </button>
        </InfoRow>
        {isGroup && (
          <InfoRow label="Rời nhóm">
            <button
              className="info-link info-link--danger"
              onClick={() => setShowLeaveGroup(true)}
            >
              Rời nhóm
            </button>
          </InfoRow>
        )}
      </Collapsible>

      <Modal
        open={showLeaveGroup}
        onClose={() => setShowLeaveGroup(false)}
        title="Rời nhóm"
      >
        <p>Bạn có chắc muốn rời nhóm <strong>{conv.groupName}</strong>?</p>
        <div style={{ display: 'flex', gap: 12, marginTop: 16, justifyContent: 'flex-end' }}>
          <Button variant="ghost" onClick={() => setShowLeaveGroup(false)}>
            Hủy
          </Button>
          <Button variant="danger" onClick={leaveGroup}>
            Rời nhóm
          </Button>
        </div>
      </Modal>

      <Modal open={showReport} onClose={() => setShowReport(false)} title="Báo cáo">
        <p style={{ color: 'var(--text-2)' }}>
          Tính năng báo cáo sẽ được gửi tới quản trị viên để xem xét.
        </p>
        <div style={{ display: 'flex', gap: 12, marginTop: 16, justifyContent: 'flex-end' }}>
          <Button variant="ghost" onClick={() => setShowReport(false)}>
            Đóng
          </Button>
          <Button variant="primary" onClick={() => {
            alert('Đã gửi báo cáo');
            setShowReport(false);
          }}>
            Gửi báo cáo
          </Button>
        </div>
      </Modal>

      <AddMemberModal
        open={showAddMember}
        onClose={() => setShowAddMember(false)}
        conversationId={conv.id}
      />
    </div>
  );
}

function AddMemberModal({ open, onClose, conversationId }) {
  const friends = useFriendStore((s) => s.friends);
  const [selected, setSelected] = useState([]);

  function toggle(id) {
    setSelected((s) => (s.includes(id) ? s.filter((x) => x !== id) : [...s, id]));
  }

  async function submit() {
    if (!selected.length) return;
    try {
      await chatService.addParticipants({
        ConversationId: conversationId,
        ParticipantIds: selected,
      });
      onClose();
      setSelected([]);
    } catch (e) {
      alert('Không thêm được: ' + e.message);
    }
  }

  return (
    <Modal open={open} onClose={onClose} title="Thêm thành viên">
      <div className="add-member">
        {friends.map((f) => {
          const name = f.fullName || `${f.firstName} ${f.lastName}`;
          const isSel = selected.includes(f.friendId);
          return (
            <button
              key={f.friendId}
              className={`add-member__row ${isSel ? 'is-selected' : ''}`}
              onClick={() => toggle(f.friendId)}
            >
              <Avatar src={f.avatar} name={name} size={36} />
              <span>{name}</span>
              <span className="add-member__check">{isSel ? '✓' : ''}</span>
            </button>
          );
        })}
        {friends.length === 0 && (
          <p style={{ textAlign: 'center', color: 'var(--text-3)' }}>
            Bạn chưa có bạn bè nào để thêm.
          </p>
        )}
      </div>
      <div style={{ display: 'flex', gap: 12, marginTop: 16, justifyContent: 'flex-end' }}>
        <Button variant="ghost" onClick={onClose}>Hủy</Button>
        <Button variant="primary" onClick={submit} disabled={!selected.length}>
          Thêm ({selected.length})
        </Button>
      </div>
    </Modal>
  );
}

/* ------------------------------------------------------------------ */
/*  PROFILE SECTION                                                   */
/* ------------------------------------------------------------------ */

function ProfileSection({ userId, onChangeUser }) {
  const me = useAuthStore((s) => s.user);
  const myProfile = useAuthStore((s) => s.profile);
  const loadMyProfile = useProfileStore((s) => s.loadMyProfile);
  const loadUser = useProfileStore((s) => s.loadUser);
  const updateMe = useProfileStore((s) => s.updateMe);
  const updateAvatar = useProfileStore((s) => s.updateAvatar);
  const fetchedProfile = useProfileStore((s) => userId !== 'me' ? s.byUserId[userId] : null);
  const signOut = useAuthStore((s) => s.signOut);

  const isMe = userId === 'me' || userId === me?.uid;
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [bio, setBio] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const fileRef = useRef(null);
  const showToast = useUiStore((s) => s.showToast);

  useEffect(() => {
    let alive = true;
    setLoading(true);
    (async () => {
      if (isMe) {
        const p = await loadMyProfile();
        if (alive) setProfile(p);
      } else if (userId) {
        const p = await loadUser(userId);
        if (alive) setProfile(p);
      }
      if (alive) setLoading(false);
    })();
    return () => { alive = false; };
  }, [userId, isMe, loadMyProfile, loadUser]);

  useEffect(() => {
    if (profile) {
      setBio(profile.bio || '');
      setFirstName(profile.firstName || '');
      setLastName(profile.lastName || '');
    }
  }, [profile]);

  async function onAvatarPick(e) {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      await updateAvatar(file);
      showToast('Đã cập nhật ảnh đại diện', 'success');
      const p = await loadMyProfile();
      setProfile(p);
    } catch {
      showToast('Cập nhật thất bại', 'error');
    }
  }

  async function save() {
    try {
      await updateMe({ FirstName: firstName, LastName: lastName, Bio: bio });
      showToast('Đã lưu hồ sơ', 'success');
      setEditing(false);
      const p = await loadMyProfile();
      setProfile(p);
    } catch (e) {
      showToast(e.message, 'error');
    }
  }

  if (loading) {
    return (
      <div className="right-panel__empty">
        <p>Đang tải hồ sơ...</p>
      </div>
    );
  }
  if (!profile) {
    return (
      <div className="right-panel__empty">
        <div className="right-panel__empty-icon">👤</div>
        <p>Không tìm thấy hồ sơ.</p>
      </div>
    );
  }

  const fullName =
    profile.fullName ||
    `${profile.firstName || ''} ${profile.lastName || ''}`.trim() ||
    me?.email;

  return (
    <div className="profile-section">
      <div className="profile-section__head">
        {isMe ? (
          <>
            <button
              className="profile-section__avatar-btn"
              onClick={() => fileRef.current?.click()}
            >
              <Avatar src={profile.avatar} name={fullName} size={96} ring />
              <span className="profile-section__avatar-overlay">Đổi ảnh</span>
            </button>
            <input
              ref={fileRef}
              type="file"
              accept="image/*"
              onChange={onAvatarPick}
              style={{ display: 'none' }}
            />
          </>
        ) : (
          <Avatar src={profile.avatar} name={fullName} size={96} ring />
        )}
        <h2 className="profile-section__name">{fullName}</h2>
        <p className="profile-section__email">{profile.email}</p>
        {profile.bio && !editing && (
          <p className="profile-section__bio">{profile.bio}</p>
        )}
      </div>

      {isMe && (
        <div className="profile-section__actions">
          {editing ? (
            <>
              <Button variant="primary" onClick={save}>Lưu</Button>
              <Button variant="ghost" onClick={() => setEditing(false)}>Hủy</Button>
            </>
          ) : (
            <>
              <Button variant="secondary" onClick={() => setEditing(true)}>
                Chỉnh sửa hồ sơ
              </Button>
              <Button variant="ghost" onClick={signOut}>Đăng xuất</Button>
            </>
          )}
        </div>
      )}

      {editing && (
        <div className="profile-section__edit">
          <div className="profile-section__row">
            <label>
              <span>Họ</span>
              <input
                className="input"
                value={lastName}
                onChange={(e) => setLastName(e.target.value)}
              />
            </label>
            <label>
              <span>Tên</span>
              <input
                className="input"
                value={firstName}
                onChange={(e) => setFirstName(e.target.value)}
              />
            </label>
          </div>
          <label className="profile-section__field">
            <span>Tiểu sử</span>
            <textarea
              className="input"
              style={{ minHeight: 80, resize: 'vertical' }}
              value={bio}
              onChange={(e) => setBio(e.target.value)}
            />
          </label>
        </div>
      )}

      {!isMe && (
        <div className="profile-section__actions">
          <Button
            variant="primary"
            onClick={async () => {
              const startChat = useChatStore.getState().startChatWithUser;
              const conv = await startChat(profile.id || userId);
              useUiStore.getState().openConversation(conv.id);
            }}
          >
            💬 Nhắn tin
          </Button>
          <Button variant="ghost">Gửi lời mời</Button>
        </div>
      )}

      <Collapsible title="Thông tin" defaultOpen>
        <InfoRow label="Email">{profile.email || '—'}</InfoRow>
        <InfoRow label="Số điện thoại">{profile.phone || '—'}</InfoRow>
        <InfoRow label="Ngày sinh">{profile.dob || '—'}</InfoRow>
      </Collapsible>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/*  FEED SECTION                                                      */
/* ------------------------------------------------------------------ */

function FeedSection({ feedId, isGroup }) {
  if (!feedId) {
    return (
      <div className="right-panel__empty">
        <div className="right-panel__empty-icon">🌿</div>
        <p>Chọn một người/nhóm để xem bảng tin.</p>
      </div>
    );
  }
  return (
    <NewsfeedView
      embedded
      scope={isGroup ? 'group' : 'user'}
      scopeId={feedId}
    />
  );
}

/* ------------------------------------------------------------------ */
/*  Shared UI helpers                                                  */
/* ------------------------------------------------------------------ */

function Collapsible({ title, defaultOpen = false, rightAction, children }) {
  const [open, setOpen] = useState(defaultOpen);
  return (
    <div className={`collapsible ${open ? 'is-open' : ''}`}>
      <button className="collapsible__head" onClick={() => setOpen((v) => !v)}>
        <span>{title}</span>
        <span className="collapsible__chev" aria-hidden>
          {open ? '▾' : '▸'}
        </span>
      </button>
      {rightAction && (
        <div className="collapsible__action" onClick={(e) => e.stopPropagation()}>
          {rightAction}
        </div>
      )}
      {open && children && <div className="collapsible__body">{children}</div>}
    </div>
  );
}

function InfoRow({ label, children }) {
  return (
    <div className="info-row">
      <span className="info-row__label">{label}</span>
      <div className="info-row__value">{children}</div>
    </div>
  );
}

function Switch({ checked, onChange }) {
  return (
    <button
      className={`switch ${checked ? 'is-on' : ''}`}
      onClick={() => onChange(!checked)}
      role="switch"
      aria-checked={checked}
    >
      <span className="switch__knob" />
    </button>
  );
}
