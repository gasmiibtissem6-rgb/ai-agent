import { Controller, Get, Query, Param, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { ContractArchiveService } from './contract-archive.service';
import { DealStatus } from '@prisma/client';

@Controller('admin/contract-archive')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('SUPER_ADMIN', 'ADMIN')
export class ContractArchiveController {
  constructor(
    private readonly contractArchiveService: ContractArchiveService,
  ) {}

  /**
   * Fetch all archived/locked contracts with pagination and filtering
   */
  @Get()
  async getArchivedContracts(
    @Query('status') status?: DealStatus,
    @Query('search') search?: string,
    @Query('page') page: string = '1',
    @Query('limit') limit: string = '10',
  ) {
    return this.contractArchiveService.getArchivedContracts({
      status,
      search,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
    });
  }

  /**
   * Fetch complete version history tree for a specific contract
   */
  @Get(':dealId/version-history')
  async getContractVersionHistory(@Param('dealId') dealId: string) {
    return this.contractArchiveService.getContractVersionHistory(dealId);
  }

  /**
   * Fetch specific version details for compliance inspection
   */
  @Get('version/:versionId')
  async getVersionDetails(@Param('versionId') versionId: string) {
    return this.contractArchiveService.getVersionDetails(versionId);
  }
}
