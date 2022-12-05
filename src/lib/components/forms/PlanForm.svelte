<script lang="ts">
	import { rpcService, planService } from '$lib/core/services';
	import { snackBar } from '$lib/core/store';
	import { createEventDispatcher } from 'svelte';
	import { fly } from 'svelte/transition';
	import TextField from './inputs/TextField.svelte';
	import FormLayer from './FormLayer.svelte';
	export let title = 'Formulario';
	export let isEdit = false;
	export let data: Partial<Plan> = {} as any;
	console.debug({ data });
	const dispatch = createEventDispatcher();
	let form: HTMLFormElement;

	async function create() {
		try {
			// validate form data
			if (!form.checkValidity()) {
				throw new Error('Formulario invalido o incompleto');
			}
			if (isEdit) {
				// delete optional pass field to avoid update it
				data = await planService.update(data.id || '', data);
				snackBar.show({
					message: 'Plan actualizado con exito',
					type: 'success'
				});
				dispatch('update', data);
			} else {
				data = await planService.create(data);
				snackBar.show({
					message: 'Plan registrado con exito',
					type: 'success'
				});
				dispatch('create', data);
			}
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
		<h6 class="text-slate-400 text-sm mt-3 mb-6 font-bold uppercase">Informacion del plane</h6>
		<div class="flex flex-wrap">
			<TextField label="Nombre" bind:value={data.name} required />
			<TextField label="Description" bind:value={data.description} placeholder="" />
		</div>
	</form>
</FormLayer>
