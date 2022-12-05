<script>
	// import '@brainandbones/skeleton/styles/all.css';
	// import '@brainandbones/skeleton/themes/theme-skeleton.css';
	// import '@brainandbones/skeleton/themes/theme-Modern.css';
	import '../app.css';
	import Admin from '$lib/layouts/Admin.svelte';
	import { page } from '$app/stores';
	import Auth from '$lib/layouts/Auth.svelte';
	import { snackBar } from '$lib/core/store';
	import { fade, fly } from 'svelte/transition';
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
<div class="electron-titlebar" />
{#if $snackBar}
	<div
		in:fly={{ y: 200, duration: 2000 }}
		out:fade={{ delay: 10, duration: 2000 }}
		id="snackbar"
		class="snackbar show"
		class:success={$snackBar.type == 'success'}
		class:error={$snackBar.type == 'error'}
		class:warning={$snackBar.type == 'warning'}
		class:info={$snackBar.type == 'info'}
	>
		{#if typeof $snackBar === 'object'}
			<p>
				{$snackBar.message}
			</p>
		{/if}
	</div>
{/if}

<style lang="scss">
	.electron-titlebar {
		position: fixed;
		top: 0;
		left: 0;
		right: 0;
		height: 30px;
		background-color: transparent;
		-webkit-app-region: drag;
	}
	.snackbar {
		display: none;
		position: fixed;
		left: 50%;
		transform: translateX(-50%);
		z-index: 129;
		bottom: 30px;
		p {
			text-align: center;
			// font-size: 0.8rem;
			background-color: #333;
			color: #fff;
			border-radius: 6px;
			padding: var(--spacing-normal);
		}
	}

	.show {
		display: flex !important;
	}
	.info {
		p {
			background-color: var(--info-color);
		}
	}
	.success {
		p {
			background-color: var(--success-color);
		}
	}
	.error {
		p {
			background-color: var(--error-color);
		}
	}
	.warning {
		p {
			background-color: var(--warning-color);
		}
	}
</style>
