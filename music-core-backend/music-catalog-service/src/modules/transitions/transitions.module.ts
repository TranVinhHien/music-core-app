import { Module } from '@nestjs/common';
import { TransitionsController } from './transitions.controller';
import { TransitionsService } from './transitions.service';

@Module({
  controllers: [TransitionsController],
  providers: [TransitionsService],
  exports: [TransitionsService],
})
export class TransitionsModule {}
