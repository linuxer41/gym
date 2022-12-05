<script>
	// library for creating dropdown menu appear on click
	import { createPopper } from '@popperjs/core';
	import { createEventDispatcher } from 'svelte';
	const dispatch = createEventDispatcher();

	// core components

	let dropdownPopoverShow = false;

	let btnDropdownRef;
	let popoverDropdownRef;

	const toggleDropdown = (event) => {
		event.preventDefault();
		if (dropdownPopoverShow) {
			dropdownPopoverShow = false;
		} else {
			dropdownPopoverShow = true;
			createPopper(btnDropdownRef, popoverDropdownRef, {
				placement: 'bottom-start'
			});
		}
	};
</script>

<div class="relative">
	<a
		class="text-slate-500 py-1 px-3"
		href="#pablo"
		bind:this={btnDropdownRef}
		on:click={toggleDropdown}
	>
		<i class="fas fa-ellipsis-v" />
	</a>
	<div
		bind:this={popoverDropdownRef}
		class="bg-white text-base z-50 float-left py-2 list-none text-left rounded shadow-lg min-w-48 {dropdownPopoverShow
			? 'block'
			: 'hidden'}"
	>
		<button
			class="text-sm py-2 px-4 font-normal block w-full whitespace-nowrap bg-transparent text-slate-700"
			on:click={() => {
				dispatch('edit');
				dropdownPopoverShow = false;
			}}
		>
			Editar
		</button>
		<button
			class="text-sm py-2 px-4 font-normal block w-full whitespace-nowrap bg-transparent text-red-700"
			on:click={() => {
				dispatch('delete');
				dropdownPopoverShow = false;
			}}
		>
			Eliminar
		</button>
	</div>
</div>
