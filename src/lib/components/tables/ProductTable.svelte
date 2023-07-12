<script lang="ts">
	// core components
	import TableDropdown from '$lib/components/Dropdowns/TableDropdown.svelte';
	import { createEventDispatcher } from 'svelte';
	const team1 = '../assets/img/team-1-800x800.jpg';
	export let data: Product[] = [];
	// can be one of light or dark
	export let color = 'light';
	export let title = 'Usuarios';
	const dispatch = createEventDispatcher();
</script>

<div
	class="relative grid grid-rows-[auto_1fr] overflow-hidden break-words w-full custom-box-shadow rounded {color ===
	'light'
		? 'bg-white'
		: 'bg-red-800 text-white'}"
>
	<div class="rounded-t mb-0 px-4 py-3 border-0">
		<div class="flex flex-wrap items-center">
			<div class="relative w-full px-4 max-w-full flex-grow flex-1">
				<h3 class="font-semibold text-lg {color === 'light' ? 'text-slate-700' : 'text-white'}">
					{title}
				</h3>
			</div>
		</div>
	</div>
	<div class="grid w-full h-full overflow-auto content-start">
		<!-- Projects table -->
		<table class="items-center w-full bg-transparent border-collapse">
			<thead>
				<tr>
					<th
						class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left {color ===
						'light'
							? 'bg-slate-50 text-slate-500 border-slate-100'
							: 'bg-red-700 text-red-200 border-red-600'}"
					>
						Código
					</th>
					<th
						class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left {color ===
						'light'
							? 'bg-slate-50 text-slate-500 border-slate-100'
							: 'bg-red-700 text-red-200 border-red-600'}"
					>
						Nombre
					</th>
					<th
						class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left {color ===
						'light'
							? 'bg-slate-50 text-slate-500 border-slate-100'
							: 'bg-red-700 text-red-200 border-red-600'}"
					>
						Stock
					</th>
					<th
						class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left {color ===
						'light'
							? 'bg-slate-50 text-slate-500 border-slate-100'
							: 'bg-red-700 text-red-200 border-red-600'}"
					/>
				</tr>
			</thead>
			<tbody>
				{#each data as item}
					<tr>
						<td
							class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4"
						>
							{item.code}
						</td>
						<td
							class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4"
						>
							{item.name}
						</td>
						<td
							class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4"
						>
							{item.stock}
						</td>
						<td
							class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4 text-right"
						>
							<TableDropdown
								on:delete={() => {
									dispatch('delete', item);
								}}
								on:edit={() => {
									dispatch('edit', item);
								}}
							/>
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>
</div>

<style>
	.custom-box-shadow {
		box-shadow: rgba(0, 0, 0, 0.24) 0px 3px 8px;
	}
</style>
