import { Injectable } from '@nestjs/common';

export type AppInfo = {
  projectName: string;
  productSubtitle: string;
  status: string;
  serviceName: string;
  apiVersion: string;
};

@Injectable()
export class AppService {
  getAppInfo(): AppInfo {
    return {
      projectName: 'IDEAL',
      productSubtitle: 'Trusted Digital Deals and Contracts',
      status: 'ready',
      serviceName: 'api',
      apiVersion: 'v1',
    };
  }
}
