import { useEffect, useRef } from 'react';
import { useUiStore } from '../../store/uiStore';
import ResizeHandle from './ResizeHandle';
import LeftPanel from './LeftPanel';
import CenterPanel from './CenterPanel';
import RightPanel from './RightPanel';
import './triChatLayout.css';

export default function TriChatLayout() {
  const leftWidth = useUiStore((s) => s.leftWidth);
  const rightWidth = useUiStore((s) => s.rightWidth);
  const leftVisible = useUiStore((s) => s.leftVisible);
  const rightVisible = useUiStore((s) => s.rightVisible);
  const setLeftWidth = useUiStore((s) => s.setLeftWidth);
  const setRightWidth = useUiStore((s) => s.setRightWidth);
  const toggleLeft = useUiStore((s) => s.toggleLeft);
  const toggleRight = useUiStore((s) => s.toggleRight);

  const rootRef = useRef(null);

  // Global keyboard shortcuts
  useEffect(() => {
    function onKey(e) {
      // Cmd/Ctrl + B → toggle left
      if ((e.metaKey || e.ctrlKey) && e.key === 'b' && !e.shiftKey) {
        e.preventDefault();
        toggleLeft();
      }
      // Cmd/Ctrl + Alt + B → toggle right
      if ((e.metaKey || e.ctrlKey) && e.altKey && (e.key === 'b' || e.key === 'B')) {
        e.preventDefault();
        toggleRight();
      }
    }
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [toggleLeft, toggleRight]);

  function handleLeftDelta(dx) {
    if (Number.isNaN(dx)) {
      setLeftWidth(320);
      return;
    }
    setLeftWidth(leftWidth + dx);
  }
  function handleRightDelta(dx) {
    if (Number.isNaN(dx)) {
      setRightWidth(340);
      return;
    }
    setRightWidth(rightWidth - dx);
  }

  return (
    <div className="tri-chat-layout" ref={rootRef}>
      {/* 3-panel container — top bar đã được lược bỏ */}
      <div className="tri-chat-layout__panels">
        {leftVisible && (
          <>
            <aside
              className="tri-chat-layout__panel tri-chat-layout__panel--left"
              style={{ width: leftWidth, minWidth: leftWidth, maxWidth: leftWidth }}
            >
              <LeftPanel />
            </aside>
            <ResizeHandle onDelta={handleLeftDelta} direction="right" />
          </>
        )}

        <main
          className="tri-chat-layout__panel tri-chat-layout__panel--center"
          style={{ flex: 1, minWidth: 360 }}
        >
          <CenterPanel />
        </main>

        {rightVisible && (
          <>
            <ResizeHandle onDelta={handleRightDelta} direction="left" />
            <aside
              className="tri-chat-layout__panel tri-chat-layout__panel--right"
              style={{ width: rightWidth, minWidth: rightWidth, maxWidth: rightWidth }}
            >
              <RightPanel />
            </aside>
          </>
        )}
      </div>

      {/* Floating chevron buttons to toggle panels */}
      <button
        className={`tri-chat-layout__dock tri-chat-layout__dock--left ${!leftVisible ? 'is-closed' : ''}`}
        onClick={toggleLeft}
        aria-label={leftVisible ? 'Ẩn panel trái' : 'Hiện panel trái'}
        title={leftVisible ? 'Ẩn panel trái (⌘B)' : 'Hiện panel trái (⌘B)'}
      >
        {leftVisible ? '‹' : '›'}
      </button>
      <button
        className={`tri-chat-layout__dock tri-chat-layout__dock--right ${!rightVisible ? 'is-closed' : ''}`}
        onClick={toggleRight}
        aria-label={rightVisible ? 'Ẩn panel phải' : 'Hiện panel phải'}
        title={rightVisible ? 'Ẩn panel phải (⌘⌥B)' : 'Hiện panel phải (⌘⌥B)'}
      >
        {rightVisible ? '›' : '‹'}
      </button>

      <ResetHotkey />
    </div>
  );
}

function ResetHotkey() {
  useEffect(() => {
    function onKey(e) {
      if ((e.metaKey || e.ctrlKey) && e.shiftKey && (e.key === 'r' || e.key === 'R')) {
        e.preventDefault();
        useUiStore.getState().resetLayout();
      }
    }
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);
  return null;
}
