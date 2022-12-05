<script lang="ts">
	import { rpcService } from '$lib/core/services';
	import { snackBar } from '$lib/core/store';
	import FormLayer from '../forms/FormLayer.svelte';
	import TextField from '../forms/inputs/TextField.svelte';
	export let title = 'Formulario';
	let subscribers: Subscriber[] = [];
	let keyword = '';
	let form: HTMLFormElement;
	let selectedSubscriber: Subscriber | null = null;

	async function create() {
		try {
			// validate form data
			if (!form.checkValidity()) {
				throw new Error('Formulario invalido o incompleto');
			}
			if (!selectedSubscriber) {
				throw new Error('Debe seleccionar un cliente');
			}
			const res = await rpcService.permission({
				client_id: selectedSubscriber.id || '',
				days: 1
			});
			// const client = await clientService.create(data)

			// console.log(client)
			// if(hasSuscription && client?.id) {
			//     const now = new Date()
			//     const end = new Date( now.getFullYear(), now.getMonth(), now.getDate() + selectedMembership?.duration)
			//     subscription.client_id = client.id
			//     subscription.start_date = now.toDateString()
			//     subscription.end_date = end.toDateString()
			//     subscription.payment_amount = selectedMembership?.price
			//     subscription.price = selectedMembership?.price
			//     subscription.balance = 0
			//     await subscriptionService.create(subscription)
			// }
			// console.log({client})
			// snackBar.show({
			//     message: 'Cliente registrado con exito',
			//     type: 'success'
			// })
		} catch (error: any) {
			console.debug(error);
			snackBar.show({
				message: error.message,
				type: 'error'
			});
		}
	}
</script>

<FormLayer
	{title}
	on:confirm={async () => {
		await create();
	}}
	on:close
>
	<form bind:this={form}>
		<h6 class="text-slate-400 text-sm mt-3 mb-6 font-bold uppercase">Cliente</h6>
		<div class="flex flex-wrap">
			<TextField label="Nombre" bind:value={keyword} required type="search" />
		</div>
		<h6 class="text-slate-400 text-sm mt-3 mb-6 font-bold uppercase">Resultados</h6>
		<div class="flex flex-wrap">
			<p>resultados</p>
		</div>
	</form>
</FormLayer>
