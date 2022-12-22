<script lang="ts">
	import { getDaysInMonth, getWeek, isBefore, isWithinInterval } from "date-fns";
	
	export let subscriber: Subscriber;

    
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
    function getBgColorRange(subscription: Subscription, date: string) {

        if (isWithinInterval(new Date(date), {
            start: new Date(subscription.start_date),
            end: new Date(subscription.end_date)
        })) {
            return 'bg-blue-100';
        }
        return 'bg-gray-100';
    }
    function getBgColor(subscription: Subscription, date: string, attendances: Attendance[] = [], permissions: Permission[] = []) {
        const attendance = attendances.find((attendance) => attendance.date === date);
        if (attendance) {
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


</script>

<!-- susbcriber profile -->

    <div class="grid lg:grid-cols-[1fr_1fr] grid-cols-1 ">
        <div>
            <h1 class="font-bold py-4 uppercase">Detalles de la cuenta</h1>
            <div class="flex flex-row space-x-4">
                <div class="flex flex-col">
                    <h6 class="text-slate-400 text-xs mt-3 mb-1 font-bold">
                        Nombre
                    </h6>
                    <h1 class="font-bold text-sm">
                        {subscriber.name || 'N/A'}
                    </h1>
                </div>
                <div class="flex flex-col">
                    <h6 class="text-slate-400 text-xs mt-3 mb-1 font-bold">
                        CI
                    </h6>
                    <h1 class="font-bold text-sm">
                        {subscriber.dni || 'N/A'}
                    </h1>
                </div>
                <div class="flex flex-col">
                    <h6 class="text-slate-400 text-xs mt-3 mb-1 font-bold">
                        Email
                    </h6>
                    <h1 class="font-bold text-sm">
                        {subscriber.email || 'N/A'}
                    </h1>
                </div>
                <div class="flex flex-col">
                    <h6 class="text-slate-400 text-xs mt-3 mb-1 font-bold">
                        Teléfono
                    </h6>
                    <h1 class="font-bold text-sm">
                        {subscriber.phone || 'N/A'}
                    </h1>
                </div>
                <div class="flex flex-col">
                    <h6 class="text-slate-400 text-xs mt-3 mb-1 font-bold">
                        Deuda
                    </h6>
                    <h1 class="font-bold text-sm">
                        Bs {subscriber.balance || 0}
                    </h1>
                </div>

            </div>
            {#if subscriber.active_subscription}
            {@const active_subscription = subscriber.active_subscription}
            <h1 class="font-bold py-4 uppercase">Suscripción actual</h1>
            <div class="flex flex-row space-x-4">
                
                <div class="flex flex-col">
                    <h6 class="text-slate-400 text-xs mt-3 mb font-bold">
                        Fecha de inicio
                    </h6>
                    <h1 class="font-bold text-sm">
                        {active_subscription.start_date || 'N/A'}
                    </h1>
                </div>
                <div class="flex flex-col">
                    <h6 class="text-slate-400 text-xs mt-3 mb font-bold">
                        Fecha de fin
                    </h6>
                    <h1 class="font-bold text-sm">
                        {active_subscription.end_date || 'N/A'}
                    </h1>
                </div>
                <div class="flex flex-col">
                    <h6 class="text-slate-400 text-xs mt-3 mb font-bold">
                        Dias restantes
                    </h6>
                    <h1 class="font-bold text-sm">
                        {active_subscription.left_days || 'N/A'}
                    </h1>
                </div>
                <div class="flex flex-col">
                    <h6 class="text-slate-400 text-xs mt-3 mb font-bold">
                        Tipo
                    </h6>
                    <h1 class="font-bold text-sm">
                        { (active_subscription.membership.name + ' - ' + active_subscription.plan.name) || 'N/A'}
                    </h1>
                </div>
            </div>
            {:else}
            <div class="flex flex-col">
                <h6 class="text-red-400 text-xs mt-3 mb-6 font-bold">
                    Sin suscripción activa
                </h6>
            </div>
            {/if}
        </div>
        {#if subscriber.active_subscription}
        {@const active_subscription = subscriber.active_subscription}
        <div class="calendar">
            {#each getDates() as month}
            {@const monthAttendances = subscriber.subscriptions.flatMap(subscription => subscription.attendances).filter(attendance => attendance.date.startsWith(month.year + '-' + (month.days[0].date.split('-')[1])))}
            {@const monthPermissions = subscriber.subscriptions.flatMap(subscription => subscription.permissions).filter(permission => permission.date.startsWith(month.year + '-' + (month.days[0].date.split('-')[1])))}
                <div>
                    <h6 class="text-slate-400 text-xs mt-3 mb-2 font-bold">
                        {month.year} - {month.name}
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
                </div>
            {/each}
        </div>
        {:else}
        <div>
        </div>
        {/if}
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
