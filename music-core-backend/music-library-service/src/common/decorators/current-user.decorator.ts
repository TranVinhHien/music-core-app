import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface GatewayUser {
  id?: string;
  email?: string;
  roles: string[];
  requestId?: string;
}

export const CurrentUser = createParamDecorator(
  (data: keyof GatewayUser | undefined, ctx: ExecutionContext): GatewayUser | any => {
    const request = ctx.switchToHttp().getRequest();
    const headers = request.headers;

    const rolesHeader = headers['x-user-roles'];
    let roles: string[] = [];
    if (rolesHeader) {
      roles = String(rolesHeader)
        .split(',')
        .map((r) => r.trim());
    }

    const user: GatewayUser = {
      id: headers['x-user-id'] as string | undefined,
      email: headers['x-user-email'] as string | undefined,
      roles,
      requestId: headers['x-request-id'] as string | undefined,
    };

    if (data) {
      return user[data];
    }
    return user;
  },
);
