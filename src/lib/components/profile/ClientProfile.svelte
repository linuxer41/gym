<script lang="ts">
	import { subscriberService } from "$lib/core/services";
	import { createEventDispatcher } from "svelte";
	import ClientForm from "../forms/ClientForm.svelte";
	import ClientResult from "./ClientResult.svelte";

	export let subscriber: Subscriber;
    const dispatch = createEventDispatcher();
    let edit = false;
    
    async function load(){
        setTimeout(async() => {
            if(subscriber?.id) subscriber = await subscriberService.get(subscriber.id);
        }, 300);
    }


</script>

<!-- subscriber profile -->
<div id="content" class="bg-white col-span-9 rounded-lg px-6 overflow-auto">
    <div class="flex flex-row justify-between sticky top-0 bg-white">
        <button
            class="flex flex-row items-center justify-center bg-slate-400 rounded-full w-10 h-10"
            on:click={() => {
                dispatch('close')
            }}
        >
            <i class="fas fa-times text-white"></i>
        </button>
        <div class="grid gap-2 grid-flow-col">
            <button on:click={()=>edit=true}>
                <i class="fas fa-edit text-xl text-green-500" ></i>
            </button>
            <!-- <i class="fas fa-trash text-xl text-red-500"></i> -->
        </div>
    </div>
    <ClientResult {subscriber} />
</div>
{#if edit}
    <ClientForm isEdit data={subscriber} on:close={()=>edit=false} on:create={async(e)=>{edit=false;subscriber = {...e.detail, ...subscriber}}} />
{/if}

<style lang="scss">
    .calendar{
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
        grid-gap: 1rem;
        padding-bottom: 1rem;
        
        .month{
            display: grid;
            grid-template-columns: repeat(7, 1fr);
            grid-gap: 0.5rem;
            padding: 0.5rem;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            border-radius: 5px;
            .day{
                display: grid;
                text-align: center;
                justify-content: center;
                align-items: center;
                border-radius: 5px;
                text-transform: capitalize;
                // border: 1px solid rgb(226, 226, 226);
                &.active{
                    background-color: greenyellow;
                    color: #fff;
                }
            }
        }

    }
    table{
        width: 100%;
        border-collapse: collapse;
        border-spacing: 0;
        border: 1px solid #e2e8f0;
        thead{
            tr{
                th{
                    padding: 0.5rem;
                    border-bottom: 1px solid #e2e8f0;
                    text-align: left;
                    font-size: 0.75rem;
                    font-weight: 600;
                    text-transform: uppercase;
                    color: #4a5568;
                    letter-spacing: 0.05em;
                }
            }
        }
        tbody{
            tr{
                td{
                    padding: 0.5rem;
                    border-bottom: 1px solid #e2e8f0;
                    text-align: left;
                    font-size: 0.75rem;
                    font-weight: 400;
                    color: #4a5568;
                    letter-spacing: 0.05em;
                }
            }
        }
    }
</style>
