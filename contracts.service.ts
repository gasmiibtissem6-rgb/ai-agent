import { Injectable } from '@nestjs/common';

@Injectable()
export class ContractsService {

  findAll() {
    return {
      success: true,
      message: 'Liste des contrats',
      data: [],
    };
  }

  findOne(id: string) {
    return {
      success: true,
      message: 'Contrat trouvé',
      contractId: id,
    };
  }

  create(data: any) {
    return {
      success: true,
      message: 'Contrat créé',
      contract: data,
    };
  }

  update(id: string, data: any) {
    return {
      success: true,
      message: 'Contrat modifié',
      id,
      contract: data,
    };
  }

  delete(id: string) {
    return {
      success: true,
      message: 'Contrat supprimé',
      id,
    };
  }
}
