<script lang="ts">
	import { createEventDispatcher, onMount } from "svelte";
	import { fade } from "svelte/transition";

	
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
	class="overflow-y-auto overflow-x-hidden fixed top-0 right-0 left-0 z-50 p-4 w-full h-full bg-black bg-opacity-75 flex items-center justify-center"
	transition:fade={{ duration: 200 }}
>
	<div class="overflow-auto w-2/3 h-2/3 bg-white rounded-lg shadow-lg flex flex-col">
		<div class="rounded-t bg-white mb-0 px-6 py-6 sticky top-0 z-10 grid grid-cols-[auto_1fr_auto] text-center">
				<!-- close icon -->
				<i class="fas fa-times text-stale-700 text-xl font-bold cursor-pointer" on:click={() => dispatch('close')} />
				<h6 class="text-stale-700 text-xl font-bold">{title}</h6>
				<button
					class="bg-stale-600 text-white active:bg-red-500 font-bold uppercase text-xs px-4 py-2 rounded shadow hover:shadow-md outline-none focus:outline-none mr-1 ease-linear transition-all duration-150"
					type="button"
					on:click={() => dispatch('confirm')}
				>
					Confirmar
				</button>
		</div>
		<div class="flex-auto p-4 bg-stale-100">
			<slot />
		</div>
	</div>
</div>

<svelte:window on:keydown={handleKeyDown} />
