<script lang="ts">
	import { clientService } from '$lib/core/services';
	import { snackBar } from '$lib/core/store';
	import { createEventDispatcher } from 'svelte';
	import FormLayer from './FormLayer.svelte';
	import TextField from './inputs/TextField.svelte';
	export let title = 'Formulario';
	export let isEdit = false;
	export let data: Partial<Client> = {} as any;
	console.debug({ data });
	const dispatch = createEventDispatcher();
	let form: HTMLFormElement;

	async function create() {
		try {
			// validate form data
			if (!form.checkValidity()) {
				throw new Error('Formulario invalido o incompleto');
			}
			const check = await clientService.get(data.dni || '', 'dni');
			if (!!check) {
				if (isEdit) {
					if (data.id !== check.id) {
						throw new Error('Ya existe un usuario con el mismo dni: ' + data.dni);
					}
				} else {
					throw new Error('Ya existe un usuario con el mismo dni: ' + data.dni);
				}
			}
			const _data = {
				name: data.name,
				dni: data.dni,
				phone: data.phone,
				email: data.email,
				address: data.address
			}
			data = (isEdit && data?.id)?await clientService.update(data.id, _data):await clientService.create(_data);
			snackBar.show({
				message: 'Cliente actualizado con éxito',
				type: 'success'
			});
			dispatch('create', data);
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
		<h6 class="text-slate-400 text-sm mt-3 mb-6 font-bold uppercase">Informacion del cliente</h6>
		<div class="flex flex-wrap">
			<TextField label="Nombre" bind:value={data.name} required />
			<TextField label="Email" bind:value={data.email} placeholder="" type="email" required />
			<TextField label="CI" bind:value={data.dni} />
			<TextField label="Teléfono" bind:value={data.phone} placeholder="" type="tel" />
			<TextField label="Dirección" bind:value={data.address} placeholder="" />
		</div>
	</form>
</FormLayer>
