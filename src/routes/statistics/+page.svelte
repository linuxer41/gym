<script lang="ts">
	import { clientService, rpcService } from "$lib/core/services";
	import {endOfDay, endOfMonth, endOfToday, endOfWeek, endOfYear, endOfYesterday, startOfDay, startOfMonth, startOfToday, startOfWeek, startOfYear, startOfYesterday} from "date-fns";
	import bs from "date-fns/locale/bs";
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

    let subscriptionData: any[] = [], subscriptionPagesLength= 0, subscriptionTotalLength= 0, subscriptionCurrentPage= 0
    let attendanceData: any[] = [], attendancePagesLength= 0, attendanceTotalLength= 0, attendanceCurrentPage= 0
    $:{
        if(selectedRange && window){
            loadInscripciones(selectedRange, subscriptionCurrentPage)
            loadResume(selectedRange)
            loadAttendances(selectedRange)
        }
    }
    
    // 'attendance_count', attendance_count,
    //     'clients_count', clients_count,
    //     'subscriptions_count', subscriptions_count,
    //     'debts_count', debts_count,
    //     'debts_amount', debts_amount,
    //     'payments_count', payments_count,
    //     'payments_amount', payments_amount,
    //     'permissions_count', permissions_count,
    //     'total_income', total_income,
    //     'total_expenses', total_expenses
interface StatisticsResume {
    attendance_count:    number;
    clients_count:       number;
    subscriptions_count: number;
    debts_count:         number;
    debts_amount:        number;
    payments_count:      number;
    payments_amount:     number;
    permissions_count:   number;
    total_income:        number;
    total_expenses:      number;
}
let statistics = {} as StatisticsResume
async function loadResume(range: typeof selectedRange){
    const response = await rpcService.statistics({
        start_date: range.start.toISOString(),
        end_date: range.end.toISOString(),
    })
    if (!response.ok) {
        throw new Error(response.statusText);
    }
    statistics = await response.json();
}

async function loadInscripciones(range: typeof selectedRange, page=0, limit=10){
    const response = await clientService.getDbClient()
    .select(`*, client:clients(*),
    membership:memberships(*, plan:plans(*)), payments:payments(*)`)
    .and.gte('created_at', range.start.toISOString())
    .lte('created_at', range.end.toISOString())
    .page(page, limit)
    .get('subscriptions', true)
    // assign data to variables
    subscriptionData = response.data
    subscriptionPagesLength = response.pagesLength
    subscriptionTotalLength = response.totalLength
    console.log(response)
}

async function loadAttendances(range: typeof selectedRange, page=0, limit=10){
    const response = await clientService.getDbClient()
    .select(`*, subscription:subscriptions(client:clients(*))`)
    .and.gte('date', range.start.toISOString())
    .lte('date', range.end.toISOString())
    .page(page, limit)
    .get('attendances', true)
    // assign data to variables
    attendanceData = response.data
    attendancePagesLength = response.pagesLength
    attendanceTotalLength = response.totalLength
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
    await loadResume(selectedRange)
    loadInscripciones(selectedRange)
    loadAttendances(selectedRange)
})
	</script>

