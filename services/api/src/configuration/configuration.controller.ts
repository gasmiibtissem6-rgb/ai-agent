import { Controller, Get } from '@nestjs/common';

type ConfigurationCheck = {
  name: string;
  status: 'configured' | 'missing' | 'pending';
  detail: string;
};

export type ConfigurationStatus = {
  projectName: 'IDEAL';
  serviceName: 'api';
  apiVersion: 'v1';
  environment: string;
  status: 'operational' | 'configuration_pending';
  checkedAt: string;
  message: string;
  checks: ConfigurationCheck[];
  employeeGuidance: string[];
};

@Controller('configuration')
export class ConfigurationController {
  @Get('status')
  getStatus(): ConfigurationStatus {
    const checks: ConfigurationCheck[] = [
      {
        name: 'API runtime',
        status: 'configured',
        detail: 'NestJS is responding through /api/v1.',
      },
      {
        name: 'Business workflow boundary',
        status: 'configured',
        detail:
          'Deal, approval, file, admin, and audit modules are registered.',
      },
      {
        name: 'Database connection',
        status: process.env.DATABASE_URL ? 'configured' : 'pending',
        detail: process.env.DATABASE_URL
          ? 'DATABASE_URL is present.'
          : 'DATABASE_URL is not set yet. This is expected before Supabase schema setup.',
      },
      {
        name: 'Supabase project',
        status: process.env.SUPABASE_URL ? 'configured' : 'pending',
        detail: process.env.SUPABASE_URL
          ? 'SUPABASE_URL is present.'
          : 'SUPABASE_URL is not set yet. Add it when the Supabase project is provisioned.',
      },
      {
        name: 'Stripe integration',
        status: process.env.STRIPE_SECRET_KEY ? 'configured' : 'pending',
        detail: process.env.STRIPE_SECRET_KEY
          ? 'Stripe secret key is present.'
          : 'Stripe is documented and pending integration credentials.',
      },
    ];

    const hasMissingRuntimeDependency = checks.some(
      (check) => check.status === 'missing',
    );

    return {
      projectName: 'IDEAL',
      serviceName: 'api',
      apiVersion: 'v1',
      environment: process.env.NODE_ENV ?? 'development',
      status: hasMissingRuntimeDependency
        ? 'configuration_pending'
        : 'operational',
      checkedAt: new Date().toISOString(),
      message:
        'IDEAL API is reachable. Pending integration credentials are expected until Supabase, Stripe, and KYC environments are provisioned.',
      checks,
      employeeGuidance: [
        'If this endpoint responds, the admin dashboard can reach the backend API.',
        'Pending integration credentials do not block UI/API foundation work.',
        'Before production, every pending integration check must become configured.',
      ],
    };
  }
}
