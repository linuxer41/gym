<script lang="ts">
	import ClientTable from "$lib/components/tables/ClientTable.svelte";
	import { clientService } from "$lib/core/services";
	import { onMount } from "svelte";


    let clients: Client[] = []
    let loading = true
    async function load() {
        try {
            const res = await clientService.query()
            clients = res.data
        } catch (error: any) {
            console.debug(error)
        } finally {
            loading = false
        }
    }
    onMount(async() => {
        await load()
    })
</script>
<div class="grid overflow-hidden grid-rows-[auto_1fr] gap-6 p-6 w-full h-full">
    <div>titles</div>
    <ClientTable data={clients} title="usuarios"/>
</div>
