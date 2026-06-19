import { ConfigurationController } from './configuration.controller';

describe('ConfigurationController', () => {
  it('returns a professional employee-facing configuration status', () => {
    const status = new ConfigurationController().getStatus();

    expect(status.projectName).toBe('IDEAL');
    expect(status.serviceName).toBe('api');
    expect(status.apiVersion).toBe('v1');
    expect(status.checks.length).toBeGreaterThan(0);
    expect(status.employeeGuidance.length).toBeGreaterThan(0);
  });
});
