import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { TransitionsService } from './transitions.service';
import { GetNextTransitionDto } from './dto/get-next-transition.dto';
import { TransitionResponseDto } from './dto/transition-response.dto';

@ApiTags('Transitions')
@Controller('transitions')
export class TransitionsController {
  constructor(private readonly transitionsService: TransitionsService) {}

  @Get('next')
  @ApiOperation({
    summary: 'Get next track transition plan based on harmonic and tempo compatibility',
    description:
      'Calculates Camelot harmonic key, BPM tempo match, and energy compatibility scores to determine the next track transition plan using temperature-controlled softmax selection.',
  })
  @ApiResponse({
    status: 200,
    description: 'Transition plan successfully generated.',
    type: TransitionResponseDto,
  })
  @ApiResponse({
    status: 400,
    description: 'Current track audio analysis is missing or not completed.',
  })
  @ApiResponse({
    status: 404,
    description: 'Current track or eligible candidate tracks not found.',
  })
  getNextTransition(
    @Query() query: GetNextTransitionDto,
  ): Promise<TransitionResponseDto> {
    return this.transitionsService.getNextTransition(query);
  }
}
