<script lang="ts">
	import DeleteButton from "$lib/components/common/DeleteButton.svelte";
import MembershipFom from "$lib/components/forms/MembershipFom.svelte";
	import PlanForm from "$lib/components/forms/PlanForm.svelte";
import { membershipService, planService } from "$lib/core/services";
	import { onMount } from "svelte";



let plans: Plan[] = []
let memberships: Membership[] = []
let createPlan = false
let createMembership = false
let toEditPlan: Plan | null = null
let toEditMembership: Membership | null = null

async function loadPlans(){
	try {
		const res = await planService.query({
			orderBy: 'name',
		})
		plans = res.data
	} catch (error: any) {
		console.debug(error)
	}
}
// load memberships
async function loadMemberships(){
	try {
		const res = await membershipService.query({
			orderBy: 'name',
		})
		memberships = res.data
	} catch (error: any) {
		console.debug(error)
	}
}
async function deletePlan(id: string){
	try {
		await planService.delete(id)
		await loadPlans()
	} catch (error: any) {
		console.debug(error)
	}
}

async function deleteMembership(id: string){
	try {
		await membershipService.delete(id)
		await loadMemberships()
	} catch (error: any) {
		console.debug(error)
	}
}

onMount(async() => {
	await loadPlans()
	await loadMemberships()
})
</script>

<div class="grid gap-6 p-6 w-full h-full overflow-auto">
	<!-- create plan cards -->
	<div class="w-full h-full rounded bg-white p-3 grid  content-start">
		<div class="grid gap-3 content-start">
			<!-- title -->
			<h1 class="text-xl font-bold text-gray-800">Planes</h1>
			<div class="cards-contaier p-2">
				<!-- iterate plans -->
				{#each plans as plan}
				<div class="w-full rounded shadow-md p-3 grid  content-start">
					<div class="grid gap-3 grid-cols-[1fr_auto]">
						<div class="grid gap-3 place-items-start">
							<h1 class="text-xl whitespace-nowrap font-bold text-gray-800">{plan.name}</h1>
							<p class="text-gray-600">{plan.description}</p>
						</div>
						<div class="grid gap-3 place-items-end">
							<button class="text-blue-500" on:click={() => toEditPlan = plan}>Editar</button>
							<DeleteButton title="Eliminar" on:delete={() => deletePlan(plan.id || '')}/>
						</div>
			
					</div>
				</div>
				{/each}

				<!-- actions -->
				<div class="w-full rounded box-sahdow p-3 grid  content-start">
					<div class="grid gap-3 grid-cols-[1fr_auto]">
						<div class="grid gap-3 place-items-start">
							<h1 class="text-xl whitespace-nowrap font-bold text-gray-800">Crear plan</h1>
						</div>
						<button class="bg-stale-500 place-self end w-min hover:bg-stale-700 text-white font-bold py-2 px-4 rounded" on:click={() => {
							createPlan = true
						}}>
							Crear
						</button>
					</div>
				</div>
			</div>
		</div>
		<hr class="my-3" />
		<div class="grid gap-3 content-start">
			<!-- title -->
			<h1 class="text-xl font-bold text-gray-800">Membresias</h1>
			<div class="cards-contaier">

				{#each memberships as membership}
				<!-- card -->
				<div class="w-full rounded bg-lime-500 p-3 grid  grid-cols-[1fr_auto]">
					<div class="grid gap-1 content-start">
						<!-- title -->
						<h1 class="text-xl font-bold text-white">{membership.name}</h1>
						<!-- price -->
						<p class="text-gray-800"> Bs {membership.price}</p>
						<!-- Plan chip tailwind -->
						<div class="inline-flex w-min whitespace-nowrap items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
							{plans.find(plan => plan.id === membership.plan_id)?.name}
						</div>

					</div>
					<div class="grid gap-1 place-items-end">
						<button class="text-blue-500" on:click={() => toEditMembership = membership}>Editar</button>
						<DeleteButton title="eliminar" on:delete={() => {
							deleteMembership(membership.id || '')
						}}/>
					</div>
				</div>
				{/each}
				<!-- actions -->
				<div class="w-full rounded box-sahdow p-3 grid  content-start">
					<div class="grid gap-3 grid-cols-[1fr_auto]">
						<div class="grid gap-3 place-items-start">
							<h1 class="text-xl whitespace-nowrap font-bold text-gray-800">Nuevo</h1>
						</div>
						<button class="bg-stale-500 place-self end w-min hover:bg-stale-700 text-white font-bold py-2 px-4 rounded" on:click={() => {
							createMembership = true
						}}>
							Crear
						</button>
					</div>
				</div>
			</div>
		</div>
	</div>
</div>

{#if createPlan || toEditPlan}
<PlanForm
	on:close={() => {
		createPlan = false;
		toEditPlan = null;
	}}
	on:create={() => {
		createPlan = false
		loadPlans()
	}}
	on:update={() => {
		toEditPlan = null
		loadPlans()
	}}
	data={toEditPlan || undefined}
	isEdit={toEditPlan !== null}
/>
{/if}

{#if createMembership || toEditMembership}
<MembershipFom
	on:close={() => {
		createMembership = false;
		toEditMembership = null;
	}}
	on:create={() => {
		createMembership = false
		loadMemberships()
	}}
	on:update={() => {
		toEditMembership = null
		loadMemberships()
	}}
	data={toEditMembership || undefined}
	isEdit={toEditMembership !== null}
/>
{/if}
<style>
	.cards-contaier{
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
		grid-gap: 1rem;
		color: white;
	}
</style>
