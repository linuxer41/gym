<script lang="ts">
	import Asistance from '$lib/components/home/Asistance.svelte';
	import Inscription from '$lib/components/home/Inscription.svelte';
	import Permission from '$lib/components/home/Permission.svelte';
	import { fly } from 'svelte/transition';

	// core components
	const cards = [
		{
			title: 'Asistencia',
			subtitle: 'Registart asistencia',
			icon: 'fas fa-users',
			iconColor: 'text-orange-500',
			component: Asistance,
			props: {
				title: 'Asistencia',
			},
			shorcut: 'F7',
		},
		{
			title: 'Admisión',
			subtitle: 'Nueva admisione de los cliente',
			icon: 'fas fa-user-plus',
			iconColor: 'text-stale-500',
			component: Inscription,
			props: {
				title: 'Nueva admisión',
			},
			shorcut: 'F8',
		},
		{
			title: 'Permiso',
			subtitle: 'Registrar permisos',
			icon: 'fas fa-user-clock',
			iconColor: 'text-emerald-500',
			component: Permission,
			props: {
				title: 'Registrar permiso',
			},
			shorcut: 'F9',
		}
	];
	let targetCard: typeof cards[number];
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
	$:console.log(panelHeight);
</script>

<div class="grid grid-rows[auto_1fr]  w-full h-screen place overflow-hidden">
	<div class="p-6 grid gap-6 custom-grid-place" bind:clientHeight={panelHeight}>
		<!-- create a 3 cards -->
		{#each cards as card}
			<!-- svelte-ignore a11y-click-events-have-key-events -->
			<div
				class="bg-lime-500 text-white shadow-lg rounded-lg p-6 grid grid-cols-[auto_1fr] gap-4 cursor-pointer"
				on:click={() => targetCard !== card && (targetCard = card)}>
				<div class="grid grid-col-1 content-center items-center">
					<i class="{card.icon} {card.iconColor} text-4xl text-center p-3" />
				</div>
				<div class="flex flex-col gap-2 text-center">
					<span class="text-sm font-bold">{card.subtitle}</span>
					<span class="text-2xl font-bold">{card.title}</span>
					<span class="text-sm text-stale-700 font-bold bg-stale-100 mx-auto px-3 rounded-sm">{card.shorcut}</span>
				</div>

			</div>
		{/each}
	</div>
	{#key targetCard}
		<div class="px-6 w-full overflow-auto rounded-lg" style="height: calc(100vh - {panelHeight + 21}px)" in:fly={{ duration: 1000, y: 100, delay: 0 }}>

			{#if targetCard}
				<svelte:component this={targetCard.component} {...targetCard.props} />
			{/if}
		</div>
	{/key}
</div>
<svelte:window on:keydown={onKeydOWn} />
<style>
	.place{
		place-items: start stretch;
		place-content: start stretch;

	}
	.custom-grid-place{
		display: grid;
		width: 100%;
		
		grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)) !important;
	}

</style>