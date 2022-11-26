import { BaseService } from './_base';
export class UserService<T> extends BaseService<T> {
	location = 'users';
}
export const userService = new UserService<User>();
