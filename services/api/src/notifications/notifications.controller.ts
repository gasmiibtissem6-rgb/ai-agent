import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { NotificationsService } from './notifications.service';

@ApiTags('notifications')
@ApiBearerAuth()
@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: "List the caller's notifications (newest first)." })
  async list(
    @CurrentUser('profileId') profileId: string,
    @Query('limit') limit?: string,
  ) {
    const parsed = limit ? parseInt(limit, 10) : 50;
    return this.notifications.listForProfile(
      profileId,
      Number.isFinite(parsed) ? parsed : 50,
    );
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Number of unread notifications for the caller.' })
  async unreadCount(@CurrentUser('profileId') profileId: string) {
    return this.notifications.unreadCount(profileId);
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark a single notification as read.' })
  async markRead(
    @CurrentUser('profileId') profileId: string,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.notifications.markRead(profileId, id);
  }

  @Post('read-all')
  @ApiOperation({ summary: 'Mark all notifications as read.' })
  async markAllRead(@CurrentUser('profileId') profileId: string) {
    return this.notifications.markAllRead(profileId);
  }
}
