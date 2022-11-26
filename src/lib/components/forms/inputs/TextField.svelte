<script lang="ts">
export let value: number | string = '';
export let label = '';
export let placeholder = '';
export let type: 'text' | 'email' | 'password' | 'tel' | 'number' = 'text';
export let required = false;
</script>
<div class="w-full lg:w-6/12 px-4">
    <div class="relative w-full mb-3">
        <label
            class="block uppercase text-stale-600 text-xs font-bold mb-2"
            for="grid-phone"
        >
            {label}
            {#if required}
            <span>
                <i class="fas fa-asterisk text-red-500 text-xs"></i>
            </span>
            {/if}
        </label>
        <input
            id="grid-prone"
            {type}
            {placeholder}
            {value}
            {required}
            class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
            on:input={(e) => (value = e.currentTarget.value)}
        />
    </div>
</div>