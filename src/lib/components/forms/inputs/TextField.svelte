<script lang="ts">
	import { createEventDispatcher } from 'svelte';

	export let value: number | string = '';
	export let label = '';
	export let placeholder = '';
	export let type: 'text' | 'email' | 'password' | 'tel' | 'number' | 'search' | 'date' = 'text';
	export let required = false;
	const dispatch = createEventDispatcher();
</script>

<div class="w-full lg:w-6/12 px-4">
	<div class="relative w-full mb-3">
		<label class="block uppercase text-slate-600 text-xs font-bold mb-2" for="grid-phone">
			{label}
			{#if required}
				<span>
					<i class="fas fa-asterisk text-red-500 text-xs" />
				</span>
			{/if}
		</label>
		<input
			id="grid-prone"
			{type}
			{placeholder}
			{value}
			{required}
			class="border-0 px-3 py-3 placeholder-slate-300 text-slate-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
			on:input={(e) => {
				value = e.currentTarget.value;
				dispatch('input', value);
			}}
			step={type === 'number'? 0.01 : undefined}
		/>
	</div>
</div>
