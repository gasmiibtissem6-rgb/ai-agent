// services/api/src/common/interceptors/transform.interceptor.ts
import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { v4 as uuidv4 } from 'uuid';

export interface StandardResponse<T> {
  success: boolean;
  requestId: string;
  data: T;
}

@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, StandardResponse<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<StandardResponse<T>> {
    const ctx = context.switchToHttp();
    const response = ctx.getResponse();
    
    // Generate a unique Request ID for tracking/logging
    const requestId = uuidv4();
    response.setHeader('X-Request-ID', requestId);

    return next.handle().pipe(
      map((data) => ({
        success: true,
        requestId,
        data: data || null, // Wraps whatever your controller returns inside this clean layout
      })),
    );
  }
}