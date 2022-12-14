<script lang="ts">
	import UserForm from '$lib/components/forms/UserForm.svelte';
	import UserTable from '$lib/components/tables/UserTable.svelte';
	import { userService } from '$lib/core/services';
	import { onMount } from 'svelte';

	let users: User[] = [];
	let loading = true;
	let totalCount = 0;
	let showCreateForm = false;
	let toEdit: User | null = null;
	let keyword = '';
	async function load() {
		try {
			const res = await userService.query({
				orderBy: 'name',
				or: [
					{
						field: 'name',
						value: keyword,
						operator: 'ilike'
					},
					{
						field: 'email',
						value: keyword,
						operator: 'ilike'
					},
					{
						field: 'dni',
						value: keyword,
						operator: 'ilike'
					}
				],
				pageSize: 10,
				page: 0
			});
			users = res.data;
			totalCount = res.totalLength;
		} catch (error: any) {
			console.debug(error);
		} finally {
			loading = false;
		}
	}

	onMount(async () => {
		await load();
	});
</script>

<div class="grid overflow-hidden grid-rows-[auto_1fr] gap-3 p-3 pt-8 w-full h-full bg-white">
	<div class="grid grid-cols-2 gap-6 ">
		<div class="flex items-center">
			<!-- search -->
			<div class="relative flex items-center w-full max-w-xl mr-6 focus-within:text-purple-500">
				<div class="absolute inset-y-0 flex items-center pl-2">
					<i class="fas fa-search text-slate-400" />
				</div>
				<input
					type="text"
					class="w-full py-2 pl-8 pr-3 text-slate-900 placeholder-slate-500 bg-slate-100 rounded-lg focus:outline-none focus:placeholder-slate-400 "
					placeholder="Buscar"
					bind:value={keyword}
					on:keyup={async () => {
						await load();
					}}
				/>
			</div>
		</div>
		<div class="flex items-center justify-end">
			<button
				on:click={() => (showCreateForm = true)}
				class="flex items-center justify-center w-10 h-10 text-white bg-blue-500 rounded-full"
			>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					class="w-6 h-6"
					fill="none"
					viewBox="0 0 24 24"
					stroke="currentColor"
				>
					<path
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						d="M12 6v6m0 0v6m0-6h6m-6 0H6"
					/>
				</svg>
			</button>
		</div>
	</div>
	<UserTable
		data={users}
		title="Usuarios"
		on:edit={(e) => {
			toEdit = e.detail;
		}}
	/>
</div>

{#if showCreateForm || toEdit}
	<UserForm
		on:create={async () => {
			showCreateForm = false;
			await load();
		}}
		on:update={async () => {
			toEdit = null;
			await load();
		}}
		on:close={() => {
			showCreateForm = false;
			toEdit = null;
		}}
		isEdit={toEdit ? true : false}
		data={toEdit || undefined}
	/>
{/if}
