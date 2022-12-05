import { BaseService } from './_base';
export class SubscriberService<T> extends BaseService<T> {
	location = 'subscribers';
}
export const subscriberService = new SubscriberService<Subscriber>();
