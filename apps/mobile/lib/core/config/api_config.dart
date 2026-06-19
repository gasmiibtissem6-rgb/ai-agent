class ApiConfig {
  const ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'IDEAL_API_BASE_URL',
    defaultValue: 'http://localhost:3001/api/v1',
  );
}
