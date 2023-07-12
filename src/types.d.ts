interface SnackbarMessage {
	message: string;
	type: 'success' | 'error' | 'info' | 'warning';
}
type AuthToken = string;
type queryDataOptItem<T> = {
	col: keyof T;
	val: string;
};
interface QueryDataOpts<T> {
	is?: { field: keyof T; value: boolean | null }[];
	eq?: { field: keyof T; value: boolean | number | null | string }[];
	neq?: { field: keyof T; value: boolean | number | null | string }[];
	gt?: { field: keyof T; value: number | string }[];
	gte?: { field: keyof T; value: number | string }[];
	lt?: { field: keyof T; value: number | string }[];
	lte?: { field: keyof T; value: number | string }[];
	in?: { field: keyof T; value: (number | string)[] }[];
	like?: { field: keyof T; value: string }[];
	ilike?: { field: keyof T; value: string }[];
	not?: { field: keyof T; value: boolean | number | null | string }[];
	and?: { field: keyof T; value: boolean | number | null | string; operator: 'ilike' | 'eq' }[];
	or?: { field: keyof T; value: boolean | number | null | string; operator: 'ilike' | 'eq' }[];
	orderBy?: keyof T;
	oderDir?: 'asc' | 'desc';
	page?: number;
	pageSize?: number;
}

type UserRole = 'api_user' | 'api_admin' | 'api_anon';

interface User {
	id?: string;
	name: string;
	email: string;
	pass: string;
	phone: string;
	address: string;
	dni: string;
	role: UserRole;
}

interface Client {
	id?: string;
	created_at?: string;
	name: string;
	phone?: string;
	address?: string;
	dni?: string;
	email?: string;
	access_code?: string;
}

interface Plan {
	id?: string;
	name: string;
	description: string;
}

interface Membership {
	id: string;
	name: string;
	price: number;
	duration: number;
	clients_limit: number;
	plan_id: string;
}

interface MembershipJoined extends Membership {
	plan: Plan;
}

interface Subscription {
	id?: string;
	created_at?: string;
	client_id: string;
	membership_id: string;
	start_date: string;
	end_date: string;
	is_active: boolean;
	price: number;
	payment_amount: number;
	balance: number;
	referred_subscription_id?: string;
}

interface Attendance {
	id: string;
	created_at: string;
	subscription_id: string;
	date: string;
	start_time: string;
	end_time: string;
}

interface Permission {
	id: string;
	created_at: string;
	subscription_id: string;
	date: string;
}

interface Payment {
	id: string;
	client_membership_id: string;
	amount: number;
	created_at: string;
	date: string;
}

interface Expend {
	id: string;
	created_at: string;
	user_id: string;
	amount: number;
	description: string;
}

interface Income {
	id: string;
	created_at: string;
	user_id: string;
	amount: number;
	description: string;
}

interface Product {
	id: string;
	code: string;
	name: string;
	price: number;
	stock: number;
	image: string;
}

interface Sale {
	id: string;
	created_at: string;
	user_id: string;
	total: number;
	client_id: string;
	items: any[];
	status_id: number;
}

interface Purchase {
	id: string;
	created_at: string;
	user_id: string;
	total: number;
	client_id: string;
	items: any[];
	status_id: number;
}


interface CartItems extends Product {
	quantity: number;
	discount: number;
}
interface Cart {
	id: string;
	client?: Client | null;
	items: CartItems[];
	cart_type: 'sale' | 'purchase';

}

interface ClientSubscription extends Subscription {
	membership: Membership;
	plan: Plan;
	payments: Payment[];
	payments_count: number;
	total_paid: number;
	attendances: Attendance[];
	attendances_count: number;
	left_days: number;
	used_days: number;
	total_days: number;
	permissions: Permission[];
	permissions_count: number;
	expired: boolean;
}

interface Subscriber extends Client {
	has_active_subscription: boolean;
	has_subscriptions: boolean;
	client_id: string;
	subscriptions: ClientSubscription[];
	subscriptions_count: number;
	balance: number;
	payment_amount: number;
	price: number;
	debt: number;
	in_debt: boolean;
	active_subscription: ClientSubscription;
}
