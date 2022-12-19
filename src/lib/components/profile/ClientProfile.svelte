<script lang="ts">
	import { getDaysInMonth, getWeek, getWeeksInMonth } from "date-fns";
	import { createEventDispatcher } from "svelte";
	import { current_component } from "svelte/internal";

	export let subscriber: Subscriber;
    const dispatch = createEventDispatcher();
    // create list of dates for 3 months, past, current and next grouped by month using date-fns
    // example: [
     // {month: '2021-08', days: [
    //  {day: 1, date: '2021-08-01', week: 1, name: 'Lun-01'},
    // ]}
    // ]
    
    function getDates() {
        const dates = [];
        const today = new Date();
        const currentMonth = today.getMonth();
        const currentYear = today.getFullYear();
        const months = [currentMonth - 1, currentMonth, currentMonth + 1];
        months.forEach((month) => {
            const monthDate = new Date(currentYear, month);
            const monthName = monthDate.toLocaleString('es-BO', { month: 'long' });
            const monthNumber = monthDate.getMonth();
            const monthYear = monthDate.getFullYear();
            const monthKey = `${monthYear}-${monthNumber + 1}`;
            const days = [];
            const daysInMonth = getDaysInMonth(monthDate);
            for (let i = 1; i <= daysInMonth; i++) {
                const dayDate = new Date(monthYear, monthNumber, i);
                const dayName = dayDate.toLocaleString('es-BO', { weekday: 'short' });
                const dayNumber = dayDate.getDate();
                const dayKey = `${monthKey}-${dayNumber}`;
                const dayWeek = getWeek(dayDate);
                days.push({
                    day: dayNumber,
                    date: dayKey,
                    week: dayWeek,
                    name: `${dayName}`,
                });
            }
            dates.push({
                year: monthYear,
                name: monthName,
                days,
            });

        });
        return dates;
    }
    console.log(getDates());


    async function load() {
        
    }

</script>

<!-- susbcriber profile -->
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
            <i class="fas fa-edit text-xl text-green-500"></i>
            <i class="fas fa-trash text-xl text-red-500"></i>
        </div>
    </div>
    <div>
        <h1 class="font-bold py-4 uppercase">Detalles de la cuenta</h1>
        <div class="flex flex-row space-x-4">
            <div class="flex flex-col">
                <h6 class="text-slate-400 text-xs mt-3 mb-6 font-bold">
                    Nombre
                </h6>
                <h1 class="font-bold text-sm">
                    {subscriber.name || 'N/A'}
                </h1>
            </div>
            <div class="flex flex-col">
                <h6 class="text-slate-400 text-xs mt-3 mb-6 font-bold">
                    CI
                </h6>
                <h1 class="font-bold text-sm">
                    {subscriber.dni || 'N/A'}
                </h1>
            </div>
            <div class="flex flex-col">
                <h6 class="text-slate-400 text-xs mt-3 mb-6 font-bold">
                    Email
                </h6>
                <h1 class="font-bold text-sm">
                    {subscriber.email || 'N/A'}
                </h1>
            </div>
            <div class="flex flex-col">
                <h6 class="text-slate-400 text-xs mt-3 mb-6 font-bold">
                    Teléfono
                </h6>
                <h1 class="font-bold text-sm">
                    {subscriber.phone || 'N/A'}
                </h1>
            </div>

        </div>
    </div>
    <div id="last-incomes">
        <h1 class="font-bold py-4 uppercase">Suscripción actual</h1>

        <div class="flex flex-row space-x-4">
            {#if subscriber.active_subscription}
            <div class="flex flex-col">
                <h6 class="text-slate-400 text-xs mt-3 mb-6 font-bold">
                    Fecha de inicio
                </h6>
                <h1 class="font-bold text-sm">
                    {subscriber.active_subscription.start_date || 'N/A'}
                </h1>
            </div>
            <div class="flex flex-col">
                <h6 class="text-slate-400 text-xs mt-3 mb-6 font-bold">
                    Fecha de fin
                </h6>
                <h1 class="font-bold text-sm">
                    {subscriber.active_subscription.end_date || 'N/A'}
                </h1>
            </div>
            <div class="flex flex-col">
                <h6 class="text-slate-400 text-xs mt-3 mb-6 font-bold">
                    Estado
                </h6>
                <h1 class="font-bold text-sm">
                    Activo
                </h1>
            </div>
            <div class="flex flex-col">
                <h6 class="text-slate-400 text-xs mt-3 mb-6 font-bold">
                    Tipo
                </h6>
                <h1 class="font-bold text-sm">
                    { (subscriber.active_subscription.membership.name + ' - ' + subscriber.active_subscription.plan.name) || 'N/A'}
                </h1>
            </div>
            {:else}
            <div class="flex flex-col">
                <h6 class="text-slate-400 text-xs mt-3 mb-6 font-bold">
                    Sin suscripción activa
                </h6>
            </div>
            {/if}

        </div>
    </div>
    <div id="last-users">
        <h1 class="font-bold py-4 uppercase">Asistencias</h1>
        <!-- inline calendar flex 3 items -->
        <div class="calendar">
            {#each getDates() as month}
                <div>
                    <h6 class="text-slate-400 text-xs mt-3 mb-6 font-bold">
                        {month.year} - {month.name}
                    </h6>
                    <div class="month">
                    {#each month.days as day}
                        <div class="day">
                            <h1 class="font-bold text-sm">
                                {day.day}
                            </h1>
                            <h1 class="text-sm text-gray-400">
                                {day.name}
                            </h1>
                        </div>
                    {/each}
                    </div>
                </div>
            {/each}
        </div>
    </div>
    <div id="last-incomes">
        <h1 class="font-bold py-4 uppercase">Historial de suscripciones</h1>
        <div>
            <table>
                <thead>
                    <tr>
                        <th>Fecha de inicio</th>
                        <th>Fecha de fin</th>
                        <th>Tipo</th>
                        <th>Asistencias</th>
                        <th>Permisos</th>
                        <th>Monto pagado</th>
                        <th>Estado</th>
                    </tr>
                </thead>
                <tbody>
                    {#each (subscriber.subscriptions || []) as subscription}
                    <tr>
                        <td>{subscription.start_date}</td>
                        <td>{subscription.end_date}</td>
                        <td>{subscription.membership.name + ' - ' + subscription.plan.name}</td>
                        <td>{subscription.attendances_count}</td>
                        <td>{subscription.permissions_count}</td>
                        <td>{subscription.total_paid}</td>
                        <td>{subscription.expired? 'Expirado' : !subscription.is_active? 'Desactivado': 'Activo' }</td>
                    </tr>
                    {/each}
                </tbody>
            </table>
        </div>
    </div>
</div>

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
                background-color: #fff;
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
