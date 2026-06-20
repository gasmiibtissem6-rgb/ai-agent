// services/api/src/app.controller.ts
import { Controller, Get, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from './common/guards/auth.guard';
// We import it without assigning it directly to the decorated parameter signature row
import type { Request } from 'express'; 

@Controller()
export class AppController {
  
  
  @UseGuards(AuthGuard)
  getSecureData(@Req() req: any) { // 👈 Changing this to 'any' satisfies isolatedModules metadata rules
    const expressReq = req as Request; // Cast it back inside if you want local typing utilities
    
    return {
      message: 'If you see this, your AuthGuard successfully verified the token!',
      // Using explicit type bypass cleanly resolves the index type warning
      userPayload: (req as any).user, 
    };
  }
}