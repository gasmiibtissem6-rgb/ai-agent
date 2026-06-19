import { Controller, Get } from '@nestjs/common';

export type HealthStatus = {
  status: 'ok';
  service: 'api';
  version: 'v1';
};

@Controller('health')
export class HealthController {
  @Get()
  getHealth(): HealthStatus {
    return {
      status: 'ok',
      service: 'api',
      version: 'v1',
    };
  }
}
