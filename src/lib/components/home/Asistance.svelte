<script>
	import FormLayer from "../forms/FormLayer.svelte";

    export let title = 'Formulario';
</script>
<FormLayer {title}>
    <form>
        <h6 class="text-stale-400 text-sm mt-3 mb-6 font-bold uppercase">Cliente</h6>
        <div class="flex flex-wrap">
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label
                        class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-client"
                    >
                        Buscar cliente
                    </label>
                    <input
                        id="grid-client"
                        type="text"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        placeholder="Nombre o codigo cliente"
                    />
                </div>
            </div>
        </div>
        <h6 class="text-stale-400 text-sm mt-3 mb-6 font-bold uppercase">Resultados</h6>
        <div class="flex flex-wrap">
            <p>
                resultados
            </p>
        </div>
    </form>
</FormLayer>
