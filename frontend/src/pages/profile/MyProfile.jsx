import { useEffect, useRef, useState } from 'react';
import { useAuthStore } from '../../store/authStore';
import { useProfileStore } from '../../store/profileStore';
import { Avatar, Button, Input } from '../../components/ui';
import { pickFile, readAsDataUrl } from '../../lib/format';
import { useUiStore } from '../../store/uiStore';

export default function MyProfile() {
  const user = useAuthStore((s) => s.user);
  const loadMyProfile = useProfileStore((s) => s.loadMyProfile);
  const updateAvatar = useProfileStore((s) => s.updateAvatar);
  const updateMe = useProfileStore((s) => s.updateMe);
  const profile = useProfileStore((s) => s.myProfile) || useAuthStore((s) => s.profile);
  const signOut = useAuthStore((s) => s.signOut);
  const showToast = useUiStore((s) => s.showToast);
  const fileRef = useRef(null);
  const [editing, setEditing] = useState(false);
  const [bio, setBio] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');

  useEffect(() => {
    loadMyProfile();
  }, [loadMyProfile]);

  useEffect(() => {
    if (profile) {
      setBio(profile.bio || '');
      setFirstName(profile.firstName || profile.first_name || '');
      setLastName(profile.lastName || profile.last_name || '');
    }
  }, [profile]);

  async function onAvatarPick(e) {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      await updateAvatar(file);
      showToast('Đã cập nhật ảnh đại diện', 'success');
    } catch (err) {
      showToast('Cập nhật thất bại', 'error');
    }
  }

  async function save() {
    try {
      await updateMe({ FirstName: firstName, LastName: lastName, Bio: bio });
      showToast('Đã lưu hồ sơ', 'success');
      setEditing(false);
    } catch (e) {
      showToast(e.message, 'error');
    }
  }

  const fullName = profile?.fullName || `${profile?.firstName || ''} ${profile?.lastName || ''}`.trim() || user?.email;

  return (
    <div style={{ maxWidth: 720, margin: '0 auto' }}>
      <header style={{ display: 'flex', alignItems: 'center', gap: 24, marginBottom: 32 }}>
        <button onClick={() => fileRef.current?.click()} style={{ background: 'transparent' }}>
          <Avatar src={profile?.avatar || user?.photoURL} name={fullName} size={120} ring />
        </button>
        <input ref={fileRef} type="file" accept="image/*" onChange={onAvatarPick} style={{ display: 'none' }} />
        <div style={{ flex: 1 }}>
          <h1 className="text-serif" style={{ fontSize: 32, margin: 0 }}>{fullName}</h1>
          <p style={{ color: 'var(--text-2)' }}>{profile?.email || user?.email}</p>
        </div>
        <Button variant="ghost" onClick={signOut}>Đăng xuất</Button>
      </header>

      {editing ? (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div style={{ display: 'flex', gap: 12 }}>
            <Input label="Họ" value={lastName} onChange={(e) => setLastName(e.target.value)} />
            <Input label="Tên" value={firstName} onChange={(e) => setFirstName(e.target.value)} />
          </div>
          <label className="field">
            <span className="field__label">Tiểu sử</span>
            <textarea
              className="field__control"
              style={{ minHeight: 96, padding: 14, resize: 'vertical' }}
              value={bio}
              onChange={(e) => setBio(e.target.value)}
            />
          </label>
          <div style={{ display: 'flex', gap: 12 }}>
            <Button variant="primary" onClick={save}>Lưu</Button>
            <Button variant="ghost" onClick={() => setEditing(false)}>Hủy</Button>
          </div>
        </div>
      ) : (
        <div>
          <p style={{ color: 'var(--text-2)', marginBottom: 24 }}>{profile?.bio || 'Chưa có tiểu sử.'}</p>
          <Button variant="secondary" onClick={() => setEditing(true)}>Chỉnh sửa hồ sơ</Button>
        </div>
      )}
    </div>
  );
}
