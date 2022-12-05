<script lang="ts">
	import UserForm from '$lib/components/forms/UserForm.svelte';
	import SubscriberTable from '$lib/components/tables/SubscriberTable.svelte';
	import { subscriberService } from '$lib/core/services';
	import { onMount } from 'svelte';

	let toEdit: Subscriber | null = null;
	let clients: Subscriber[] = [];
	let loading = true;
	async function load() {
		try {
			const res = await subscriberService.query();
			clients = res.data;
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
				/>
			</div>
		</div>
		<!-- <div class="flex items-center justify-end">
            <button on:click={()=>showCreateForm=true} class="flex items-center justify-center w-10 h-10 text-white bg-blue-500 rounded-full">
                <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
            </button>
        </div> -->
	</div>
	<SubscriberTable data={clients} title="" on:edit />
</div>

<style>
	/* .custom-box-shadow {
		box-shadow: rgba(0, 0, 0, 0.24) 0px 3px 8px;
	} */
</style>
