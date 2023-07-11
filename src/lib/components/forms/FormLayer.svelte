<script lang="ts">
	import { createEventDispatcher, onMount } from 'svelte';
	import { fade } from 'svelte/transition';

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
	class="overflow-y-auto overflow-x-hidden fixed top-0 right-0 left-0 z-50 p-4 w-full h-full bg-black bg-opacity-25 flex items-center justify-center"
	transition:fade={{ duration: 200 }}
>
	<div class="overflow-auto w-2/3 h-full bg-white rounded-lg shadow-lg flex flex-col">
		<div class="dark_bg sticky top-0 z-10 grid">
			<img class="place-self-center" src="/logos/titlebar-logo.jpg" alt="" height="25" width="175">
			<div
				class="rounded-t mb-0 px-6 py-6  grid grid-cols-[auto_1fr_auto] text-center w-full"
			>
				<!-- close icon -->
				<button on:click={() => dispatch('close')}>
					<i
					class="fas fa-times text-white text-xl font-bold cursor-pointer"/>
				</button>

				<h6 class="text-white text-xl font-bold">{title}</h6>
				<button
					class="bg-slate-600 text-white active:bg-red-500 font-bold uppercase text-xs px-4 py-2 rounded shadow hover:shadow-md outline-none focus:outline-none mr-1 ease-linear transition-all duration-150"
					type="button"
					on:click={() => dispatch('confirm')}
				>
					Confirmar
				</button>
			</div>
		</div>
		<div class="flex-auto p-4 light_bg">
			<slot />
		</div>
	</div>
</div>

<svelte:window on:keydown={handleKeyDown} />
