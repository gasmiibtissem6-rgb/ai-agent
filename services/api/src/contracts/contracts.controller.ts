import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
} from '@nestjs/common';
import { ContractsService } from './contracts.service';
import { CreateContractDto } from './dto/create-contract.dto';

@Controller('contracts')
export class ContractsController {
  constructor(private readonly contractsService: ContractsService) {}

  @Get()
  findAll() {
    return this.contractsService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.contractsService.findOne(id);
  }

  @Post()
  create(@Body() body: CreateContractDto) {
    return this.contractsService.create(body);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() body: any) {
    return this.contractsService.update(id, body);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.contractsService.delete(id);
  }

  @Post(':id/send')
  send(@Param('id') id: string, @Body('email') email: string) {
    return this.contractsService.sendToParty(id, email);
  }
}
