<script lang="ts">
	import { rpcService, subscriptionService } from '$lib/core/services';
	import { snackBar } from '$lib/core/store';
	import { createEventDispatcher, onMount } from 'svelte';
	import ModalLayer from './ModalLayer.svelte';
	export let title = 'Formulario';
	export let data: Partial<Client> = {} as any;
	console.debug({ data });
	const dispatch = createEventDispatcher();
    let subscriptions: Subscription[] = [];

    async function loadSubscriptions() {
        try {
            if(!data.id) return;
            const req = await subscriptionService.query({
                eq:[{ field: 'client_id', value: data.id }],
                gt: [{ field: 'balance', value: 0 }],
            });
            subscriptions = req.data;
        } catch (error: any) {
            console.debug(error);
            snackBar.show({
                message: error.message,
                type: 'error'
            });
        }
    }
    onMount(async () => {
        await loadSubscriptions();
    });

	async function payment(subscription: Subscription) {
		try {
			// validate form data
            if(!subscription.id) {
                throw new Error('No se ha seleccionado una suscripción');
            }
			if (!subscription.balance) {
                throw new Error('El monto no puede ser 0');
            }
            if (subscription.balance > subscription.price) {
                throw new Error('El monto no puede ser mayor al saldo');
            }
            if (subscription.balance < 0) {
                throw new Error('El monto no puede ser menor a 0');
            }
            const req = await rpcService.payment({
                subscription_id: subscription.id,
                amount: subscription.balance,
            });
            snackBar.show({
                message: 'Pago realizado',
                type: 'success'
            });
            await loadSubscriptions();
            dispatch('payment');
            dispatch('close');
            
        } catch (error: any) {
            console.debug(error);
            snackBar.show({
                message: error.message,
                type: 'error'
            });
        }

	}
</script>

<ModalLayer
	{title}
	on:close
>
	<div>
        <div class="overflow-x-auto">
            <table class="min-w-full" >
                <thead>
                    <tr class="bg-gray-50 border-b border-gray-200 text-left text-xs leading-4 font-medium text-gray-500 uppercase tracking-wider">
                        <th class="px-6 py-3">Detalle</th>
                        <th class="px-6 py-3">Fecha de deuda</th>
                        <th class="px-6 py-3">Fecha de limite</th>
                        <th class="px-6 py-3">Monto</th>
                        <!-- <th class="px-6 py-3">Saldo</th> -->
                        <!-- action pay -->
                        <th class="px-6 py-3">Acciones</th>
                    </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                    {#each subscriptions as subscription}
                        <tr class="text-sm leading-5 text-gray-500">
                            <td class="px-6 py-4 whitespace-no-wrap">
                                Deuda por suscripción
                            </td>
                            <td class="px-6 py-4 whitespace-no-wrap">
                                {subscription.start_date}
                            </td>
                            <td class="px-6 py-4 whitespace-no-wrap">
                                {subscription.end_date}
                            </td>
                            <td class="px-6 py-4 whitespace-no-wrap">
                                {subscription.balance}
                            </td>
                            <td class="px-6 py-4 whitespace-no-wrap">
                                <button class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded" on:click={()=>payment(subscription)}>
                                    Pagar
                                </button>
                            </td>
                        </tr>
                    {/each}
                </tbody>
            </table>
        </div>
</ModalLayer>
