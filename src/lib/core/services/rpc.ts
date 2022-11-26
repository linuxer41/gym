
import { get } from 'svelte/store';
import { settings } from '../settings';
import { authToken } from '../store';

class RpcService {
	base_url = settings.apiUrl;
	fetch = async (call: string, options: RequestInit): Promise<Response> => {
		const headers: typeof options.headers = {
			'Content-Type': 'application/json',
		}
		if (get(authToken)) {
			headers['Authorization'] = `Bearer ${get(authToken)}`;
		}
		return fetch(`${this.base_url}/rpc/${call}`, {
			headers,
			...options,
		});
	};
	login(data: Record<string, unknown>): Promise<Response> {
		return this.fetch(`login`, {
			method: 'POST',
			body: JSON.stringify(data),
		});
	}
	register(data: Partial<User>): Promise<Response> {
		return this.fetch(`register`, {
			method: 'POST',
			body: JSON.stringify(data)
		});
	}
}

export const rpcService = new RpcService();
