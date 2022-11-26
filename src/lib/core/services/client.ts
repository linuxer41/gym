import { BaseService } from './_base';
export class ClientService<T> extends BaseService<T> {
	location = 'clients';
}
export const clientService = new ClientService<Client>();
