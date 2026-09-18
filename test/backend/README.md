# Backend Tests

## Overview

Comprehensive test suite for TriChat backend, focusing on the **Friendship feature** business logic.

## Test Coverage

### `FriendshipServiceTests.cs` (44 tests)

Unit tests for `FriendshipService` using an in-memory data store (no Firestore emulator required).

#### Section 1: GetFriendsPagedAsync (5 tests)
- ✅ Empty friend list returns zero total
- ✅ Friends sorted by recent chat (most recent first)
- ✅ Pagination with limit/offset
- ✅ Friends without recent chat sorted by friendsSince
- ✅ Both-direction friendships handled correctly (sender/addressee)

#### Section 2: GetSuggestionsPagedAsync — Zero Friends (4 tests)
- ✅ Newest users shown first (created_at DESC)
- ✅ MutualCount is null for all suggestions
- ✅ Self excluded from suggestions
- ✅ Pagination works correctly

#### Section 3: GetSuggestionsPagedAsync — Has Friends (4 tests)
- ✅ Sorted by mutual friends count (DESC)
- ✅ MutualCount populated correctly
- ✅ Users with 0 mutual friends ranked lower
- ✅ Pagination respects mutual count ordering

#### Section 4: GetSuggestionsPagedAsync — Exclusions (3 tests)
- ✅ Already-friends excluded from suggestions
- ✅ Pending requests (sent/received) excluded
- ✅ Disabled users (status=false) excluded

#### Section 5: GetPendingRequestsPagedAsync (2 tests)
- ✅ Only pending requests returned
- ✅ Pagination works correctly

#### Section 6: GetBlockedUsersAsync (2 tests)
- ✅ Only blocked users returned (where current user is blocker)
- ✅ Reverse direction blocks ignored

#### Section 7: SendRequestAsync — Business Rules (10 tests)
- ✅ Cannot send request to self
- ✅ Cannot send request to non-existent user
- ✅ Cannot send request to existing friend
- ✅ Cannot send duplicate pending request
- ✅ Auto-accept when pending request exists in reverse direction (Zalo UX)
- ✅ Cannot send request when you blocked the user
- ✅ Cannot send request when user blocked you
- ✅ Declined requests can be re-sent (old doc deleted, new created)
- ✅ Success creates pending document with correct fields
- ✅ SignalR notification sent to addressee

#### Section 8: RespondAsync — Accept/Decline (5 tests)
- ✅ Accept updates status to "accepted"
- ✅ Decline updates status to "declined"
- ✅ Only recipient can respond (not sender)
- ✅ Already-accepted requests cannot be re-accepted
- ✅ SignalR notifications sent to sender

#### Section 9: CancelRequestAsync & UnfriendAsync (4 tests)
- ✅ Cancel deletes pending request document
- ✅ Only sender can cancel request
- ✅ Unfriend deletes accepted friendship document
- ✅ Cannot unfriend non-friends

#### Section 10: BlockAsync & UnblockAsync (5 tests)
- ✅ Block creates blocked document
- ✅ Cannot block already-blocked user
- ✅ Blocking existing friend updates document status to "blocked"
- ✅ Cannot block self
- ✅ Unblock deletes blocked document
- ✅ Only blocker can unblock
- ✅ Cannot unblock non-blocked user

## Running Tests

```bash
cd backend
dotnet test tests/backend.Tests/backend.Tests.csproj

# With verbose output
dotnet test tests/backend.Tests/backend.Tests.csproj --logger "console;verbosity=detailed"

# Run specific test
dotnet test --filter "FullyQualifiedName~SendRequest_Success_CreatesPendingDoc"
```

## Test Infrastructure

### `InMemoryFriendshipDataStore.cs`

In-memory implementation of `IFriendshipDataStore` for fast, isolated tests:
- Thread-safe with `lock` blocks
- Simulates Firestore queries (WhereIn, WhereArrayContains, OrderBy)
- Matches Firestore behavior (e.g., filters disabled users)
- Reset between tests via `Dispose()`

### Mocked Dependencies

- `ILogger<FriendshipService>` — mocked with Moq
- `IHubContext<FriendHub>` — mocked SignalR hub (all SendAsync calls ignored)

## Adding New Tests

1. Add test method with `[Fact]` attribute
2. Use helper methods:
   - `AddUser(id, firstName, lastName, createdAt, status=true)`
   - `AddFriend(userId1, userId2, since)`
   - `AddPending(senderId, addresseeId, createdAt)`
   - `AddConversation(convId, user1, user2, updatedAt)`
3. Call service method
4. Assert result using `Xunit.Assert`
5. Check `AppException.ErrorCode` for expected errors

## Best Practices

- Each test is independent (uses `IDisposable` to clear state)
- Tests are named clearly: `MethodName_Scenario_ExpectedResult`
- Business rules tested exhaustively (all error paths + happy path)
- SignalR calls are fire-and-forget (tests don't verify hub invocations)

## Future Work

- [ ] Add tests for `FriendController` (integration tests)
- [ ] Add tests for `ChatService`, `FeedService`
- [ ] Add tests for SignalR hubs (`ChatHub`, `FriendHub`)
- [ ] Add tests for middleware (`FirebaseAuthMiddleware`, `GlobalExceptionHandler`)
- [ ] Add tests for validators (FluentValidation)
- [ ] Integration tests with real Firestore emulator
