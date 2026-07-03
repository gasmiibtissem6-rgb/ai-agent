// services/api/src/common/interceptors/transform.interceptor.ts
import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { v4 as uuidv4 } from 'uuid';

export interface StandardResponse<T> {
  success: boolean;
  message: string;
  data: T;
  requestId: string;
}

/** Optional envelope a controller can return to set a custom success message. */
interface MessagedPayload<T> {
  message: string;
  data: T;
}

function isMessagedPayload<T>(value: unknown): value is MessagedPayload<T> {
  return (
    typeof value === 'object' &&
    value !== null &&
    'message' in value &&
    'data' in value &&
    typeof (value as { message: unknown }).message === 'string'
  );
}

@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<
  T,
  StandardResponse<T>
> {
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<StandardResponse<T>> {
    const ctx = context.switchToHttp();
    const response = ctx.getResponse();

    // Generate a unique Request ID for tracking/logging
    const requestId = uuidv4();
    response.setHeader('X-Request-ID', requestId);

    return next.handle().pipe(
      map((payload): StandardResponse<T> => {
        // Allow controllers to return { message, data } to customize the message.
        if (isMessagedPayload<T>(payload)) {
          return {
            success: true,
            message: payload.message,
            data: payload.data ?? (null as T),
            requestId,
          };
        }

        return {
          success: true,
          message: 'Success',
          data: (payload as T) ?? (null as T),
          requestId,
        };
      }),
    );
  }
}
