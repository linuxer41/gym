<script lang="ts">
	import { getDaysInMonth, getWeek, isBefore, isWithinInterval, parseISO, sub } from "date-fns";
	import DebtModal from "../modals/DebtModal.svelte";
	import ModalLayer from "../modals/ModalLayer.svelte";
	import { snackBar } from "$lib/core/store";
	import Dialog from "../common/Dialog.svelte";
	import { subscriptionService } from "$lib/core/services";
	
	export let subscriber: Subscriber;
    export let fontLarge = false;
    let showDebtModal = false;
    let toCancelSubscription: ClientSubscription|null = null;


    async function cancelSubscription(subs: ClientSubscription){
        try {
            const res = await subscriptionService.update(subs.id!, {
                is_active: false
            });
            snackBar.show({
                message: 'Suscripción cancelada con exito',
                type: 'success'
            });
        } catch (error) {
            snackBar.show({
                message: 'Error al cancelar la suscripción',
                type: 'error'
            });
            console.debug(error);
        }
    }
    
    function getDates() {
        const dates: any[] = [];
        const today = new Date();
        const currentMonth = today.getMonth();
        const currentYear = today.getFullYear();
        // const months = [currentMonth - 1, currentMonth, currentMonth + 1];
        const months = [currentMonth];
        months.forEach((month) => {
            const monthDate = new Date(currentYear, month);
            const monthName = monthDate.toLocaleString('es-BO', { month: 'long' });
            const monthNumber = monthDate.getMonth();
            const monthYear = monthDate.getFullYear();
            const monthKey = `${monthYear}-${String(monthNumber + 1).padStart(2, '0')}`;
            const days = [];
            const daysInMonth = getDaysInMonth(monthDate);
            for (let i = 1; i <= daysInMonth; i++) {
                const dayDate = new Date(monthYear, monthNumber, i);
                const dayName = dayDate.toLocaleString('es-BO', { weekday: 'short' });
                const dayNumber = dayDate.getDate();
                const dayKey = `${monthKey}-${String(dayNumber).padStart(2, '0')}`;
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
        console.log({dates});
        return dates;
    }
    function getBgColorRange(subscription: Subscription, date: string) {

        if (isWithinInterval(new Date(date), {
            start: new Date(subscription.start_date),
            end: new Date(subscription.end_date)
        })) {
            return 'bg-gray-100';
        }
        return 'bg-gray-400';
    }
    function getBgColor(subscription: Subscription, date: string, attendances: Attendance[] = [], permissions: Permission[] = []) {
        const attendance = attendances.find((attendance) => attendance.date === date);
        if (attendance) {
            console.log({'atte_dat': attendance.date, date, 'equal': attendance.date === date});
            return 'text-green-500';
        }
        const permission = permissions.find((permission) => permission.date === date);
        if (permission) {
            return 'text-yellow-500';
        }
        if (isWithinInterval(new Date(date), {
            start: new Date(subscription.start_date),
            end: new Date(subscription.end_date)
        }) && !attendance && !permission && isBefore(new Date(date), new Date())) {
            return 'text-red-500';
        }
        return 'text-gray-700';
    }


    const getUserShowProps = (subscriber: Subscriber)=> [
        {
            label: 'Nombre',
            value: subscriber.name || 'N/A',
        },
        {
            label: 'CI',
            value: subscriber.dni || 'N/A',
        },
        {
            label: 'Email',
            value: subscriber.email || 'N/A',
        },
        {
            label: 'Teléfono',
            value: subscriber.phone || 'N/A',
        },
        {
            label: 'Deuda',
            value: `Bs ${subscriber.balance || 0}`,
        }
    ]

    const infoColors = {
        'text-green-500': 'Asistió',
        'text-yellow-500': 'Permiso',
        'text-red-500': 'Falta',
        'text-gray-700': 'Habilitado',
    }
    const getSubscriptionInfo = (active_subscription: ClientSubscription) =>  {
        console.log({active_subscription});
        return[
        {
            label: 'Fecha de inicio',
            value: active_subscription.start_date || 'N/A',
        },
        {
            label: 'Fecha de fin',
            value: active_subscription.end_date || 'N/A',
        },
        {
            label: 'Dias restantes',
            value: active_subscription.left_days || 'N/A',
        },
        {
            label: 'Membresía',
            value: (active_subscription.membership.name + ' - ' + active_subscription.plan.name) || 'N/A',
        },
        {
            label: 'Tipo',
            value: (active_subscription.membership.item_type == 'continuous' ? 'Continuo' : 'Intervalo') || 'N/A',
        }
    ]}

</script>

<!-- subscriber profile -->

    <div class="grid lg:grid-cols-[1fr_1fr] grid-cols-1 gap-1 ">
        <div class="border border-gray-200 rounded-lg p-4">
            <h1 class="font-bold uppercase text-gray-700 text-center underline">Detalles de la cuenta</h1>
            <div class="grid grid-cols-2 gap-1">
                {#each getUserShowProps(subscriber) as prop}
                    <div class="flex flex-col">
                        <h6 class="text-slate {fontLarge?'text-lg':'text-xs'} text-gray-100 font-bold whitespace-nowrap overflow-hidden text-ellipsis">
                            {prop.label}
                        </h6>
                        <h1 class="font-bold {fontLarge?'text-xl':'text-xs'} whitespace-nowrap overflow-hidden text-ellipsis">
                            {prop.value}
                        </h1>
                    </div>
                {/each}
                <!-- Boton de pagar deuda -->
                {#if subscriber.balance > 0}
                    <div class="col-span-2">
                        <button class="bg-green-500 text-white font-bold py-2 px-4 rounded w-full" on:click={() => {
                            showDebtModal = true
                        }}>
                            Pagar deuda
                        </button>
                    </div>
                {/if}

            </div>
            <h1 class="font-bold uppercase text-gray-700 text-center underline">Suscripción actual</h1>
            {#if subscriber.active_subscription}
            {@const active_subscription = subscriber.active_subscription}
            <div class="grid grid-cols-2 gap-1">
                
                {#each getSubscriptionInfo(active_subscription) as prop}
                    <div class="flex flex-col">
                        <h6 class="text-slate {fontLarge?'text-lg':'text-xs'} text-gray-100 font-bold whitespace-nowrap overflow-hidden text-ellipsis">
                            {prop.label}
                        </h6>
                        <h1 class="font-bold {fontLarge?'text-xl':'text-xs'} whitespace-nowrap overflow-hidden text-ellipsis">
                            {prop.value}
                        </h1>
                    </div>
                {/each}
            </div>

            <!-- add remove subscription button -->
            <div class="flex justify-between">
                <button class="bg-red-500 text-white font-bold py-2 px-4 rounded w-full" on:click={() => {
                    toCancelSubscription = subscriber.active_subscription;
                }}>
                    Cancelar suscripción
                </button>
            </div>
            {:else}
                <h6 class="text-red-500 text-lg mt-3 mb-6 font-bold ">
                    Sin suscripción activa !!!
                </h6>
            {/if}
        </div>
        {#if subscriber.active_subscription}
        {@const active_subscription = subscriber.active_subscription}
        <div class="calendar">
            {#each getDates() as month}
            {@const monthAttendances = subscriber.subscriptions.flatMap(subscription => subscription.attendances).filter(attendance => attendance.date.startsWith(month.year + '-' + (month.days[0].date.split('-')[1])))}
            {@const monthPermissions = subscriber.subscriptions.flatMap(subscription => subscription.permissions).filter(permission => permission.date.startsWith(month.year + '-' + (month.days[0].date.split('-')[1])))}
                <div>
                    <h6 class="text-slate-100 text-xl mt-3 mb-2 font-bold">
                        Asistencias: {month.year} - {month.name}
                    </h6>
                    <div class="month">
                    {#each month.days as day}
                    
                        <div class="day {getBgColorRange(active_subscription, day.date)}">
                            <h1 class="font-bold text-sm  {getBgColor(active_subscription, day.date, monthAttendances, monthPermissions)} {
                                day.date === new Date().toISOString().split('T')[0] ? 'border border-blue-500 rounded-lg' : ''
                            }">
                                {day.day}
                            </h1>
                            <h1 class="text-sm text-gray-600">
                                {day.name}
                            </h1>
                        </div>
                    {/each}
                    </div>
                    <!-- info colors -->
                    <div class="flex flex-row gap-2 mt-2">
                        {#each Object.entries(infoColors) as [color, text]}
                            <div class="grid gap-1">
                                <div class="w-4 h-4 rounded-lg {color}">
                                 <i class="fas fa-check"></i>
                                </div>
                                <h1 class="text-sm text-gray-600">
                                    {text}
                                </h1>
                            </div>
                        {/each}
                    </div>
                </div>
            {/each}
        </div>
        {:else}
        <div>
        </div>
        {/if}
    </div>
    <div id="last-incomes dark_bg">
        <h1 class="font-bold py-4 uppercase">Historial de suscripciones</h1>
        <div>
            <table class="dark_bg">
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
{#if showDebtModal}
<DebtModal
    data={subscriber}
    on:close={() => showDebtModal = false}
    on:success={() => showDebtModal = false}
    on:payment
    title="Deudas del cliente"
/>
{/if}

{#if toCancelSubscription}
<Dialog
	title="Cancelar suscripción"
    message="¿Está seguro que desea cancelar la suscripción?. Esta acción no se puede deshacer."
	on:cancel={() => toCancelSubscription = null}
    on:confirm={() => {
        toCancelSubscription && cancelSubscription(toCancelSubscription)
        toCancelSubscription = null
        
        // snackBar.show({
        //     message: 'Funcionalidad no implementada',
        //     type: 'error'
        // })
    }}
>

</Dialog>
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
                // background-color: #fff;
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
                    color: white;
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
                    color: white;
                    letter-spacing: 0.05em;
                }
            }
        }
    }
</style>
