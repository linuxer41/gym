<script>
	import CardBarChart from '$lib/components/Cards/CardBarChart.svelte';
	import CardLineChart from '$lib/components/Cards/CardLineChart.svelte';
	import CardPageVisits from '$lib/components/Cards/CardPageVisits.svelte';
	import CardSocialTraffic from '$lib/components/Cards/CardSocialTraffic.svelte';
	import CardStats from '$lib/components/Cards/CardStats.svelte';

	// core components
	import CardTable from '$lib/components/Cards/CardTable.svelte';
</script>

<div class="p-6 overflow-auto h-full w-full">
	<div class="relative md:pt-32 pb-32 pt-12">
		<div class="px-4 md:px-10 mx-auto w-full">
		  <div>
			<!-- Card stats -->
			<div class="flex flex-wrap">
			  <div class="w-full lg:w-6/12 xl:w-3/12 px-4">
				<CardStats
				  statSubtitle="ASISTENCIAS"
				  statTitle="350,897"
				  statArrow="up"
				  statPercent="3.48"
				  statPercentColor="text-emerald-500"
				  statDescripiron="Desde ayer"
				  statIconName="far fa-chart-bar"
				  statIconColor="bg-red-500"
				/>
			  </div>
			  <div class="w-full lg:w-6/12 xl:w-3/12 px-4">
				<CardStats
				  statSubtitle="CLIENTES NUEVOS"
				  statTitle="2,356"
				  statArrow="down"
				  statPercent="3.48"
				  statPercentColor="text-red-500"
				  statDescripiron="Desde ayer"
				  statIconName="fas fa-chart-pie"
				  statIconColor="bg-orange-500"
				/>
			  </div>
			  <div class="w-full lg:w-6/12 xl:w-3/12 px-4">
				<CardStats
				  statSubtitle="Suscripciones"
				  statTitle="924"
				  statArrow="down"
				  statPercent="1.10"
				  statPercentColor="text-orange-500"
				  statDescripiron="Desde ayer"
				  statIconName="fas fa-users"
				  statIconColor="bg-pink-500"
				/>
			  </div>
			  <div class="w-full lg:w-6/12 xl:w-3/12 px-4">
				<CardStats
				  statSubtitle="Ganancia"
				  statTitle="49,65%"
				  statArrow="up"
				  statPercent="12"
				  statPercentColor="text-emerald-500"
				  statDescripiron="Desde ayer"
				  statIconName="fas fa-percent"
				  statIconColor="bg-emerald-500"
				/>
			  </div>
			</div>
		  </div>
		</div>
	  </div>
	<div class="flex flex-wrap">
		<div class="w-full xl:w-8/12 mb-12 xl:mb-0 px-4">
			<CardLineChart />
		</div>
		<div class="w-full xl:w-4/12 px-4">
			<CardBarChart />
		</div>
	</div>
	<div class="flex flex-wrap mt-4">
		<div class="w-full xl:w-8/12 mb-12 xl:mb-0 px-4">
			<CardPageVisits />
		</div>
		<div class="w-full xl:w-4/12 px-4">
			<CardSocialTraffic />
		</div>
	</div>
</div>
