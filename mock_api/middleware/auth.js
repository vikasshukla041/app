import { randomUUID } from 'node:crypto';

const ACCESS_PREFIX = 'activotrade_mock_jwt_token_for_';
const REFRESH_PREFIX = 'activotrade_mock_refresh_token_for_';

// Helper auth token validation
export const extractUserId = (authHeader) => {
  if (!authHeader || !authHeader.startsWith(`Bearer ${ACCESS_PREFIX}`)) {
    return null;
  }
  return authHeader.replace(`Bearer ${ACCESS_PREFIX}`, '');
};

// Issues the pair the app expects from both /login and /refresh.
//
// The access token stays derivable from the user id so the docs' "authorize
// with activotrade_mock_jwt_token_for_user_demo_123" still works. The refresh
// token carries a nonce so every exchange really does hand back a new string,
// which is what the client persists and what its rotation handling expects.
//
// Unlike the real backend, the old refresh token is not invalidated - there is
// no token store here to revoke against.
export const issueTokenPair = (userId) => ({
  accessToken: `${ACCESS_PREFIX}${userId}`,
  refreshToken: `${REFRESH_PREFIX}${userId}.${randomUUID()}`,
});

export const userIdFromRefreshToken = (refreshToken) => {
  if (!refreshToken || !refreshToken.startsWith(REFRESH_PREFIX)) {
    return null;
  }
  const [userId] = refreshToken.slice(REFRESH_PREFIX.length).split('.');
  return userId || null;
};
