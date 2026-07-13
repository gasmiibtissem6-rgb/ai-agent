import { NestFactory } from '@nestjs/core';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from '../src/app.module';
import * as fs from 'fs';
import * as path from 'path';

async function generate() {
  const app = await NestFactory.create(AppModule);
  const config = new DocumentBuilder().setTitle('IDEAL API').build();
  const document = SwaggerModule.createDocument(app, config);
  
  const schemas = document.components?.schemas;
  let tsInterfaces = `// Auto-generated from Backend DTOs - Do not edit manually\n\n`;
  
  if (schemas) {
    Object.entries(schemas).forEach(([name, schema]: [string, any]) => {
      tsInterfaces += `export interface ${name} {\n`;
      if (schema.properties) {
        Object.entries(schema.properties).forEach(([propName, propDetails]: [string, any]) => {
          const isRequired = schema.required?.includes(propName) ? '' : '?';
          let type = 'any';
          
          if (propDetails.type === 'string') type = 'string';
          else if (propDetails.type === 'number' || propDetails.type === 'integer') type = 'number';
          else if (propDetails.type === 'boolean') type = 'boolean';
          else if (propDetails.type === 'array') {
            const itemType = propDetails.items?.type === 'string' ? 'string' : 'any';
            type = `${itemType}[]`;
          }
          
          tsInterfaces += `  ${propName}${isRequired}: ${type};\n`;
        });
      }
      tsInterfaces += `}\n\n`;
    });
  }

  // Adjust relative path here to target your Next.js project directory
 const outputPath = path.join(
  __dirname,
  '../../../apps/admin/src/types/backend-api.d.ts',
);
  
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, tsInterfaces);
  console.log('✨ Shared DTO types successfully generated and synced!');
  await app.close();
}

generate();