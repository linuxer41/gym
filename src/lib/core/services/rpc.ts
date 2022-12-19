import { get } from 'svelte/store';
import { settings } from '../settings';
import { authToken } from '../store';

class RpcService {
	base_url = settings.apiUrl;
	fetch = async (call: string, options: RequestInit): Promise<Response> => {
		const headers: typeof options.headers = {
			'Content-Type': 'application/json'
		};
		if (get(authToken)) {
			headers['Authorization'] = `Bearer ${get(authToken)}`;
		}
		return fetch(`${this.base_url}/rpc/${call}`, {
			headers,
			...options
		});
	};
	login(data: Record<string, unknown>): Promise<Response> {
		return this.fetch(`login`, {
			method: 'POST',
			body: JSON.stringify(data)
		});
	}
	register(data: Partial<User>): Promise<Response> {
		return this.fetch(`register`, {
			method: 'POST',
			body: JSON.stringify(data)
		});
	}
	admission(data: {
		client: Partial<Client>;
		subscription: Partial<Subscription>;
		payment: Partial<Payment>;
	}): Promise<Response> {
		return this.fetch(`new_admission`, {
			method: 'POST',
			body: JSON.stringify({
				admission: data
			})
		});
	}
	attendance(data: { client_id: string }): Promise<Response> {
		return this.fetch(`new_attendance`, {
			method: 'POST',
			body: JSON.stringify(data)
		});
	}

	permission(data: { client_id: string; days: number; start_date: string }): Promise<Response> {
		return this.fetch(`new_permission`, {
			method: 'POST',
			body: JSON.stringify(data)
		});
	}
	statistics(data: { start_date: string; end_date: string }): Promise<Response> {
		return this.fetch(`resume`, {
			method: 'POST',
			body: JSON.stringify(data)
		});
	}
}

export const rpcService = new RpcService();
