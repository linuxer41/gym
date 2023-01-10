<script lang="ts">
	import { rpcService, subscriberService } from '$lib/core/services';
	import { snackBar } from '$lib/core/store';
	import { format } from 'date-fns';
	import { onMount } from 'svelte';
	import TextField from '../forms/inputs/TextField.svelte';
	import ClientResult from '../profile/ClientResult.svelte';
	export let title = 'Formulario';
	export let type: 'attendance' | 'permission' = 'attendance';
	let subscribers: Subscriber[] = [];
	let keyword = '';
	let start_date = format(new Date(), 'yyyy-MM-dd');
	let permissionDays = 1;
	let div: HTMLDivElement;
	let selectedSubscriber: Subscriber | null = null;

	async function submit() {
		try {
			if (!selectedSubscriber) {
				throw new Error('Debe seleccionar un cliente');
			}
			let res: Response;
			if (type === 'attendance') {
				res = await rpcService.attendance({
					client_id: selectedSubscriber.id || ''
				});
			} else {
				res = await rpcService.permission({
					client_id: selectedSubscriber.id || '',
					days: permissionDays,
					start_date: start_date
				});
			}
			if (!res.ok) {
				const error = await res.json();
				throw new Error(error.message);
			}
			await searchSubscriber();
			snackBar.show({
				message:
					type === 'attendance'
						? 'Asistencia registrada con exito'
						: 'Permiso registrado con exito',
				type: 'success'
			});
			keyword = '';
			selectedSubscriber = null as any;
			focus()
		} catch (error: any) {
			console.debug(error);
			snackBar.show({
				message: error.message,
				type: 'error'
			});
		}
	}

	async function searchSubscriber() {
		try {
			selectedSubscriber = null as any;
			subscribers = (
				await subscriberService.query({
					or: [
						{
							field: 'name',
							value: keyword,
							operator: 'eq'
						},
						{
							field: 'access_code',
							value: keyword,
							operator: 'eq'
						},
						{
							field: 'dni',
							value: keyword,
							operator: 'eq'
						}
					],
					pageSize: 10,
					page: 0
				})
			).data;
			if (subscribers.length > 0) {
				selectedSubscriber = subscribers[0];
			}
		} catch (error: any) {
			snackBar.show({
				message: error.message,
				type: 'error'
			});
		}
	}
	function focus(){
		const inputs = div?.querySelectorAll('input');
		if (inputs.length > 0) {
			(inputs[0] as HTMLInputElement).focus();
		}
	}
	const backgrounds = [
		'/wallpapers/1.jpg',
		'/wallpapers/2.jpg',
		'/wallpapers/3.jpg',
		'/wallpapers/4.jpg'
	];
	let background = backgrounds[Math.floor(Math.random() * backgrounds.length)];

	onMount(() => {
		// change background image every 10 seconds

	});
	onMount(() => {
		// get div and focus on first input
		focus()
		const interval = setInterval(() => {
			background = backgrounds[Math.floor(Math.random() * backgrounds.length)];
			const el = document.getElementById('wallpapers');
			if (el) el.style.backgroundImage = `url(${background})`;
		}, 10000);
		return () => {
			clearInterval(interval);
		};
	});
</script>


<div class="form  bg-image bg-cover w-full h-full" id="wallpapers" bind:this={div}>
	<div class="dark_bg sticky top-0 z-10">
		<h1 class="text-2xl font-bold text-center text-white grid  place-content-center content-center">
			<img src="/logos/endorGymLogo.jpg" alt="" height="25" width="175">
			<span>{title}</span>
		</h1>
	</div>
	
	<div class="flex flex-wrap sticky top-0">
		<div class="w-full p-2 text-4xl">
			<!-- decored shadow text label -->
			<label class="block font-medium special-label" for="search">Acceso clientes</label>
			<div class="mt-1  relative rounded-md shadow-sm">
				<div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
					<i class="text-sm fas fa-search"></i>
				</div>
				<input type="text" name="keyword" id="keyword" class="focus:ring-black focus:border-black block text-4xl w-full pl-10 border-gray-300 rounded-md" placeholder="CI / DNI" bind:value={keyword} on:input={searchSubscriber} required>
			</div>
		</div>
	</div>
	{#if selectedSubscriber}
	<div id="content" class="col-span-9 m-3 p-3 overflow-auto light_bg">
		<ClientResult subscriber={selectedSubscriber} fontLarge ></ClientResult>
	</div>
	{/if}
</div>
<svelte:window on:keydown={e => {
	if (e.key === 'Enter') {
		submit();
	}
	if(e.key === 'Escape'){
		keyword = '';
		selectedSubscriber = null;
		focus()
	}
}} />
<style>
	.form{
		height: 100%;
		margin: 0.5rem;
		width: calc(100% - 1rem);
		height: calc(100% - 1rem);
		overflow: auto;
		border-radius: 1rem;
	}
	.bg-image {
		background-image: url('/wallpapers/1.jpg');
		transition: out_image_bg 60000ms linear;
	}
	@keyframes out_image_bg {
		from {
			opacity: 1;
		}
		to {
			opacity: 0;
		}
	}

	.special-label{
		text-shadow: 0 0 0.5rem #000000;
		color: white;
		-webkit-text-stroke: 0.1rem #000000;
	}

</style>