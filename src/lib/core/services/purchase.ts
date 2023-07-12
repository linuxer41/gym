import { BaseService } from './_base';
export class PurchaseService<T> extends BaseService<T> {
	location = 'purchases';
}
export const purchaseService = new PurchaseService<Purchase>();
