<script lang="ts">
	import Permission from '$lib/components/home/Permission.svelte';
	import Inscription from '$lib/components/home/Inscription.svelte';
	import { fly } from 'svelte/transition';
	import Attendance from '$lib/components/home/Attendance.svelte';
	import Cart from '$lib/components/home/Cart.svelte';

	// core components
	const cards = [

		{
			title: 'Admisión',
			subtitle: 'Admisión de clientes',
			icon: 'fas fa-user-plus',
			iconColor: 'text-slate-500',
			component: Inscription,
			props: {
				title: 'Nueva admisión',
				type: 'inscription'
			} as any,
			shortcut: 'F7'
		},
		{
			title: 'Permiso',
			subtitle: 'Registrar permisos',
			icon: 'fas fa-user-clock',
			iconColor: 'text-emerald-500',
			component: Permission,
			props: {
				title: 'Registrar permiso',
				type: 'permission'
			} as any,
			shortcut: 'F8'
		},
		{
			title: 'Venta',
			subtitle: 'Registrar venta',
			icon: 'fas fa-shopping-cart',
			iconColor: 'text-cyan-500',
			component: Cart,
			props: {
				title: 'Registrar Venta',
				type: 'sale'
			} as any,
			shortcut: 'F9'
		}
	];
	let targetCard: typeof cards[number] | null;
	let panelHeight = 0;
	function onKeydOWn(e: KeyboardEvent) {
		// no repeat
		if (e.repeat) return;

		switch (e.key) {
			case 'F7':
				e.preventDefault();
				targetCard = cards[0];
				break;
			case 'F8':
				e.preventDefault();
				targetCard = cards[1];
				break;
			case 'F9':
				e.preventDefault();
				targetCard = cards[2];
				break;
		}
	}
	$: console.log(panelHeight);
</script>

<div class="grid grid-rows-[auto_1fr] w-full h-screen place overflow-hidden">
	<div class="p-2 grid gap-2 custom-grid-place" bind:clientHeight={panelHeight}>
		<!-- create a 3 cards -->
		{#each cards as card}
			<!-- svelte-ignore a11y-click-events-have-key-events -->
			<div
				class="light_bg text-white shadow-lg rounded-lg p-6 grid grid-cols-[auto_1fr] gap-4 cursor-pointer"
				on:click={() => targetCard !== card && (targetCard = card)}
			>
				<div class="grid grid-col-1 content-center items-center">
					<i class="{card.icon} {card.iconColor} text-4xl text-center p-3" />
				</div>
				<div class="flex flex-col gap-2 text-center">
					<span class="text-sm font-bold">{card.subtitle}</span>
					<span class="text-2xl font-bold">{card.title}</span>
					<span class="text-sm text-slate-700 font-bold bg-slate-100 mx-auto px-3 rounded-sm"
						>{card.shortcut}</span
					>
				</div>
			</div>
		{/each}
	</div>
	<Attendance title="Asistencia" type="attendance" />
	{#key targetCard}
		{#if targetCard}
			<svelte:component
				this={targetCard.component}
				{...targetCard.props}
				on:close={() => (targetCard = null)}
			/>
		{/if}
	{/key}
</div>
<svelte:window on:keydown={onKeydOWn} />

<style>
	.place {
		place-items: start stretch;
		place-content: start stretch;
	}
	.custom-grid-place {
		display: grid;
		width: 100%;

		grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)) !important;
	}
</style>
