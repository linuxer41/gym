import { goto } from "$app/navigation";
import { authToken, storeUser } from "$lib/core/store";
import type { Load } from "@sveltejs/kit";
import { get } from "svelte/store";

// export const csr = false;
export const prerender = true;
export const ssr = false;


export const load: Load = async (args) => {
    console.log('logs', args);
    authToken.load();
    storeUser.load();
    if((!get(authToken) || !get(storeUser)) && args.route.id !== '/auth') {
        await goto('/auth');
    }
    return {
        title: 'Page',
    }
}
