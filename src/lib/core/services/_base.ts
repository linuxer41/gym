import { get } from 'svelte/store';
import { authToken } from '../store';
import { settings } from '../settings';
import { create } from "postgrester";

import axios from "axios";

// create a new instance of axios with a custom config
const axiosInstance = axios.create({
	  baseURL: settings.apiUrl,
	  headers: {
		'Content-Type': 'application/json',
		'Accept': 'application/json',
		'Authorization': `Bearer ${get(authToken)}`
	  }
});

const postgrestClient = create({
	axiosInstance
});


export class BaseService<T> {
	base_url = `${settings.apiUrl}`;
	location = '';
	dbClient = postgrestClient;


	// async fetch(last_patch = '', method = 'GET', data?: any): Promise<{
	// 	data: T
	//   }> {
	// 	const token = (get(authToken) as AuthToken)?.access_token;
	// 	return await fetch(`${this.base_url}${this.location ? '/' + this.location : ''}${last_patch}`, {
	// 		headers: {
	// 			'Content-Type': 'application/json',
	// 			Authorization: token ? `Bearer ${token}` : null
	// 		},
	// 		method: method,
	// 		body: data ? JSON.stringify(data) : null
	// 	});
	// }
	getDbClient() {
		const token = (get(authToken) as AuthToken);
		if(token) {
			axiosInstance.defaults.headers.common['Authorization'] = `Bearer ${token}`;
		}
		return this.dbClient;
	}

	async query(opts: QueryDataOpts<T> = {page: 0, pageSize: 1000}): Promise<{
		data: T[];
		pagesLength: number;
		totalLength: number;
	}> {

		let query = this.getDbClient().select("*")
		// is?: { key: keyof T, val: boolean | null }[];
		// eq?: { key: keyof T, val: boolean | number | null | string }[];
		// neq?: { key: keyof T, val: boolean | number | null | string }[];
		// gt?: { key: keyof T, val: number | string }[];
		// gte?: { key: keyof T, val: number | string }[];
		// lt?: { key: keyof T, val: number | string }[];
		// lte?: { key: keyof T, val: number | string }[];
		// in?: { key: keyof T, val: boolean | number | null | string }[];
		// like?: { key: keyof T, val: string }[];
		// ilike?: { key: keyof T, val: string }[];
		// not?: { key: keyof T, val: boolean | number | null | string }[];
		// and?: { key: keyof T, val: boolean | number | null | string }[];
		// or?: { key: keyof T, val: boolean | number | null | string }[];


		if (opts.is) {
			opts.is.forEach((is) => {
				query = query.is(String(is.key), is.val);
			});
		}
		if (opts.eq) {
			opts.eq.forEach((eq) => {
				query = query.eq(String(eq.key), eq.val);
			});
		}
		if (opts.neq) {
			opts.neq.forEach((neq) => {
				query = query.neq(String(neq.key), neq.val);
			});
		}
		if (opts.gt) {
			opts.gt.forEach((gt) => {
				query = query.gt(String(gt.key), gt.val);
			});
		}
		if (opts.gte) {
			opts.gte.forEach((gte) => {
				query = query.gte(String(gte.key), gte.val);
			});
		}
		if (opts.lt) {
			opts.lt.forEach((lt) => {
				query = query.lt(String(lt.key), lt.val);
			});
		}
		if (opts.lte) {
			opts.lte.forEach((lte) => {
				query = query.lte(String(lte.key), lte.val);
			});
		}
		if (opts.in) {
			opts.in.forEach((in_) => {
				query = query.in(String(in_.key), in_.val);
			});
		}
		if (opts.like) {
			opts.like.forEach((like) => {
				query = query.like(String(like.key), like.val);
			});
		}
		if (opts.ilike) {
			opts.ilike.forEach((ilike) => {
				query = query.ilike(String(ilike.key), ilike.val);
			});
		}
		if (opts.not) {
			query = query.not
			opts.not.forEach((not) => {
				query = query.eq(String(not.key), not.val);
			});
		}
		if (opts.and) {
			query = query.and
			opts.and.forEach((and) => {
				query = query.eq(String(and.key), and.val);
			});
		}
		if (opts.or) {
			query = query.or
			opts.or.forEach((or) => {
				query = query.eq(String(or.key), or.val);
			});
		}
		if (opts.orderBy) {
			query = query.orderBy(String(opts.orderBy), opts.oderDir === 'desc' ? true : false);
		}
		if (opts.page) {
			query = query.page(opts.page || 0, opts.pageSize || 1000);
		}
		return await query.get<T>(`/${this.location}`);
	}
	async get(id: string, col: keyof T = 'id' as keyof T): Promise<T> {
		const res = await this.getDbClient().select("*").eq(String(col), id).get<T>(`/${this.location}`, false);
		return res?.data[0];
	}
	async create(data: Partial<T>): Promise<T> {
		const res = await this.getDbClient().post<Partial<T>>(`/${this.location}`, data, {return: 'representation'});
		return res?.data as T;
	}
	async update(id: string, data: Partial<T>): Promise<T> {
		await this.getDbClient().eq('id', id).patch(`/${this.location}`, data);
		return data as T;
	}

	async delete(id: string): Promise<T> {
		const res =  await this.getDbClient().eq('id', id).delete<Partial<T>>(`/${this.location}`, {
			return: 'representation',
		});
		return res?.data[0] as T;
	}
}
