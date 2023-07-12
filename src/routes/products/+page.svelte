<script lang="ts">
	import ProductForm from '$lib/components/forms/ProductForm.svelte';
	import Cart from '$lib/components/home/Cart.svelte';
	import ProductTable from '$lib/components/tables/ProductTable.svelte';
	import { productService } from '$lib/core/services';
	import { onMount } from 'svelte';

	let data: Product[] = [];
	let loading = true;
	let totalCount = 0;
	let showCreateForm = false;
	let showCart = false;
	let toEdit: Product | null = null;
	let keyword = '';
	async function load() {
		try {
			const res = await productService.query({
				orderBy: 'name',
				or: [
					{
						field: 'name',
						value: keyword,
						operator: 'ilike'
					},
				],
				pageSize: 10,
				page: 0
			});
			data = res.data;
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
		<div class="flex items-center justify-end gap-2">
			<button
				on:click={() => (showCreateForm = true)}
				class="flex items-center justify-center w-10 h-10 text-white bg-blue-500 rounded-full"
			>
				<i class="fas fa-plus" />
			</button>
			<button
				on:click={() => (showCart = true)}
				class="flex items-center justify-center w-10 h-10 text-white bg-blue-500 rounded-full"
			>
				<i class="fas fa-shopping-cart" />
			</button>
		</div>
	</div>
	<ProductTable
		data={data}
		title="Usuarios"
		on:edit={(e) => {
			toEdit = e.detail;
		}}
	/>
</div>

{#if showCreateForm || toEdit}
	<ProductForm
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

{#if showCart}
<Cart
	on:close={() => {
		showCart = false;
	}}
	type='purchase'
	/>
{/if}
