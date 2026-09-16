import { createBrowserRouter, Navigate, Outlet } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import TriChatLayout from '../components/layout/TriChatLayout';

const Splash = () => <></>;

function RequireAuth() {
  const ready = useAuthStore((s) => s.ready);
  const user = useAuthStore((s) => s.user);
  if (!ready) return null;
  return user ? <Outlet /> : <Navigate to="/" replace />;
}

function RedirectIfAuth() {
  const ready = useAuthStore((s) => s.ready);
  const user = useAuthStore((s) => s.user);
  if (!ready) return null;
  return user ? <Navigate to="/app" replace /> : <Outlet />;
}

import Home from '../pages/Home';
import Login from '../pages/auth/Login';
import SignUp from '../pages/auth/SignUp';
import OtpVerify from '../pages/auth/OtpVerify';
import SetPassword from '../pages/auth/SetPassword';
import EnterName from '../pages/auth/EnterName';
import PersonalInfo from '../pages/auth/PersonalInfo';
import UpdateAvatar from '../pages/auth/UpdateAvatar';
import CreatePost from '../pages/feed/CreatePost';
import CreateStory from '../pages/feed/CreateStory';
import StoryViewer from '../pages/feed/StoryViewer';
import AddFriend from '../pages/friends/AddFriend';
import Contacts from '../pages/friends/Contacts';
import FriendRequests from '../pages/friends/FriendRequests';
import CallRoom from '../pages/call/CallRoom';
import NotFound from '../pages/NotFound';

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
      { path: '/otp-verify', element: <OtpVerify /> },
    ],
  },
  {
    element: <RequireAuth />,
    children: [
      // Single primary app shell — handles everything via state
      { path: '/app', element: <TriChatLayout /> },

      // Standalone routes (post creation, call room) — fullscreen overlays
      { path: '/create-post', element: <CreatePost /> },
      { path: '/create-story', element: <CreateStory /> },
      { path: '/story-viewer', element: <StoryViewer /> },
      { path: '/add-friend', element: <AddFriend /> },
      { path: '/contacts', element: <Contacts /> },
      { path: '/friend-requests', element: <FriendRequests /> },
      { path: '/call', element: <CallRoom /> },

      // Legacy aliases → redirect to /app (back-compat with old bookmarks)
      { path: '/chat-list', element: <Navigate to="/app" replace /> },
      { path: '/chat-list/:id', element: <Navigate to="/app" replace /> },
      { path: '/newfeed', element: <Navigate to="/app" replace /> },
      { path: '/friends', element: <Navigate to="/app" replace /> },
      { path: '/profile', element: <Navigate to="/app" replace /> },
      { path: '/my-profile', element: <Navigate to="/app" replace /> },
      { path: '/new-conversation', element: <Navigate to="/app" replace /> },
      { path: '/group-info/:id', element: <Navigate to="/app" replace /> },
    ],
  },
  { path: '*', element: <NotFound /> },
]);
