<script lang="ts">
	import { createEventDispatcher } from 'svelte';

	export let title = 'Eliminar';
	export let message = 'Esta accion no se puede deshacer';
	const dispatch = createEventDispatcher();
</script>

<div
	id="authentication-modal"
	tabindex="-1"
	aria-hidden="true"
	class="overflow-y-auto overflow-x-hidden fixed top-0 right-0 left-0 z-50 p-4 w-full md:inset-0 h-full grid place-content-center bg-black bg-opacity-25"
>
	<div class="relative mx-auto w-80 bg-slate-100 p-6 rounded-lg">
		<h3 class="mb-4 text-xl text-slate-700 font-medium ">{title}</h3>
		<p class="mb-4 text-slate-600 dark:text-slate-400">{message}</p>
		<!-- confirm, cancel buttons -->
		<div class="flex justify-end">
			<button
				type="button"
				class="px-4 py-2 text-sm font-medium leading-5 text-white transition-colors duration-150 bg-red-600 border border-transparent rounded-lg active:bg-red-600 hover:bg-red-700 focus:outline-none focus:shadow-outline-red"
				on:click={() => dispatch('cancel')}
			>
				Cancelar
			</button>
			<button
				type="button"
				class="px-4 py-2 ml-3 text-sm font-medium leading-5 text-white transition-colors duration-150 bg-lime-600 border border-transparent rounded-lg active:bg-green-600 hover:bg-green-700 focus:outline-none focus:shadow-outline-green"
				on:click={() => dispatch('confirm')}
			>
				Confirmar
			</button>
		</div>
	</div>
</div>
