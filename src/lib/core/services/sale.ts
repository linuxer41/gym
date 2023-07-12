import { BaseService } from './_base';
export class SaleService<T> extends BaseService<T> {
	location = 'sales';
}
export const saleService = new SaleService<Sale>();
