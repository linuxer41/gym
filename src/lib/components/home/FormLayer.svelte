<script>
	export let title = 'Formulario';
</script>
<div
	class="flex flex-col min-w-0 break-words w-full shadow-lg rounded-lg bg-stale-100 border-0"
>
	<div class="rounded-t bg-white mb-0 px-6 py-6 sticky top-0 z-10">
		<div class="text-center flex justify-between">
			<h6 class="text-stale-700 text-xl font-bold">{title}</h6>
			<button
				class="bg-stale-600 text-white active:bg-red-500 font-bold uppercase text-xs px-4 py-2 rounded shadow hover:shadow-md outline-none focus:outline-none mr-1 ease-linear transition-all duration-150"
				type="button"
			>
				Confirmar
			</button>
		</div>
	</div>
	<div class="flex-auto px-4 lg:px-10 py-10 pt-0">
        <slot />
	</div>
</div>
