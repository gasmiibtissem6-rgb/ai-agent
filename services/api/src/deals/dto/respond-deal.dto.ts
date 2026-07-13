import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

/** An invited party's answer to a deal invitation: accept or refuse. */
export class RespondDealDto {
  @ApiProperty({ description: 'true to accept the deal, false to refuse it.' })
  @IsBoolean()
  accept!: boolean;
}
