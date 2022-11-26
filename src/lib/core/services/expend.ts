import { BaseService } from './_base';
export class ExpendService<T> extends BaseService<T> {
	location = 'expends';
}
export const expendService = new ExpendService<Expend>();
