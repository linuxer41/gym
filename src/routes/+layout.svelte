<script>
	// import '@brainandbones/skeleton/styles/all.css';
	// import '@brainandbones/skeleton/themes/theme-skeleton.css';
	// import '@brainandbones/skeleton/themes/theme-Modern.css';
	import '../app.css';
	import Admin from '$lib/layouts/Admin.svelte';
	import { page } from '$app/stores';
	import Auth from '$lib/layouts/Auth.svelte';
	$: pathname = $page.url.pathname;
</script>

{#if pathname == '/auth'}
	<Auth>
		<slot />
	</Auth>
{:else}
	<Admin>
		<slot />
	</Admin>
{/if}
<div class="electron-titlebar">

</div>
<style>
    .electron-titlebar{
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        height: 30px;
        background-color: transparent;
        -webkit-app-region: drag;
    }
</style>