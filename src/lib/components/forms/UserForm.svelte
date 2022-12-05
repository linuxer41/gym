<script lang="ts">
	import { rpcService, userService } from '$lib/core/services';
	import { snackBar } from '$lib/core/store';
	import { createEventDispatcher } from 'svelte';
	import { fly } from 'svelte/transition';
	import TextField from '../forms/inputs/TextField.svelte';
	import FormLayer from './FormLayer.svelte';
	export let title = 'Formulario';
	export let isEdit = false;
	export let data: Partial<User> = {} as any;
	console.debug({ data });
	const dispatch = createEventDispatcher();
	let form: HTMLFormElement;

	async function create() {
		try {
			// validate form data
			if (!form.checkValidity()) {
				throw new Error('Formulario invalido o incompleto');
			}
			const check = await userService.get(data.email || '', 'email');
			if (!!check) {
				if (isEdit) {
					if (data.id !== check.id) {
						throw new Error('Ya existe un usuario con el mismo email: ' + data.email);
					}
				} else {
					throw new Error('Ya existe un usuario con el mismo email: ' + data.email);
				}
			}
			// const res = await rpcService.register(data)
			// if(!res.ok){
			//     throw new Error('Error al registrar usuario')
			// }
			// const user = await res.json()
			if (isEdit) {
				// delete optional pass field to avoid update it
				delete data.pass;
				data = await userService.update(data.id || '', data);
				snackBar.show({
					message: 'Usuario actualizado con exito',
					type: 'success'
				});
				dispatch('update', data);
			} else {
				data = await userService.create(data);
				snackBar.show({
					message: 'Usuario registrado con exito',
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
		<h6 class="text-slate-400 text-sm mt-3 mb-6 font-bold uppercase">Informacion del usere</h6>
		<div class="flex flex-wrap">
			<TextField label="Nombre" bind:value={data.name} required />
			<TextField label="Email" bind:value={data.email} placeholder="" type="email" required />
			{#if !isEdit}
				<TextField
					label="Contraseña"
					bind:value={data.pass}
					placeholder=""
					type="password"
					required
				/>
			{/if}
			<TextField label="CI" bind:value={data.dni} />
			<TextField label="Telefono" bind:value={data.phone} placeholder="" type="tel" />
			<TextField label="Direccion" bind:value={data.address} placeholder="" />
			<div class="w-full lg:w-6/12 px-4">
				<div class="relative w-full mb-3">
					<label class="block uppercase text-slate-600 text-xs font-bold mb-2" for="grid-phone">
						Rol
					</label>
					<select
						id="grid-prone"
						type="tel"
						class="border-0 px-3 py-3 placeholder-slate-300 text-slate-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
						bind:value={data.role}
					>
						<option value="api_admin" selected>Administrador</option>
						<option value="api_user">Usuario</option>
					</select>
				</div>
			</div>
		</div>
	</form>
</FormLayer>
