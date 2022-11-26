interface SnackbarMessage {
    message: string;
    type: 'success' | 'error' | 'info' | 'warning';
}
type AuthToken = string;
type queryDataOptItem<T> = {
    col: keyof T;
    val: string;
}
interface QueryDataOpts<T> {
    is?: { key: keyof T, val: boolean | null }[];
    eq?: { key: keyof T, val: boolean | number | null | string }[];
    neq?: { key: keyof T, val: boolean | number | null | string }[];
    gt?: { key: keyof T, val: number | string }[];
    gte?: { key: keyof T, val: number | string }[];
    lt?: { key: keyof T, val: number | string }[];
    lte?: { key: keyof T, val: number | string }[];
    in?: { key: keyof T, val: ( number| string)[] }[];
    like?: { key: keyof T, val: string }[];
    ilike?: { key: keyof T, val: string }[];
    not?: { key: keyof T, val: boolean | number | null | string }[];
    and?: { key: keyof T, val: boolean | number | null | string }[];
    or?: { key: keyof T, val: boolean | number | null | string }[];
    orderBy?: keyof T;
    oderDir?: 'asc' | 'desc';
    page?: number;
    pageSize?: number;
}


type UserRole = 'api_user' | 'api_admin' | 'api_anon';

interface User {
    id?:      string;
    name:    string;
    email:   string;
    pass:    string;
    phone:   string;
    address: string;
    dni:     string;
    role:    UserRole;
}

interface Client {
    id?:         string;
    created_at?: string;
    name:       string;
    phone?:      string;
    address?:    string;
    dni?:        string;
    email?:      string;
}

interface Plan {
    id?:          string;
    name:        string;
    description: string;
}


interface Membership {
    id:       string;
    name:     string;
    price:    number;
    duration: number;
    clients_limit: number;
    plan_id:  string;
}

interface MembershipJoined extends Membership {
    plan: Plan;
}

interface Subscription {
    id?:            string;
    created_at?:    string;
    client_id:      string;
    membership_id:  string;
    start_date:     string;
    end_date:       string;
    is_active:      boolean;
    price:          number;
    payment_amount: number;
    balance:        number;
}



interface Payment {
    id:                   string;
    client_membership_id: string;
    amount:               number;
    created_at:           string;
    date:                 string;
}


interface Expend {
    id:          string;
    created_at:  string;
    user_id:     string;
    amount:      number;
    description: string;
}

interface Income {
    id:          string;
    created_at:  string;
    user_id:     string;
    amount:      number;
    description: string;
}


