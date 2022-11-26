import { BaseService } from './_base';
export class PlanService<T> extends BaseService<T> {
	location = 'plans';
}
export const planService = new PlanService<Plan>();
