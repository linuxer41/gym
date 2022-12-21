<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import { format } from 'date-fns';
	export let data: Subscriber[] = [];
	export let color = 'light';
	export let title = 'Clientes';
	export let selected: Subscriber = null as any;
	const team1 = '../assets/img/team-1-800x800.jpg';
	const dispatch = createEventDispatcher();

	function getTodayStatus(subscriber: Subscriber) {
		let color = 'text-slate-100';
		if (subscriber.has_active_subscription) {
			color = 'text-slate-400';
			let subscription = subscriber.active_subscription;
			// TODAY DATE FNS
			const todayDate = format(new Date(), 'yyyy-MM-dd');

			const attendance = subscription.attendances.find(
				(attendance) => attendance.date === todayDate
			);
			if (attendance) {
				color = 'text-green-500';
			}
			const permission = subscription.permissions.find(
				(permission) => permission.date === todayDate
			);
			console.log({ permission });
			if (permission) {
				color = 'text-yellow-500';
			}
		}

		return color;
	}

	function round(value: number, decimals = 2) {
		// @ts-ignore
		return Number(Math.round(value + 'e' + decimals) + 'e-' + decimals);
	}

	function usedDaysPercentage(subscriber: Subscriber) {
		let percentage = 0;
		if (subscriber.has_active_subscription) {
			let subscription = subscriber.active_subscription;
			percentage = round((subscription.used_days / subscription.total_days) * 100);
		}
		return percentage;
	}

	function handleKeyDown(event: KeyboardEvent) {
		// hancle arrow up and arrow down navigate to selected item
		switch (event.key) {
			case 'ArrowUp':
				event.preventDefault();
				if(!selected) selected = data[0];
				if(selected === data[0]) return;
				selected = data[data.indexOf(selected) - 1];
				break;
			case 'ArrowDown':
				event.preventDefault();
				if(!selected) selected = data[0];
				if(selected === data[data.length - 1]) return;
				selected = data[data.indexOf(selected) + 1];
				break;
		}
		if (event.key === 'Enter') {
			dispatch('select', selected);
		}
		// get data-selected attribute for selected item and scroll to it
		const selectedElement = document.querySelector(`[data-selected="true"]`);
		if (selectedElement) {
			selectedElement.scrollIntoView({
				behavior: 'smooth',
				block: 'nearest',
				inline: 'nearest',
			});
		}
	}

</script>

<div
	class="relative grid grid-rows-[auto_1fr] overflow-hidden break-words w-full custom-box-shadow rounded {color ===
	'light'
		? 'bg-white'
		: 'bg-red-800 text-white'}"
>
	{#if title}
		<div class="rounded-t mb-0 px-4 py-3 border-0">
			<div class="flex flex-wrap items-center">
				<div class="relative w-full px-4 max-w-full flex-grow flex-1">
					<h3 class="font-semibold text-lg {color === 'light' ? 'text-slate-700' : 'text-white'}">
						{title}
					</h3>
				</div>
			</div>
		</div>
	{/if}
	<div class="grid w-full h-full overflow-auto">
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
						Nombre
					</th>
					<th
						class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left {color ===
						'light'
							? 'bg-slate-50 text-slate-500 border-slate-100'
							: 'bg-red-700 text-red-200 border-red-600'}"
					>
						Codigo
					</th>
					<th
						class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left {color ===
						'light'
							? 'bg-slate-50 text-slate-500 border-slate-100'
							: 'bg-red-700 text-red-200 border-red-600'}"
					>
						CI
					</th>
					<th
						class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left {color ===
						'light'
							? 'bg-slate-50 text-slate-500 border-slate-100'
							: 'bg-red-700 text-red-200 border-red-600'}"
					>
						Asistencia
					</th>
					<th
						class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left {color ===
						'light'
							? 'bg-slate-50 text-slate-500 border-slate-100'
							: 'bg-red-700 text-red-200 border-red-600'}"
					>
						Subscripcion
					</th>
					<th
						class="px-6 align-middle border border-solid py-3 text-xs uppercase border-l-0 border-r-0 whitespace-nowrap font-semibold text-left {color ===
						'light'
							? 'bg-slate-50 text-slate-500 border-slate-100'
							: 'bg-red-700 text-red-200 border-red-600'}"
					>
						<i class="fas fa-check text-slate-100 mr-4" />
					</th>
				</tr>
			</thead>
			<tbody>
				{#each data as item}
					<tr
						data-id={item.id}
						on:click={() => {
							selected = item;
							dispatch('select', item);
						}}
						data-selected={selected && selected.id === item.id}
					>
						<th
							class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4 text-left flex items-center"
						>
							<img src={team1} class="h-12 w-12 bg-white rounded-full border" alt="..." />
							<span class="ml-3 font-bold {color === 'light' ? 'btext-slate-600' : 'text-whit'}">
								{item.name}
							</span>
						</th>
						<td
							class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4"
						>
							{item.access_code}
						</td>
						<td
							class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4"
						>
							{item.dni}
						</td>
						<td
							class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4 text-center"
						>
							<i class="fas fa-circle {getTodayStatus(item)} mr-2" />
						</td>
						<td
							class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4"
						>
							{#if item.has_active_subscription}
								<div class="flex items-center">
									<span class="mr-2">{usedDaysPercentage(item)}%</span>
									<div class="relative w-full">
										<div class="overflow-hidden h-2 text-xs flex rounded bg-emerald-200">
											<div
												style="width: {usedDaysPercentage(item)}%;"
												class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-emerald-500"
											/>
										</div>
									</div>
								</div>
							{:else}
								<div class="flex items-center">
									<span class="mr-2">--</span>
									<div class="relative w-full">
										<div class="overflow-hidden h-2 text-xs flex rounded bg-slate-200">
											<div
												style="width: 0%;"
												class="shadow-none flex flex-col text-center whitespace-nowrap text-white justify-center bg-emerald-500"
											/>
										</div>
									</div>
								</div>
							{/if}
						</td>
						<!-- checked indicator -->
						<td
							class="border-t-0 px-6 align-middle border-l-0 border-r-0 text-xs whitespace-nowrap p-4 text-center"
						>
							{#if selected === item}
								<i class="fas fa-check text-emerald-500 mr-4" />
							<!-- {:else}
								<i class="fas fa-times text-red-500 mr-4" /> -->
							{/if}
						</td>
						<!-- <td
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
						</td> -->
					</tr>
				{/each}
			</tbody>
		</table>
	</div>
</div>
<svelte:window on:keydown={handleKeyDown} />

<style>
	.custom-box-shadow {
		box-shadow: rgba(0, 0, 0, 0.24) 0px 3px 8px;
	}
</style>
