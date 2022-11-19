<script>
	// core components
	import CardStats from '$lib/components/Cards/CardStats.svelte';
</script>

<!-- Header -->
<div class="relative bg-stale-800 md:pt-32 pb-32 pt-12">
	<div class="px-4 md:px-10 mx-auto w-full">
		<div>
			<!-- Card stats -->
			<div class="flex flex-wrap">
				<div class="w-full lg:w-6/12 xl:w-3/12 px-4">
					<CardStats
						statSubtitle="TRÁFICO"
						statTitle="350,897"
						statArrow="up"
						statPercent="3.48"
						statPercentColor="text-emerald-500"
						statDescripiron="Desde el mes pasado"
						statIconName="far fa-chart-bar"
						statIconColor="bg-lime-500"
					/>
				</div>
				<div class="w-full lg:w-6/12 xl:w-3/12 px-4">
					<CardStats
						statSubtitle="USUARIOS CLIENTES"
						statTitle="2,356"
						statArrow="down"
						statPercent="3.48"
						statPercentColor="text-red-500"
						statDescripiron="Desde la semana pasada"
						statIconName="fas fa-chart-pie"
						statIconColor="bg-orange-500"
					/>
				</div>
				<div class="w-full lg:w-6/12 xl:w-3/12 px-4">
					<CardStats
						statSubtitle="VENTAS"
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
						statSubtitle="RENDIMIENDO"
						statTitle="49,65%"
						statArrow="up"
						statPercent="12"
						statPercentColor="text-emerald-500"
						statDescripiron="Desde el mes pasado"
						statIconName="fas fa-percent"
						statIconColor="bg-emerald-500"
					/>
				</div>
			</div>
		</div>
	</div>
</div>
