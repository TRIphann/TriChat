import { createBrowserRouter, Navigate, Outlet } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import AppShell from '../components/layout/AppShell';

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
  return user ? <Navigate to="/chat-list" replace /> : <Outlet />;
}

import Home from '../pages/Home';
import Login from '../pages/auth/Login';
import SignUp from '../pages/auth/SignUp';
import OtpVerify from '../pages/auth/OtpVerify';
import SetPassword from '../pages/auth/SetPassword';
import EnterName from '../pages/auth/EnterName';
import PersonalInfo from '../pages/auth/PersonalInfo';
import UpdateAvatar from '../pages/auth/UpdateAvatar';
import ChatList from '../pages/chat/ChatList';
import ChatRoom from '../pages/chat/ChatRoom';
import NewConversation from '../pages/chat/NewConversation';
import GroupInfo from '../pages/chat/GroupInfo';
import Newsfeed from '../pages/feed/Newsfeed';
import CreatePost from '../pages/feed/CreatePost';
import CreateStory from '../pages/feed/CreateStory';
import StoryViewer from '../pages/feed/StoryViewer';
import FriendList from '../pages/friends/FriendList';
import FriendRequests from '../pages/friends/FriendRequests';
import AddFriend from '../pages/friends/AddFriend';
import Contacts from '../pages/friends/Contacts';
import Profile from '../pages/profile/Profile';
import MyProfile from '../pages/profile/MyProfile';
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
      {
        element: <AppShell />,
        children: [
          { path: '/chat-list', element: <ChatList /> },
          { path: '/chat-list/:id', element: <ChatRoom /> },
          { path: '/newfeed', element: <Newsfeed /> },
          { path: '/create-post', element: <CreatePost /> },
          { path: '/create-story', element: <CreateStory /> },
          { path: '/story-viewer', element: <StoryViewer /> },
          { path: '/profile', element: <Profile /> },
          { path: '/my-profile', element: <MyProfile /> },
          { path: '/friends', element: <FriendList /> },
          { path: '/friend-requests', element: <FriendRequests /> },
          { path: '/add-friend', element: <AddFriend /> },
          { path: '/contacts', element: <Contacts /> },
          { path: '/new-conversation', element: <NewConversation /> },
          { path: '/group-info/:id', element: <GroupInfo /> },
          { path: '/call', element: <CallRoom /> },
        ],
      },
    ],
  },
  { path: '*', element: <NotFound /> },
]);
