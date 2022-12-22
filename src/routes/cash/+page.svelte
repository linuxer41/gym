<script lang="ts">
	import { clientService, rpcService } from "$lib/core/services";
	import {endOfDay, endOfMonth, endOfToday, endOfWeek, endOfYear, endOfYesterday, startOfDay, startOfMonth, startOfToday, startOfWeek, startOfYear, startOfYesterday} from "date-fns";
	import { onMount } from "svelte";
    

    const now = new Date()
	let dateRanges = [
        {
            label: 'Hoy',
            value: 'today',
            start: startOfToday(),
            end: endOfToday(),
        },
        {
            label: 'Ayer',
            value: 'yesterday',
            start: startOfYesterday(),
            end: endOfYesterday(),
        },
        {
            label: 'Semana',
            value: 'week',
            start: startOfWeek(new Date()),
            end: endOfWeek(new Date()),
        },
        {
            label: 'Mes',
            value: 'month',
            start: startOfMonth(new Date()),
            end: endOfMonth(new Date()),
        },
        {
            label: 'Año',
            value: 'year',
            start: startOfYear(new Date()),
            end: endOfYear(new Date()),

        },
        {
            label: 'Todo',
            value: 'all',
            start: startOfYear(new Date(1970, 0, 1)),
            end: endOfYear(new Date()),
        },
    ];
    let selectedRange: typeof dateRanges[0]
    let cashFlowData: any[] = [], cashFlowPagesLength= 0, cashFlowTotalLength= 0, cashFlowCurrentPage= 0


async function loadCashFlow(range: typeof selectedRange, page=0, limit=10){
    const response = await clientService.getDbClient()
    .select(`*`)
    .and.gte('date', range.start.toISOString())
    .lte('date', range.end.toISOString())
    .page(page, limit)
    .get('cash_flow', true)
    // assign data to variables
    cashFlowData = response.data
    cashFlowPagesLength = response.pagesLength
    cashFlowTotalLength = response.totalLength
    console.log(response)
    
}
function paginate(totalPages: number, subscriptionCurrentPage: number = 0) {
    // create array from number and splice it in current page. ex: [subscriptionCurrentPage-1, subscriptionCurrentPage, subscriptionCurrentPage+1]
    const pages =  Array.from({ length:totalPages }, (_, i) => i)
    const maxIndex = pages.length - 1
    const currentIndex = pages.indexOf(subscriptionCurrentPage)
    if (currentIndex === -1) return []
    if (maxIndex <= 2) return pages
    let toReturn = [...pages].slice(currentIndex-1, currentIndex+2)
    //  if current page is 0, return first 3 pages
    if(currentIndex === 0) toReturn = [...pages].slice(0, 3)
    // if current page is last page, return last 3 pages
    if(currentIndex === maxIndex) toReturn = [...pages].slice(maxIndex-2, maxIndex+1)
    // if current page is not first or last page, return current page and 2 pages before and after
    console.log({pages, toReturn, currentIndex, maxIndex})
    return toReturn

}
selectedRange = dateRanges[0]
onMount(async ()=>{
    loadCashFlow(selectedRange)
})
	</script>

<div id="content" class="bg-white col-span-9 p-6 overflow-auto">
    <div id="statictics">
        <h1 class="font-bold py-4 uppercase flex justify-between">
            <span>
                Caja
            </span>
            <div class="text-normal grid grid-flow-col gap-2">
                <!-- {#each dateRanges as range}
                <button on:click={()=>{cashFlowCurrentPage=0;selectedRange=range}} class="{range===selectedRange?'':'opacity-25'}">{range.label}</button>
                {/each} -->
            </div>
        </h1>
    </div>
    <div id="last-users">
        <div class="reports">
            <div class="report">
                <div class="header grid grid-cols-[1fr_auto]">
                    <h4 class="font-bold">{
                        new Intl.DateTimeFormat('es-ES', {
                            year: 'numeric',
                            month: 'long',
                            day: 'numeric',
                        }).format(selectedRange.start)
                        }</h4>
                    <div class="flex">
                        <!-- download -->
                        <i class="fas fa-download"></i>
                    </div>
                </div>
                <div class="body">
                    <table>
                        <thead>
                            <tr>
                                <th>Dia</th>
                                <th>Pagos</th>
                                <th>Monto total</th>
                                <th>Usuario</th>
                            </tr>
                        </thead>
                        <tbody>
                            {#each cashFlowData as cashFlow}
                            <tr>
                                <td>{cashFlow.date}</td>
                                <td>{cashFlow.payments_count}</td>
                                <td>{cashFlow.amount}</td>
                                <td>{cashFlow.user_name}</td>
                            {/each}

                        </tbody>
                    </table>
                </div>
                <div class="footer">
                    <!-- navigation design < prev 1 2 3 next> -->
                    <div class="flex justify-between">
                        <div class="flex">
                            <!-- total count -->
                            <p class="text-gray-400">Total: {cashFlowTotalLength}</p>
                        </div>
                        <div class="flex items-center gap-3">
                            {#if cashFlowPagesLength > 1}
                                {#if (cashFlowCurrentPage - 1) > 0}
                                <button class="flex items-center justify-center" on:click={()=>cashFlowCurrentPage--}>
                                    <i class="fas fa-chevron-left text-xs"></i>
                                </button>
                                {/if}
                                {#each paginate(cashFlowPagesLength, cashFlowCurrentPage) as page, index}
                                <button class="px-2" class:active={cashFlowCurrentPage === page} on:click={()=>cashFlowCurrentPage = page}>{page + 1} </button>
                                {/each}
                                {#if (cashFlowCurrentPage + 2) <= cashFlowPagesLength && cashFlowPagesLength > 3}
                                <button class="flex items-center justify-center" on:click={()=>cashFlowCurrentPage++}>
                                    <i class="fas fa-chevron-right text-xs"></i>
                                </button>
                                {/if}
                            {/if}
                        </div>
                    </div>
                </div>
                
            </div>
        </div>
    </div>
</div>

<style lang="scss">
    .reports{
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(800px, 1fr));
        gap: 1rem;
        .report{
            @apply bg-gray-700 rounded-lg shadow-lg p-3 text-white;
            .header{
                @apply p-3;
            }
            .body{
                @apply p-3 w-full h-96 overflow-y-auto;
                table{
                    @apply w-full;
                    thead{
                        @apply text-white;
                        th{
                            @apply py-3 px-2 text-start;
                        }
                    }
                    
                    tr{
                        @apply border-b border-gray-800;
                        td{
                            @apply py-3 px-2 text-white;
                        }
                    }
                }

            }
            .footer{
                @apply p-3;
            }
        }
    }
    .active{
        @apply bg-gray-800;
    }
</style>
