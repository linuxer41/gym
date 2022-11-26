<script lang="ts">
	// core components
	import TableDropdown from '$lib/components/Dropdowns/TableDropdown.svelte';
	import { USER_ROLES } from '$lib/core/constants';
	import { createEventDispatcher } from 'svelte';
	const team1 = '../assets/img/team-1-800x800.jpg';
    export let data: User[] = [];
	// can be one of light or dark
	export let color = 'light';
	export let title = 'Usuarios';
	const dispatch = createEventDispatcher();
</script>

<div
	class="relative grid grid-rows-[auto_1fr] overflow-hidden break-words w-full shadow-lg rounded {color === 'light'
		? 'bg-white'
		: 'bg-red-800 text-white'}"
>
	<div class="rounded-t mb-0 px-4 py-3 border-0">
		<div class="flex flex-wrap items-center">
			<div class="relative w-full px-4 max-w-full flex-grow flex-1">
				<h3 class="font-semibold text-lg {color === 'light' ? 'text-stale-700' : 'text-white'}">
					{title}
				</h3>
			</div>
		</div>
	</div>
	<div class="grid w-full h-full overflow-auto">
		<!-- Projects table -->
		<table class="items-center w-full bg-transparent border-collapse">
			<thead>
				<tr>
					<th
						class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left {color ===
						'light'
							? 'bg-stale-50 text-stale-500 border-stale-100'
							: 'bg-red-700 text-red-200 border-red-600'}"
					>
						Nombre
					</th>
					<th
						class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left {color ===
						'light'
							? 'bg-stale-50 text-stale-500 border-stale-100'
							: 'bg-red-700 text-red-200 border-red-600'}"
					>
						Correo
					</th>
					<th
						class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left {color ===
						'light'
							? 'bg-stale-50 text-stale-500 border-stale-100'
							: 'bg-red-700 text-red-200 border-red-600'}"
					>
						Cargo
					</th>
                    <th
                    class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left {color ===
                    'light'
                        ? 'bg-stale-50 text-stale-500 border-stale-100'
                        : 'bg-red-700 text-red-200 border-red-600'}"
                />
				</tr>
			</thead>
			<tbody>
                {#each data as user}

				<tr>
					<th
						class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4 text-left flex items-center"
					>
						<img src={team1} class="h-12 w-12 bg-white rounded-full border" alt="..." />
						<span class="ml-3 font-bold {color === 'light' ? 'btext-stale-600' : 'text-whit'}">
							{user.name}
						</span>
					</th>
					<td
						class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4"
					>
						{user.email}
					</td>
					<td
						class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4"
					>
						<i class="fas fa-circle text-{user.role==='api_admin'?'lime':'purple'}-500 mr-2" /> {USER_ROLES[user.role]}
					</td>

					<td
						class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4 text-right"
					>
						<TableDropdown on:delete={
							() => {
								dispatch('delete', user)
							}
						}
						on:edit={
							() => {
								dispatch('edit', user)
							}
						}/>
					</td>
				</tr>
                {/each}
			</tbody>
		</table>
	</div>
</div>
