import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';

export class AdminLoginDto {
  @ApiProperty({ example: 'admin@ideal.local', format: 'email' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'ChangeMe123!', minLength: 8 })
  @IsString()
  @IsNotEmpty()
  @MinLength(8)
  password!: string;
}
