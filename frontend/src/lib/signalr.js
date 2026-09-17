// SignalR — ChatHub + FriendHub
import * as signalR from '@microsoft/signalr';
import { buildHubUrl } from './apiConfig';
import { auth } from './firebase';

function options(extraQuery = {}) {
  return {
    skipNegotiation: true,
    transport: signalR.HttpTransportType.WebSockets,
    accessTokenFactory: async () => {
      const u = auth.currentUser;
      return u ? u.getIdToken() : '';
    },
    ...extraQuery,
  };
}

export function createChatConnection({ userId } = {}) {
  // ChatHub.OnConnectedAsync đọc userId từ query string để join group user_{uid}.
  // Không gửi access_token trong query vì backend dùng Bearer header (accessTokenFactory).
  const query = userId ? { userId } : undefined;
  const url = buildHubUrl('/hubs/chat', query);
  return new signalR.HubConnectionBuilder()
    .withUrl(url, options())
    .withAutomaticReconnect([2000, 5000, 10000, 30000])
    .configureLogging(signalR.LogLevel.Warning)
    .build();
}

export function createFriendConnection() {
  return new signalR.HubConnectionBuilder()
    .withUrl(buildHubUrl('/hubs/friend'), options())
    .withAutomaticReconnect([2000, 5000, 10000, 30000])
    .configureLogging(signalR.LogLevel.Warning)
    .build();
}
