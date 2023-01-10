<script lang="ts">
	import { rpcService, subscriberService } from '$lib/core/services';
	import { snackBar } from '$lib/core/store';
	import FormLayer from '../forms/FormLayer.svelte';
	import TextField from '../forms/inputs/TextField.svelte';
	import SubscriberTable from '../tables/SubscriberTable.svelte';
	import { format } from 'date-fns';
	import ClientProfile from '../profile/ClientResult.svelte';
	export let title = 'Formulario';
	export let type: 'attendance' | 'permission' = 'attendance';
	let subscribers: Subscriber[] = [];
	let keyword = '';
	let start_date = format(new Date(), 'yyyy-MM-dd');
	let permissionDays = 1;
	let form: HTMLFormElement;
	let selectedSubscriber: Subscriber;

	async function submit() {
		try {
			if (!selectedSubscriber) {
				throw new Error('Debe seleccionar un cliente');
			}
			let res: Response;
			if (type === 'attendance') {
				res = await rpcService.attendance({
					client_id: selectedSubscriber.id || ''
				});
			} else {
				res = await rpcService.permission({
					client_id: selectedSubscriber.id || '',
					days: permissionDays,
					start_date: start_date
				});
			}
			if (!res.ok) {
				const error = await res.json();
				throw new Error(error.message);
			}
			await searchSubscriber();
			snackBar.show({
				message:
					type === 'attendance'
						? 'Asistencia registrada con exito'
						: 'Permiso registrado con exito',
				type: 'success'
			});
		} catch (error: any) {
			console.debug(error);
			snackBar.show({
				message: error.message,
				type: 'error'
			});
		}
	}

	async function searchSubscriber() {
		try {
			selectedSubscriber = null as any;
			subscribers = (
				await subscriberService.query({
					or: [
						{
							field: 'name',
							value: keyword,
							operator: 'eq'
						},
						{
							field: 'access_code',
							value: keyword,
							operator: 'eq'
						},
						{
							field: 'dni',
							value: keyword,
							operator: 'eq'
						}
					],
					pageSize: 10,
					page: 0
				})
			).data;
			if (subscribers.length > 0) {
				selectedSubscriber = subscribers[0];
			}
		} catch (error: any) {
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
		await submit();
	}}
	on:close
>
	<form bind:this={form}>
		<div class="flex flex-wrap">
			<TextField
				label="CI / DNI"
				bind:value={keyword}
				on:input={searchSubscriber}
				required
				type="search"
			/>
			{#if type === 'permission'}
				<TextField label="Dias" bind:value={permissionDays} required type="number" />
				<TextField label="Fecha de inicio" bind:value={start_date} required type="date" />
			{/if}
		</div>
		{#if selectedSubscriber}
		<ClientProfile subscriber={selectedSubscriber} fontLarge ></ClientProfile>
		{/if}
	</form>
</FormLayer>
