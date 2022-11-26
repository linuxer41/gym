<script lang="ts">
	// core components
	import TableDropdown from '$lib/components/Dropdowns/TableDropdown.svelte';

	const bootstrap = '../assets/img/bootstrap.jpg';
	const angular = '../assets/img/angular.jpg';
	const sketch = '../assets/img/sketch.jpg';
	const react = '../assets/img/react.jpg';
	const vue = '../assets/img/react.jpg';

	const team1 = '../assets/img/team-1-800x800.jpg';
	const team2 = '../assets/img/team-2-800x800.jpg';
	const team3 = '../assets/img/team-3-800x800.jpg';
	const team4 = '../assets/img/team-4-470x470.png';
    export let title = 'Usuarios';
    export let data: Client[] = [];

	// can be one of light or dark
	export let color = 'light';
</script>

<div
	class="relative flex flex-col min-w-0 break-words w-full shadow-lg rounded {color === 'light'
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
	<div class="block w-full overflow-x-auto">
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
						Celular
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
						<i class="fas fa-circle text-orange-500 mr-2" /> {user.phone}
					</td>

					<td
						class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4 text-right"
					>
						<TableDropdown />
					</td>
				</tr>
                {/each}
			</tbody>
		</table>
	</div>
</div>
