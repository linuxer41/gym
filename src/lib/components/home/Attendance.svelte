<script lang="ts">
	import { rpcService, subscriberService } from '$lib/core/services';
	import { snackBar } from '$lib/core/store';
	import FormLayer from '../forms/FormLayer.svelte';
	import TextField from '../forms/inputs/TextField.svelte';
	import SubscriberTable from '../tables/SubscriberTable.svelte';
	import { format } from 'date-fns';
	import ClientResult from '../profile/ClientResult.svelte';
	import { onMount } from 'svelte';
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
			keyword = '';
			selectedSubscriber = null as any;
			focus()
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
	function focus(){
		const inputs = form?.querySelectorAll('input');
		if (inputs.length > 0) {
			(inputs[0] as HTMLInputElement).focus();
		}
	}
	onMount(() => {
		// get form and focus on first input
		focus()
	});
</script>


<form class="bg-white" bind:this={form}>
	<h1 class="text-2xl font-bold text-center">{title || 'Asistencia'}</h1>
	<div class="flex flex-wrap sticky top-0 bg-white">
		<TextField
			label="CI / DNI"
			bind:value={keyword}
			on:input={searchSubscriber}
			required
			type="search"
		/>
		<div class="w-full lg:w-6/12 px-4">
			<div class="grid place-content-end h-full w-full">
				<!-- button -->
				<button
					type="button"
					class="bg-blue-500 text-white active:bg-blue-600 font-bold uppercase text-sm px-6 py-3 rounded shadow hover:shadow-lg outline-none focus:outline-none mr-1 mb-1 ease-linear transition-all duration-150"
					on:click={submit}
				>
					{#if type === 'attendance'}
						Registrar asistencia
					{:else}
						Registrar permiso
					{/if}
				</button>
			</div>
		</div>
	</div>
	{#if selectedSubscriber}
	<ClientResult subscriber={selectedSubscriber} ></ClientResult>
	{/if}
</form>
<svelte:window on:keydown={e => {
	if (e.key === 'Enter') {
		submit();
	}
}} />
<style>
	form{
		height: 100%;
		margin: 1.5rem;
		width: calc(100% - 3rem);
		height: calc(100% - 3rem);
		overflow: auto;
		border-radius: 1rem;
	}
</style>