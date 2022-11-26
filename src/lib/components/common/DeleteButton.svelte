<script lang="ts">
	import { createEventDispatcher } from "svelte";
	import Dialog from "./Dialog.svelte";
    export let title = "Eliminar";
    export let message = "Esta accion no se puede deshacer";
    const dispatch = createEventDispatcher()
    let showConfirm = false
</script>

<button class="px-4 py-2 text-sm font-medium leading-5 text-red-400 transition-colors duration-150  border border-transparent rounded-lg active:bg-red-600 hover:bg-red-700 focus:outline-none focus:shadow-outline-red"
    on:click={() => showConfirm=true}>
    Eliminar
</button>
{#if showConfirm}
    <Dialog title={title} message={message} on:confirm={() => {showConfirm=false;dispatch('delete')}} on:cancel={() => showConfirm=false}/>
{/if}