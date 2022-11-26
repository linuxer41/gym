import { BaseService } from './_base';
export class PaymentService<T> extends BaseService<T> {
	location = 'payments';
}
export const paymentService = new PaymentService<Payment>();
