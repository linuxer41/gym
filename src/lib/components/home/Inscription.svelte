<script lang="ts">
	import {
		clientService,
		membershipService,
		rpcService,
		subscriberService
	} from '$lib/core/services';
	import { snackBar } from '$lib/core/store';
	import { addDays, format, parseISO } from 'date-fns';
	import { createEventDispatcher, onMount } from 'svelte';
	import { fly } from 'svelte/transition';
	import FormLayer from '../forms/FormLayer.svelte';
	import TextField from '../forms/inputs/TextField.svelte';
	import SubscriberTable from '../tables/SubscriberTable.svelte';
	export let title = 'Formulario';
	export let alreadyExists = false;
	const dispatch = createEventDispatcher();
	let data: Client = {} as any;
	let form: HTMLFormElement;
	let hasSubscription = true;
	let memberships: MembershipJoined[] = [];
	let subscription: Subscription = {
		start_date: format(new Date(), 'yyyy-MM-dd'),	
	} as any;
	let selectedMembership: MembershipJoined = {} as any;
	let keyword = '';
	let subscribers: Subscriber[] = [];
	let referredSubscribers: Subscriber[] = [];
	let checkedClientSubscription: Subscriber = {} as any;
	let first_attendance = true;

	function debounce(func: Function, wait: number, immediate: boolean) {
		let timeout: any;
		return () => {
			// @ts-ignore
			const context = this;
			const args = arguments;
			const later = function () {
				timeout = null;
				if (!immediate) func.apply(context, args);
			};
			const callNow = immediate && !timeout;
			clearTimeout(timeout);
			timeout = setTimeout(later, wait);
			if (callNow) func.apply(context, args);
		};
	}

	$:{
		if((subscription.payment_amount || 0)>=0){
			subscription.balance = Number(selectedMembership?.price) - Number(subscription.payment_amount);
			// check balance negative
			if(subscription.balance<0){
				subscription.balance = 0;
			}
		}
		if((subscription.price || 0)>=0){
			subscription.balance = Number(subscription.price) - Number(subscription.payment_amount);
			// check balance negative
			if(subscription.balance<0){
				subscription.balance = 0;
			}
		}
	}

	// debounce search
	const onDniChange = debounce(
		async () => {
			if (data.dni && data.dni?.length > 2) {
				await checkClient();
			}
		},
		500,
		false
	);

	async function checkClient() {
		try {
			alreadyExists = false;
			if (data.dni) {
				const client = await clientService.get(data.dni, 'dni');
				if (client) {
					data = client;
					alreadyExists = true;
					data?.id && (await loadSubscriber(data.id));
					// snackBar.show({
					// 	message: 'Ya existe un cliente con el mismo DNI: ' + data.dni,
					// 	type: 'info'
					// });
					return client;
				} else {
					alreadyExists = false;
					const dni = data.dni;
					data = {
						dni,
						phone: '',
						email: '',
						name: '',
						address: ''
					} as any;
				}
			}
			return null;
		} catch (error) {
			console.debug(error);
		}
	}

	async function create() {
		try {
			// validate form data
			if (!form.checkValidity()) {
				throw new Error('Formulario invalido o incompleto');
			}
			const to_admit: any = {
				client: data
			};
			const client = await checkClient();
			if (data.dni && !!client) {
				to_admit.client = client;
				// return;
				// throw new Error('Ya existe un cliente con el mismo DNI: ' + data.dni);
			}

			if (selectedMembership && hasSubscription) {
				const now = parseISO(subscription.start_date) || new Date();
				console.debug('now', now);
				const end =
					selectedMembership.duration === 1
						? addDays(now, selectedMembership.duration - 1)
						: addDays(now, selectedMembership.duration);
				subscription.start_date = format(now, 'yyyy-MM-dd');
				subscription.end_date = format(end, 'yyyy-MM-dd');
				// subscription.payment_amount = selectedMembership?.price;
				subscription.price = selectedMembership?.price;
				// subscription.balance = 0;
				subscription.membership_id = selectedMembership?.id;
				to_admit.subscription = subscription;
				to_admit.payment = {
					amount: subscription.payment_amount || 0
				};
				to_admit.first_attendance = first_attendance;
				if (referredSubscribers.length) {
					to_admit.referred_client_ids = referredSubscribers.map((s) => s.id);
				}
			}
			const res = await rpcService.admission(to_admit);
			if (!res.ok) {
				const error = await res.json();
				throw new Error(error.message);
			}
			snackBar.show({
				message: 'Cliente registrado con éxito',
				type: 'success'
			});
			dispatch('close');
		} catch (error: any) {
			console.debug(error);
			snackBar.show({
				message: error.message,
				type: 'error'
			});
		}
	}

	async function loadMemberShip() {
		try {
			memberships = await membershipService.listAllJoined();
			if (memberships.length > 0) {
				selectedMembership = memberships[0];
				subscription.membership_id = selectedMembership.id;
				subscription.price = selectedMembership.price;
			}
		} catch (error) {
			console.debug(error);
		}
	}

	async function searchSubscriber() {
		try {
			subscribers = (
				await subscriberService.query({
					or: [
						{
							field: 'name',
							value: keyword,
							operator: 'ilike'
						},
						{
							field: 'access_code',
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
				})
			).data;
		} catch (error: any) {
			snackBar.show({
				message: error.message,
				type: 'error'
			});
		}
	}
	async function loadSubscriber(id: string) {
		try {
			checkedClientSubscription = await subscriberService.get(id);
		} catch (error: any) {
			console.debug(error);
		}
	}

	function addRefereedSubscriber(subscriber: Subscriber) {
		if (referredSubscribers?.length >= selectedMembership?.clients_limit) {
			snackBar.show({
				message: `Solo se pueden agregar ${selectedMembership?.clients_limit} referidos`,
				type: 'error'
			});
			return;
		}
		const index = referredSubscribers.findIndex((s) => s.id === subscriber.id);
		if (index === -1) {
			referredSubscribers.push(subscriber);
		}
		referredSubscribers = [...referredSubscribers];
	}

	function removeRefereedSubscriber(subscriber: Subscriber) {
		const index = referredSubscribers.findIndex((s) => s.id === subscriber.id);
		if (index !== -1) {
			referredSubscribers.splice(index, 1);
		}
		referredSubscribers = [...referredSubscribers];
	}
	onMount(async () => {
		await loadMemberShip();
	});
</script>

<FormLayer
	{title}
	on:confirm={async () => {
		await create();
	}}
	on:close
>
	<form bind:this={form}>
		<h6 class="text-slate-400 text-sm mt-3 mb-6 font-bold uppercase">Informacion del cliente</h6>
		<div class="flex flex-wrap">
			<TextField label="CI" bind:value={data.dni} required on:input={onDniChange} />
			<TextField label="Nombre" bind:value={data.name} required />
			<TextField label="Teléfono" bind:value={data.phone} placeholder="" />
			<TextField label="Email" bind:value={data.email} placeholder="" />
			<TextField label="Dirección" bind:value={data.address} placeholder="" />
		</div>

		<hr class="mt-6 border-b-1 border-slate-300" />
		{#if alreadyExists && checkedClientSubscription && checkedClientSubscription.has_active_subscription}
			<!-- created a informative card with existe message -->
			<div class="mt-3 mb-6 flex place-content-between items-center">
				<h6 class="text-slate-400 text-sm font-bold uppercase">
					El cliente ya tiene una suscripción activa
				</h6>
				<!-- finish date info -->
			</div>
			<div class="flex items-center">
				<span class="text-slate-400 text-sm">Vence: &nbsp;</span>
				<i class="fas fa-calendar-alt text-slate-400 text-xl mr-2" />
				<span class="text-slate-400 text-sm">
					{checkedClientSubscription?.active_subscription?.end_date}
				</span>
			</div>
		{:else}
			<div class="mt-3 mb-1 flex place-content-between items-center">
				<h6 class="text-slate-400 text-sm font-bold uppercase">Suscripción</h6>
				<i
					class="fas fa-toggle-{hasSubscription ? 'on' : 'off'} text-lime-{hasSubscription
						? '500'
						: '100'} text-2xl"
					on:click={() => (hasSubscription = !hasSubscription)}
					on:keyup={null}
				/>
			</div>
			{#if hasSubscription}
				<div class="mt-3 mb-6 flex place-content-between items-center">
					<h6 class="text-slate-400 text-xs font-bold">Asistencia</h6>
					<i
						class="fas fa-toggle-{first_attendance ? 'on' : 'off'} text-lime-{first_attendance
							? '500'
							: '100'} text-2xl"
						on:click={() => (first_attendance = !first_attendance)}
						on:keyup={null}
					/>
				</div>
				<div class="flex flex-wrap" transition:fly={{ y: 100, duration: 500 }}>
					<div class="w-full lg:w-6/12 px-4">
						<div class="relative w-full mb-3">
							<label class="block uppercase text-slate-600 text-xs font-bold mb-2" for="grid-phone">
								Membresía
							</label>
							<select
								id="grid-prone"
								class="border-0 px-3 py-3 placeholder-slate-300 text-slate-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
								bind:value={subscription.membership_id}
								on:change={(e) => {
									const id = e.currentTarget.value;
									const membership = memberships.find((m) => m.id === id);
									if (membership) {
										selectedMembership = membership;
										subscription.price = membership.price;
									}
								}}
							>
								<option value="">Seleccione una membrecía</option>
								{#each memberships as membership, i}
									<option selected={membership.id === selectedMembership.id} value={membership.id}
										>{membership.name} - {membership.plan?.name}</option
									>
								{/each}
							</select>
						</div>
					</div>

					<TextField label="Fecha de inicio" type="date" bind:value={subscription.start_date} placeholder="" />

					<TextField label="Precio" type="number" bind:value={subscription.price} placeholder="" />
					<TextField label="Monto pagado" type="number" bind:value={subscription.payment_amount} placeholder="" />
					{#if selectedMembership}
						<!-- membership details card -->
						<div class="w-full lg:w-6/12 px-4">
							<div class="relative w-full mb-3">
								<label
									class="block uppercase text-slate-600 text-xs font-bold mb-2"
									for="grid-email"
								>
									Detalles de suscripción
								</label>
								<div class="bg-white shadow rounded-lg overflow-hidden">
									<div class="px-4 py-5 sm:p-6">
										<dl>
											<div class="sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6 sm:py-5">
												<dt class="text-sm font-medium text-slate-500">Deuda</dt>
												<dd class="mt-1 text-sm text-slate-900 sm:mt-0 sm:col-span-2">
													Bs {subscription.balance || 0}
												</dd>
											</div>
											<div class="sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6 sm:py-5">
												<dt class="text-sm font-medium text-slate-500">Plan</dt>
												<dd class="mt-1 text-sm text-slate-900 sm:mt-0 sm:col-span-2">
													{selectedMembership.plan?.name}
												</dd>
											</div>
											<!-- membership name -->
											<div
												class="border-t border-slate-200 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6 sm:py-5"
											>
												<dt class="text-sm font-medium text-slate-500">Membresia</dt>
												<dd class="mt-1 text-sm text-slate-900 sm:mt-0 sm:col-span-2">
													{selectedMembership.name}
												</dd>
											</div>
											<div
												class="border-t border-slate-200 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6 sm:py-5"
											>
												<dt class="text-sm font-medium text-slate-500">Duracion</dt>
												<dd class="mt-1 text-sm text-slate-900 sm:mt-0 sm:col-span-2">
													{selectedMembership.duration} Dias
												</dd>
											</div>
											<div
												class="border-t border-slate-200 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6 sm:py-5"
											>
												<dt class="text-sm font-medium text-slate-500">Precio</dt>
												<dd class="mt-1 text-sm text-slate-900 sm:mt-0 sm:col-span-2">
													{selectedMembership.price}
												</dd>
											</div>
											<div
												class="border-t border-slate-200 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6 sm:py-5"
											>
												<dt class="text-sm font-medium text-slate-500">Descripcion</dt>
												<dd class="mt-1 text-sm text-slate-900 sm:mt-0 sm:col-span-2">
													{selectedMembership.plan?.description}
												</dd>
											</div>
										</dl>
									</div>
								</div>
							</div>
						</div>
						<!-- referred clients -->
						{#if selectedMembership.clients_limit > 1}
							<div class="w-full lg:w-6/12 px-4">
								<div class="relative w-full mb-3">
									<label
										class="block uppercase text-slate-600 text-xs font-bold mb-2"
										for="grid-email"
									>
										Referidos
									</label>
									<div class="bg-white shadow rounded-lg overflow-hidden">
										<div class="flex flex-wrap justify-center space-x-2 items-end px-4 py-5 sm:p-6">
											{#each referredSubscribers || [] as referredSubscriber, i}
												<span
													class="rounded-full text-slate-500 bg-slate-200 font-semibold text-sm flex align-center cursor-pointer active:bg-slate-300 transition duration-300 ease w-max"
												>
													<img
														class="rounded-full w-9 h-9 max-w-none"
														alt="A"
														src="https://mdbootstrap.com/img/Photos/Avatars/avatar-6.jpg"
													/>
													<span class="flex items-center px-3 py-2">
														{referredSubscriber.name}
													</span>
													<button
														on:click|preventDefault={() =>
															removeRefereedSubscriber(referredSubscriber)}
														class="bg-transparent hover focus:outline-none"
													>
														<i class="fas fa-times text-slate-500" />
													</button>
												</span>
											{/each}
										</div>
										<!-- search div -->
										<div class="px-4 py-5 sm:p-6">
											<div class="relative w-full mb-3">
												<input
													id="grid-email"
													type="text"
													class="border-0 px-3 py-3 placeholder-slate-300 text-slate-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
													placeholder="Buscar"
													bind:value={keyword}
													on:input={searchSubscriber}
												/>
											</div>
										</div>
										{#if subscribers?.length > 0}
											<!-- results table -->
											<div class="px-4 py-5 sm:p-6 max-h-80 overflow-auto">
												<SubscriberTable
													data={subscribers}
													on:select={(e) => addRefereedSubscriber(e.detail)}
													title=""
												/>
											</div>
										{/if}
									</div>
								</div>
							</div>
						{/if}
					{/if}
				</div>
			{/if}
		{/if}
	</form>
</FormLayer>
