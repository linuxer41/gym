import { BaseService } from './_base';
export class IncomeService<T> extends BaseService<T> {
	location = 'incomes';
}
export const incomeService = new IncomeService<Income>();
