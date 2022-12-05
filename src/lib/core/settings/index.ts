/* eslint-disable @typescript-eslint/adjacent-overload-signatures */

export class Settings {
	apiUrl: string;
	constructor(apiUrl: string) {
		this.apiUrl = apiUrl;
	}
}

export const settings = new Settings(import.meta.env.VITE_API_URL || 'http://localhost:801');
