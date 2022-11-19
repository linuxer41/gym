<script>
	import CardSettings from "../Cards/CardSettings.svelte";
	import FormLayer from "./FormLayer.svelte";

    export let title = 'Formulario';
</script>
<FormLayer {title}>
    <form>
        <h6 class="text-stale-400 text-sm mt-3 mb-6 font-bold uppercase">Informacion del cliente</h6>
        <div class="flex flex-wrap">
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label
                        class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-first-name"
                    >
                        Nombre
                    </label>
                    <input
                        id="grid-first-name"
                        type="text"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        value="Juan"
                    />
                </div>
            </div>
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label
                        class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-last-name"
                    >
                        Apellido
                    </label>
                    <input
                        id="grid-last-name"
                        type="text"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        value="Perez"
                    />
                </div>
            </div>
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label
                        class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-first-name"
                    >
                        Fecha Nac.
                    </label>
                    <input
                        id="grid-first-name"
                        type="date"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        value="1990-01-01"
                    />
                </div>
            </div>
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label
                        class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-last-name"
                    >
                        CI
                    </label>
                    <input
                        id="grid-last-name"
                        type="text"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        value="12345678"
                    />
                </div>
            </div>
        </div>

        <hr class="mt-6 border-b-1 border-stale-300" />

        <h6 class="text-stale-400 text-sm mt-3 mb-6 font-bold uppercase">Información de contacto</h6>
        <div class="flex flex-wrap">
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label
                        class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-phone"
                    >
                        Celular
                    </label>
                    <input
                        id="grid-prone"
                        type="tel"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        value="71307408"
                    />
                </div>
            </div>
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label class="block uppercase text-stale-600 text-xs font-bold mb-2" for="grid-email">
                        Email
                    </label>
                    <input
                        id="grid-email"
                        type="email"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        value="juan@example.com"
                    />
                </div>
            </div>
            <div class="w-full lg:w-12/12 px-4">
                <div class="relative w-full mb-3">
                    <label class="block uppercase text-stale-600 text-xs font-bold mb-2" for="grid-address">
                        Dirección
                    </label>
                    <input
                        id="grid-address"
                        type="text"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        value="Sucre, Calle bejarano #5"
                    />
                </div>
            </div>
        </div>

        <hr class="mt-6 border-b-1 border-stale-300" />

        <h6 class="text-stale-400 text-sm mt-3 mb-6 font-bold uppercase">Suscripcion</h6>
        <div class="flex flex-wrap">
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label
                        class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-phone"
                    >
                        Tipo
                    </label>
                    <select
                        id="grid-prone"
                        type="tel"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                    >
                        <option value="1">Mensual</option>
                        <option value="2">Anual</option>
                    </select>
                </div>
            </div>
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label class="block uppercase text-stale-600 text-xs font-bold mb-2" for="grid-email">
                        Fecha Inicio
                    </label>
                    <input
                        id="grid-email"
                        type="date"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        value="2021-01-01"
                    />
                </div>
            </div>
            <div class="w-full lg:w-6/12 px-4">
                <div class="relative w-full mb-3">
                    <label class="block uppercase text-stale-600 text-xs font-bold mb-2" for="grid-email">
                        Fecha Fin
                    </label>
                    <input
                        id="grid-email"
                        type="date"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        value="2021-01-01"
                    />
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
                        value="100"
                    />
                </div>
            </div>
        </div>
        <!-- <div class="flex flex-wrap">
            <div class="w-full lg:w-12/12 px-4">
                <div class="relative w-full mb-3">
                    <label
                        class="block uppercase text-stale-600 text-xs font-bold mb-2"
                        for="grid-about-me"
                    >
                        About me
                    </label>
                    <textarea
                        id="grid-about-me"
                        type="text"
                        class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
                        rows="4"
                        value="A beautiful UI Kit and Admin for Svelte & Tailwind CSS. It is Free
            and Open Source."
                    />
                </div>
            </div>
        </div> -->
    </form>
</FormLayer>
