import { Injectable } from '@nestjs/common';

export type AppInfo = {
  projectName: string;
  status: string;
  serviceName: string;
};

export type HealthStatus = {
  status: string;
};

@Injectable()
export class AppService {
  getAppInfo(): AppInfo {
    return {
      projectName: 'IDEAL',
      status: 'ready',
      serviceName: 'api',
    };
  }

  getHealth(): HealthStatus {
    return {
      status: 'ok',
    };
  }
}
