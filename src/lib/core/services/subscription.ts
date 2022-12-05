import { BaseService } from './_base';
export class SubscriptionService<T> extends BaseService<T> {
	location = 'subscriptions';
}
export const subscriptionService = new SubscriptionService<Subscription>();
