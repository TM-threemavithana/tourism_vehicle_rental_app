import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { User } from '../../entities/user.entity';

export interface AuthenticatedRequest extends Request {
  user: User;
}

export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): User => {
    const request = ctx.switchToHttp().getRequest<AuthenticatedRequest>();
    return request.user;
  },
);
