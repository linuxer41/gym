<script lang="ts">
	import { productService } from '$lib/core/services';
	import { snackBar } from '$lib/core/store';
	import { createEventDispatcher } from 'svelte';
	import FormLayer from './FormLayer.svelte';
	import TextField from './inputs/TextField.svelte';
	export let isEdit = false;
	export let title = !isEdit? 'Nuevo producto': 'Editar producto';
	export let data: Partial<Product> = {} as any;
	console.debug({ data });
	const dispatch = createEventDispatcher();
	let form: HTMLFormElement;

	async function create() {
		try {
			// validate form data
			if (!form.checkValidity()) {
				throw new Error('Formulario invalido o incompleto');
			}
			const check = await productService.get(data.name || '', 'code');
			if (!!check) {
				if (isEdit) {
					if (data.id !== check.id) {
						throw new Error('Ya existe un usuario con el mismo código: ' + data.code);
					}
				} else {
					throw new Error('Ya existe un usuario con el mismo código: ' + data.code);
				}
			}
			// const res = await rpcService.register(data)
			// if(!res.ok){
			//     throw new Error('Error al registrar usuario')
			// }
			// const product = await res.json()
			if (isEdit) {
				// delete optional pass field to avoid update it
				data = await productService.update(data.id || '', data);
				snackBar.show({
					message: 'Producto actualizado con éxito',
					type: 'success'
				});
				dispatch('update', data);
			} else {
				data = await productService.create(data);
				snackBar.show({
					message: 'Producto registrado con éxito',
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
		<h6 class="text-slate-400 text-sm mt-3 mb-6 font-bold uppercase">Información del producto</h6>
		<div class="flex flex-wrap">
			<TextField label="Código" bind:value={data.code} required />
			<TextField label="Nombre" bind:value={data.name} required />
			<TextField label="Precio" bind:value={data.price} placeholder="" type="number" required />
			<TextField label="Stock" bind:value={data.stock} placeholder="" type="number" required />
		</div>
	</form>
</FormLayer>
