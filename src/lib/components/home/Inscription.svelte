<script lang="ts">
	import { clientService, membershipService } from "$lib/core/services";
	import { snackBar } from "$lib/core/store";
	import { fly } from "svelte/transition";
	import TextField from "../forms/inputs/TextField.svelte";
	import FormLayer from "../forms/FormLayer.svelte";
	import HomeFormLayer from "../forms/HomeFormLayer.svelte";
	import { onMount } from "svelte";
    export let title = 'Formulario';
    let data: Client = {} as any
    let form: HTMLFormElement
    let hasSuscription = true
    let memberships: MembershipJoined[]= []
    let subscription: Subscription = {} as any
    let selectedMembership: MembershipJoined = {} as any
    let clients = []
    let referedClients = []

    
    async function create() {
        try {
            // validate form data
            if (!form.checkValidity()) {
                throw new Error('Formulario invalido o incompleto')
            }
            if(data.dni && !!await clientService.get(data.dni, 'dni')) {
                throw new Error('Ya existe un cliente con el mismo DNI: ' + data.dni)
            }
            const client = await clientService.create(data)
            console.log({client})
            snackBar.show({
                message: 'Cliente registrado con exito',
                type: 'success'
            })
        } catch (error: any) {
            console.debug(error)
            snackBar.show({
                message: error.message,
                type: 'error'
            })
        }
    }

    async function loadMemberShip() {
        try {
            memberships = await membershipService.listAllJoined()
            if(memberships.length > 0) {
                selectedMembership = memberships[0]
            }
        } catch (error) {
            console.debug(error)
        }
    }

    async function loadClients() {
        try {
            clients = (await clientService.query()).data
        } catch (error) {
            console.debug(error)
        }
    }

    onMount(async () => {
        await loadMemberShip()
    })
</script>
<HomeFormLayer {title} on:confirm={async()=>{
    await create()
}} on:close>
    <form bind:this={form}>
        <h6 class="text-stale-400 text-sm mt-3 mb-6 font-bold uppercase">Informacion del cliente</h6>
        <div class="flex flex-wrap">
            <TextField label="Nombre" bind:value={data.name} required />
            <TextField label="CI" bind:value={data.dni} required />
            <TextField label="Telefono" bind:value={data.phone} placeholder="" />
            <TextField label="Email" bind:value={data.email} placeholder="" />
            <TextField label="Direccion" bind:value={data.address} placeholder="" />
        </div>

        <hr class="mt-6 border-b-1 border-stale-300" />
        <div class="mt-3 mb-6 flex place-content-between items-center">
            <h6 class="text-stale-400 text-sm font-bold uppercase">Suscripcion</h6>
            <i class="fas fa-toggle-{hasSuscription?'on':'off'} text-lime-{hasSuscription?'500':'100'} text-2xl" on:click={()=>hasSuscription=!hasSuscription} on:keyup={null}></i>
        </div>
        {#if hasSuscription}
        <div class="flex flex-wrap" transition:fly={{y:100, duration: 500}}>
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label
                        class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-phone"
                    >
                        Membresia
                    </label>
                    <select
                        id="grid-prone"
                        type="tel"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        bind:value={subscription.membership_id}
                        on:change={(e) => {
                            const id = e.currentTarget.value
                            const membership = memberships.find(m => m.id === id)
                            console.log({membership})
                            if(membership) {
                                selectedMembership = membership
                                subscription.price = membership.price
                            }
                        }}
                    >
                        <option value="">Seleccione una membrecia</option>
                        {#each memberships as membership, i}
                        <option selected={membership.id === selectedMembership.id} value={membership.id}>{membership.name} - {membership.plan?.name}</option>
                        {/each}
                    </select>
                </div>
            </div>
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-email">
                        Precio
                    </label>
                    <input
                        id="grid-email"
                        type="number"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        bind:value={subscription.price}
                    />
                </div>
            </div>
            <!-- membership details card -->
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-email">
                        Detalles
                    </label>
                    <div class="bg-white shadow rounded-lg overflow-hidden">
                        <div class="px-4 py-5 sm:p-6">
                            <dl>
                                <div class="sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6 sm:py-5">
                                    <dt class="text-sm font-medium text-stale-500">
                                        Plan
                                    </dt>
                                    <dd class="mt-1 text-sm text-stale-900 sm:mt-0 sm:col-span-2">
                                        {selectedMembership.plan?.name}
                                    </dd>
                                </div>
                                <div class="border-t border-stale-200 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6 sm:py-5">
                                    <dt class="text-sm font-medium text-stale-500">
                                        Duracion
                                    </dt>
                                    <dd class="mt-1 text-sm text-stale-900 sm:mt-0 sm:col-span-2">
                                        {selectedMembership.duration} Dias
                                    </dd>
                                </div>
                                <div class="border-t border-stale-200 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6 sm:py-5">
                                    <dt class="text-sm font-medium text-stale-500">
                                        Precio
                                    </dt>
                                    <dd class="mt-1 text-sm text-stale-900 sm:mt-0 sm:col-span-2">
                                        {selectedMembership.price}
                                    </dd>
                                </div>
                                <div class="border-t border-stale-200 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6 sm:py-5">
                                    <dt class="text-sm font-medium text-stale-500">
                                        Descripcion
                                    </dt>
                                    <dd class="mt-1 text-sm text-stale-900 sm:mt-0 sm:col-span-2">
                                        {selectedMembership.plan?.description}
                                    </dd>
                                </div>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>
            <!-- refered clients -->
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-email">
                        Referidos
                    </label>
                    <div class="bg-white shadow rounded-lg overflow-hidden">
                        <div class="px-4 py-5 sm:p-6">
                            <dl>
                                <div class="sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6 sm:py-5">
                                    <dt class="text-sm font-medium text-stale-500">
                                        Referidos
                                    </dt>
                                    <dd class="mt-1 text-sm text-stale-900 sm:mt-0 sm:col-span-2">
                                        {selectedMembership.refered_clients}
                                    </dd>
                                </div>
                                <div class="border-t border-stale-200 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6 sm:py-5">
                                    <dt class="text-sm font-medium text-stale-500">
                                        Referidos Gratis
                                    </dt>
                                    <dd class="mt-1 text-sm text-stale-900 sm:mt-0 sm:col-span-2">
                                        {selectedMembership.free_refered_clients}
                                    </dd>
                                </div>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        {/if}
    </form>
</HomeFormLayer>
