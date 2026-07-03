import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateContractDto } from './dto/create-contract.dto';
import { EmailService } from './email.service';

@Injectable()
export class ContractsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly emailService: EmailService,
  ) {}

  findAll() {
    return this.prisma.contract.findMany({
      include: { parties: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    const contract = await this.prisma.contract.findUnique({
      where: { id },
      include: { parties: true, sendLogs: true },
    });
    if (!contract) {
      throw new NotFoundException('Contrat introuvable');
    }
    return contract;
  }

  create(data: CreateContractDto) {
    return this.prisma.contract.create({
      data: {
        title: data.title,
        description: data.description,
        contractType: data.contractType,
        content: data.content,
        parties: {
          create: (data.parties ?? []).map((p) => ({
            role: p.role,
            fullName: p.fullName,
            functionRole: p.functionRole,
            address: p.address,
            email: p.email,
          })),
        },
      },
      include: { parties: true },
    });
  }

  async update(id: string, data: any) {
    await this.findOne(id);
    return this.prisma.contract.update({
      where: { id },
      data: {
        title: data.title,
        description: data.description,
        content: data.content,
      },
      include: { parties: true },
    });
  }

  async delete(id: string) {
    await this.findOne(id);
    return this.prisma.contract.delete({ where: { id } });
  }

  async sendToParty(contractId: string, email: string) {
    const contract = await this.findOne(contractId);
    await this.prisma.contractSendLog.create({
      data: { contractId, sentToEmail: email },
    });
    const updated = await this.prisma.contract.update({
      where: { id: contractId },
      data: { status: 'SENT' },
      include: { parties: true },
    });
    await this.emailService.sendContractEmail(
      email,
      contract.title,
      contractId,
    );
    return {
      success: true,
      message: `Contrat envoyé à ${email}`,
      contract: updated,
    };
  }
}
