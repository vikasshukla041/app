// Helper auth token validation
export const extractUserId = (authHeader) => {
  if (!authHeader || !authHeader.startsWith('Bearer activotrade_mock_jwt_token_for_')) {
    return null;
  }
  return authHeader.replace('Bearer activotrade_mock_jwt_token_for_', '');
};