<div id="content" class="bg-white col-span-9 p-6 overflow-auto">
    <div id="statictics">
        <h1 class="font-bold py-4 uppercase flex justify-between">
            <span>
                Estadísticas
            </span>
            <div class="text-normal grid grid-flow-col gap-2">
                {#each dateRanges as range}
                <button on:click={()=>{subscriptionCurrentPage=0;selectedRange=range}} class="{range===selectedRange?'':'opacity-25'}">{range.label}</button>
                {/each}
            </div>
        </h1>
        <h1 class="font-bold py-4 uppercase">Resumen</h1>
        <div id="stats" class="grid gird-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div class="bg-black/60 to-white/5 p-6 rounded-lg">
                <div class="flex flex-row space-x-4 items-center">
                    <div id="stats-1">
                        <i class="fas fa-users text-white text-4xl"></i>
                    </div>
                    <div>
                        <p class="text-indigo-300 text-sm font-medium uppercase leading-4">Nuevos clientes</p>
                        <p class="text-white font-bold text-2xl inline-flex items-center space-x-2">
                            <span>+{statistics.clients_count || 0}</span>
                            <span>
                                <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    fill="none"
                                    viewBox="0 0 24 24"
                                    stroke-width="1.5"
                                    stroke="currentColor"
                                    class="w-6 h-6"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 015.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941"
                                    />
                                </svg>
                            </span>
                        </p>
                    </div>
                </div>
            </div>
            <div class="bg-black/60 p-6 rounded-lg">
                <div class="flex flex-row space-x-4 items-center">
                    <div id="stats-1">
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            class="w-10 h-10 text-white"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                d="M12 6v12m-3-2.818l.879.659c1.171.879 3.07.879 4.242 0 1.172-.879 1.172-2.303 0-3.182C13.536 12.219 12.768 12 12 12c-.725 0-1.45-.22-2.003-.659-1.106-.879-1.106-2.303 0-3.182s2.9-.879 4.006 0l.415.33M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                            />
                        </svg>
                    </div>
                    <div>
                        <p class="text-indigo-300 text-sm font-medium uppercase leading-4">Ingreso</p>
                        <p class="text-white font-bold text-2xl inline-flex items-center space-x-2">
                            <span>Bs {statistics.payments_amount || 0}</span>
                            <span>
                                <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    fill="none"
                                    viewBox="0 0 24 24"
                                    stroke-width="1.5"
                                    stroke="currentColor"
                                    class="w-6 h-6"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 015.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941"
                                    />
                                </svg>
                            </span>
                        </p>
                    </div>
                </div>
            </div>
            <div class="bg-black/60 p-6 rounded-lg">
                <div class="flex flex-row space-x-4 items-center">
                    <div id="stats-1">
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            class="w-10 h-10 text-white"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"
                            />
                        </svg>
                    </div>
                    <div>
                        <p class="text-blue-300 text-sm font-medium uppercase leading-4">Deudas</p>
                        <p class="text-white font-bold text-2xl inline-flex items-center space-x-2">
                            <span>Bs {statistics.debts_amount || 0}</span>
                            <span>
                                <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    fill="none"
                                    viewBox="0 0 24 24"
                                    stroke-width="1.5"
                                    stroke="currentColor"
                                    class="w-6 h-6"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 015.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941"
                                    />
                                </svg>
                            </span>
                        </p>
                    </div>
                </div>
            </div>
            <div class="bg-black/60 p-6 rounded-lg">
                <div class="flex flex-row space-x-4 items-center">
                    <div id="stats-1">
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            class="w-10 h-10 text-white"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"
                            />
                        </svg>
                    </div>
                    <div>
                        <p class="text-blue-300 text-sm font-medium uppercase leading-4">Asistencias</p>
                        <p class="text-white font-bold text-2xl inline-flex items-center space-x-2">
                            <span>+{statistics.attendance_count || 0}</span>
                            <span>
                                <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    fill="none"
                                    viewBox="0 0 24 24"
                                    stroke-width="1.5"
                                    stroke="currentColor"
                                    class="w-6 h-6"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 015.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941"
                                    />
                                </svg>
                            </span>
                        </p>
                    </div>
                </div>
            </div>
            <div class="bg-black/60 p-6 rounded-lg">
                <div class="flex flex-row space-x-4 items-center">
                    <div id="stats-1">
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke-width="1.5"
                            stroke="currentColor"
                            class="w-10 h-10 text-white"
                        >
                            <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"
                            />
                        </svg>
                    </div>
                    <div>
                        <p class="text-blue-300 text-sm font-medium uppercase leading-4">Permisos</p>
                        <p class="text-white font-bold text-2xl inline-flex items-center space-x-2">
                            <span>+{statistics.permissions_count || 0}</span>
                            <span>
                                <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    fill="none"
                                    viewBox="0 0 24 24"
                                    stroke-width="1.5"
                                    stroke="currentColor"
                                    class="w-6 h-6"
                                >
                                    <path
                                        stroke-linecap="round"
                                        stroke-linejoin="round"
                                        d="M2.25 18L9 11.25l4.306 4.307a11.95 11.95 0 015.814-5.519l2.74-1.22m0 0l-5.94-2.28m5.94 2.28l-2.28 5.941"
                                    />
                                </svg>
                            </span>
                        </p>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div id="last-users">
        <h1 class="font-bold py-4 uppercase">Reportes</h1>
        <div class="reports">
            <div class="report">
                <div class="header grid grid-cols-[1fr_auto]">
                    <h4 class="font-bold">Inscripciones</h4>
                    <div class="flex">
                        <!-- download -->
                        <i class="fas fa-download"></i>
                    </div>
                </div>
                <div class="body">
                    <table>
                        <thead>
                            <tr>
                                <th>Cliente</th>
                                <th>Inicio</th>
                                <th>Fin</th>
                                <th>Precio</th>
                                <th>Pago</th>
                                <th>Balance</th>
                                <th>Membresía</th>
                                <th>Plan</th>
                                <th>Estado</th>
                            </tr>
                        </thead>
                        <tbody>
                            {#each subscriptionData as subscription}
                            <tr>
                                <td>{subscription.client?.name}</td>
                                <td>{subscription.start_date}</td>
                                <td>{subscription.end_date}</td>
                                <td>{subscription.price}</td>
                                <td>{(subscription.payments || []).reduce((a, b) => a + b.amount, 0)}</td>
                                <td>{subscription.balance}</td>
                                <td>{subscription.membership?.name}</td>
                                <td>{subscription.membership?.plan?.name}</td>
                                <td>{subscription.status || 'activo'}</td>
                            {/each}
                        </tbody>
                    </table>
                </div>
                <div class="footer">
                    <!-- navigation design < prev 1 2 3 next> -->
                    <div class="flex justify-between">
                        <div class="flex">
                            <!-- total count -->
                            <p class="text-gray-400">Total: {subscriptionTotalLength}</p>
                        </div>
                        <div class="flex items-center gap-3">
                            {#if subscriptionPagesLength > 1}
                                {#if (subscriptionCurrentPage - 1) > 0}
                                <button class="flex items-center justify-center" on:click={()=>subscriptionCurrentPage--}>
                                    <i class="fas fa-chevron-left text-xs"></i>
                                </button>
                                {/if}
                                {#each paginate(subscriptionPagesLength, subscriptionCurrentPage) as page, index}
                                <button class="px-2" class:active={subscriptionCurrentPage === page} on:click={()=>subscriptionCurrentPage = page}>{page + 1} </button>
                                {/each}
                                {#if (subscriptionCurrentPage + 2) <= subscriptionPagesLength && subscriptionPagesLength > 3}
                                <button class="flex items-center justify-center" on:click={()=>subscriptionCurrentPage++}>
                                    <i class="fas fa-chevron-right text-xs"></i>
                                </button>
                                {/if}
                            {/if}
                        </div>

                    </div>
                </div>
                
            </div>
            <div class="report">
                <div class="header grid grid-cols-[1fr_auto]">
                    <h4 class="font-bold">Asistencias</h4>
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
                                <th>Cliente</th>
                                <th>Entrada</th>
                                <th>Salida</th>
                            </tr>
                        </thead>
                        <tbody>
                            {#each attendanceData as attendance}
                            <tr>
                                <td>{attendance.date}</td>
                                <td>{attendance?.subscription?.client?.name || ''}</td>
                                <td>{attendance.start_time?.substring(0,5) || '--'}</td>
                                <td>{attendance.end_time || '--'}</td>
                            {/each}

                        </tbody>
                    </table>
                </div>
                <div class="footer">
                    <!-- navigation design < prev 1 2 3 next> -->
                    <div class="flex justify-between">
                        <div class="flex">
                            <!-- total count -->
                            <p class="text-gray-400">Total: {attendanceTotalLength}</p>
                        </div>
                        <div class="flex items-center gap-3">
                            {#if attendancePagesLength > 1}
                                {#if (attendanceCurrentPage - 1) > 0}
                                <button class="flex items-center justify-center" on:click={()=>attendanceCurrentPage--}>
                                    <i class="fas fa-chevron-left text-xs"></i>
                                </button>
                                {/if}
                                {#each paginate(attendancePagesLength, attendanceCurrentPage) as page, index}
                                <button class="px-2" class:active={attendanceCurrentPage === page} on:click={()=>attendanceCurrentPage = page}>{page + 1} </button>
                                {/each}
                                {#if (attendanceCurrentPage + 2) <= attendancePagesLength && attendancePagesLength > 3}
                                <button class="flex items-center justify-center" on:click={()=>attendanceCurrentPage++}>
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
