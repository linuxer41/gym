<script lang="ts">
	import { rpcService, membershipService, planService } from "$lib/core/services";
	import { snackBar } from "$lib/core/store";
	import { createEventDispatcher, onMount } from "svelte";
	import { fly } from "svelte/transition";
	import TextField from "./inputs/TextField.svelte";
	import FormLayer from "./FormLayer.svelte";
    export let title = 'Formulario';
    export let isEdit = false;
    export let data: Partial<Membership> = {} as any
        console.debug({data})
    const dispatch = createEventDispatcher()
    let form: HTMLFormElement
    let plans: Plan[] = []

    async function loadPlans(){
        try {
            const res = await planService.query()
            plans = res.data
        } catch (error: any) {
            console.debug(error)
        }
    }
    
    async function create() {
        try {
            // validate form data
            if (!form.checkValidity()) {
                throw new Error('Formulario invalido o incompleto')
            }
            if(isEdit){
                // delete optional pass field to avoid update it
                data = await membershipService.update(data.id || '', data)
                snackBar.show({
                    message: 'Membership actualizado con exito',
                    type: 'success'
                })
                dispatch('update', data)

            }else{
                data = await membershipService.create(data)
                snackBar.show({
                    message: 'Membership registrado con exito',
                    type: 'success'
                })
                dispatch('create', data)
            }
            
        } catch (error: any) {
            console.debug(error)
            snackBar.show({
                message: error.message,
                type: 'error'
            })
        }
    }
    onMount(async() => {
        await loadPlans()
    })
</script>
<FormLayer {title} on:confirm={async()=>{
    await create()
    
}} on:close>
    <form bind:this={form}>
        <h6 class="text-stale-400 text-sm mt-3 mb-6 font-bold uppercase">Informacion del membershipe</h6>
        <div class="flex flex-wrap">
            <TextField label="Nombre" bind:value={data.name} required />
            <TextField label="Precio" bind:value={data.price} placeholder="" type="number"/>
            <TextField label="Duracion" bind:value={data.duration} placeholder="Duracion (Dias)" type="number"/>
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label
                        class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-phone"
                    >
                        Plan
                    </label>
                    <select
                        id="grid-prone"
                        type="tel"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        bind:value={data.plan_id}
                    >
                        <option value="">Seleccione un plan</option>
                        {#each plans as plan}
                            <option value={plan.id}>{plan.name}</option>
                        {/each}
                    </select>
                </div>
            </div>
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label
                        class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-phone"
                    >
                        Personas
                    </label>
                    <select
                        id="grid-prone"
                        type="tel"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        bind:value={data.clients_limit}
                    >
                        <option value="">Seleccione limite de personas</option>
                        <option value="1">1</option>
                        <option value="2">2</option>
                        <option value="3">3</option>
                        <option value="4">4</option>
                        <option value="5">5</option>
                        <option value="6">6</option>
                        <option value="7">7</option>
                        <option value="8">8</option>
                        <option value="9">9</option>
                        <option value="10">10</option>
                    </select>
                </div>
            </div>
        </div>
    </form>
</FormLayer>
