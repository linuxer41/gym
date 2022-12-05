<script lang="ts">
	import { createEventDispatcher, onMount } from 'svelte';

	export let title = 'Formulario';
	const dispatch = createEventDispatcher();
	onMount(() => {
		// get form and set focus on first input
		setTimeout(() => {
			const form = document.querySelector('form');
			if (form) {
				form.focus();
				const input = form.querySelector('input');
				if (input) {
					input.focus();
					console.log(input);
				}
			}
		}, 100);
	});
	function handleKeyDown(event: KeyboardEvent) {
		if (['Enter', 'NumpadEnter'].includes(event.code)) {
			event.preventDefault();
			dispatch('confirm');
		} else if (event.code === 'Escape') {
			event.preventDefault();
			dispatch('close');
		}
	}
</script>

<div
	class="flex flex-col min-w-0 break-words w-full h-full overflow-auto shadow-lg rounded-lg bg-slate-100 border-0"
>
	<div class="rounded-t bg-white mb-0 px-6 py-6 sticky top-0 z-10">
		<div class="text-center flex justify-between">
			<h6 class="text-slate-700 text-xl font-bold">{title}</h6>
			<button
				class="bg-slate-600 text-white active:bg-red-500 font-bold uppercase text-xs px-4 py-2 rounded shadow hover:shadow-md outline-none focus:outline-none mr-1 ease-linear transition-all duration-150"
				type="button"
				on:click={() => dispatch('confirm')}
			>
				Confirmar
			</button>
		</div>
	</div>
	<div class="flex-auto px-4 lg:px-10 py-10 pt-0">
		<slot />
	</div>
</div>

<svelte:window on:keydown={handleKeyDown} />
