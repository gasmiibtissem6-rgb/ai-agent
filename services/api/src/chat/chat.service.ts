import {
  BadGatewayException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

import { detectChatMode } from './chat.types';

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);

  constructor(
    private readonly httpService: HttpService,
  ) {}

  async sendMessage(dto: {
    message: string;
    history?: any[];
    userId?: string | number;
    sessionId?: string;
    image?: string;
  }) {
    const mode = detectChatMode(
      dto.message,
      dto.history,
    );

    const parsedUserId = Number(dto.userId ?? 123);

    const userId = Number.isNaN(parsedUserId)
      ? 123
      : parsedUserId;

    const sessionId =
      dto.sessionId?.trim() || `user-${userId}`;

    try {
      const response = await firstValueFrom(
        this.httpService.post(
          'http://127.0.0.1:8000/langgraph-agent',
          {
            message: dto.message,
            user_id: userId,
            session_id: sessionId,
          },
        ),
      );

      this.logger.log(
        `Réponse FastAPI : ${JSON.stringify(response.data)}`,
      );

      const answer =
        response.data.final_answer ??
        response.data.answer ??
        response.data.response ??
        response.data.message ??
        response.data.result?.next_question ??
        'Aucune réponse générée par l’agent.';

      return {
        answer,
        mode,
        userId,
        sessionId,
        agent: response.data.agent,
        agentMode: response.data.mode,
        plan: response.data.plan,
        result: response.data.result,
        observations:
          response.data.observations ?? [],
        metrics:
          response.data.metrics ?? {},
      };
    } catch (error: any) {
      const details =
        error?.response?.data ??
        error?.message ??
        'Erreur inconnue';

      this.logger.error(
        'Erreur FastAPI',
        JSON.stringify(details),
      );

      throw new BadGatewayException({
        message:
          'Impossible de communiquer avec l’agent IA.',
        details,
      });
    }
  }
}