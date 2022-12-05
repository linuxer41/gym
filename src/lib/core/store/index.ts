import type { Writable } from 'svelte/store';
import { writable } from 'svelte/store';

interface SyncData {
	progress: number;
	total_items: number;
	current_item: number;
	message: string;
	step: number;
	total_steps: number;
	error: string;
}

interface SyncWritable<T> extends Writable<T> {
	/**
	 * show pso.
	 * @param value to set
	 */
	show(this: void, value: T): void;

	/**
	 * Set value, inform subscribers, and sync whith localstorage.
	 * @param value to set
	 */
	sync(this: void, value: T): void;

	/**
	 * load from localstorage.
	 */
	load(this: void): void;

	/**
	 * flush values from localstorage.
	 */
	flush(this: void): void;

	/**
	 * value for localstorage
	 */
	storageKey: string;
	/**
	 * STORE DEFAULT VALUE TO FLUSH
	 */
	defaultValue: unknown;
}

function syncWritable<T>(init: any, _storageKey: string): SyncWritable<T> {
	const { subscribe, set, update } = writable(init);

	return {
		storageKey: _storageKey,
		defaultValue: init,
		set,
		subscribe,
		update,
		show: (value: T, duration = 5000) => {
			// check typeof value
			if (typeof value === 'string') {
				return update((va) => {
					setTimeout(() => update((val) => (val = init)), duration);
					return (va = value);
				});
			} else if (typeof value === 'object') {
				return update((va) => {
					setTimeout(() => update((val) => (val = init)), duration);
					return (va = value);
				});
			}
		},

		sync: (value: T) =>
			update((va) => {
				if (window) {
					localStorage.setItem(_storageKey, JSON.stringify(value));
				}
				return (va = value);
			}),
		load: () =>
			update((va) => {
				let parsed = init;
				if (window) {
					const _data = localStorage.getItem(_storageKey);
					const _parsed = _data ? JSON.parse(_data) : null;
					if (_parsed !== null && _parsed !== undefined) {
						// ensure no load null values
						parsed = _parsed;
						// console.debug('loading', _storageKey, parsed);
					}
				}
				return (va = parsed);
			}),
		flush: () =>
			update((va) => {
				if (window) {
					localStorage.removeItem(_storageKey);
					console.debug('flushing', _storageKey);
				}
				return (va = init);
			})
	};
}

const authToken = syncWritable<AuthToken>(undefined, 'auth-token');
const storeUser = syncWritable<User>(undefined, 'user-info');

const snackBar = syncWritable<SnackbarMessage>(null, 'snack-bar');
const hasInvoice = syncWritable<boolean>(false, 'has-invoice');
const cashRegister = syncWritable<Record<string, string>>(null, 'cash-register');
const silentPrint = syncWritable<boolean>(false, 'silent-print');
const networkFallback = syncWritable<boolean>(false, 'network-fallback');
const printerName = syncWritable<string>(null, 'printer-name');
const copiesPrint = syncWritable<number>(1, 'printer-copies');

export {
	authToken,
	snackBar,
	storeUser,
	cashRegister,
	hasInvoice,
	silentPrint,
	printerName,
	copiesPrint,
	networkFallback
};
