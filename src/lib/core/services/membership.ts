import { BaseService } from './_base';
export class MembershipService<T> extends BaseService<T> {
	location = 'memberships';
	async listAllJoined(): Promise<MembershipJoined[]> {
		return (await  this.getDbClient().select('*,plan:plans(*)').get<MembershipJoined>(this.location)).data;
	}
}
export const membershipService = new MembershipService<Membership>();
