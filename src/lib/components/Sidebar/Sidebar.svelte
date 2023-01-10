<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
// core components
	import { authToken, storeUser } from '$lib/core/store';

	$: pathname = $page.url.pathname;
	const logo = '/logos/endor-logo.jpg';

	const routes = [
		{
			label: 'Gym',
			icon: 'fa-dumbbell',
			path: '/',
			access_level: 1,
			group: 'management'
		},
		{
			label: 'Caja',
			icon: 'fa-cash-register',
			path: '/cash',
			access_level: 1,
			group: 'management'
		},
		{
			label: 'Estadísticas',
			icon: 'fa-tv',
			path: '/statistics',
			access_level: 2,
			group: 'management'
		},
		{
			label: 'Ajustes',
			icon: 'fa-tools',
			path: '/settings',
			access_level: 2,
			group: 'management'
		},
		{
			label: 'Clientes',
			icon: 'fa-users',
			path: '/clients',
			access_level: 1,
			group: 'data'
		},
		{
			label: 'Usuarios',
			icon: 'fa-user',
			path: '/users',
			access_level: 2,
			group: 'data'
		}
	]
	let access_levels = [
		{
			id: 1,
			name: 'Usuario',
			key: 'api_user'
		},
		{
			id: 2,
			name: 'Administrador',
			key: 'api_admin'
		},

	]
</script>

<nav
	class="shadow-xl dark_bg flex flex-wrap items-center justify-between relative w-full z-10 py-4 px-6"
>
	<div
		class="flex-col items-stretch min-h-full flex-nowrap px-0 flex  justify-between w-full mx-auto"
	>
		<!-- Collapse -->
		<div
			class="flex flex-col items-stretch relative mt-4 shadow-none overflow-y-auto overflow-x-hidden h-auto items-center flex-1 rounded"
		>
			<!-- Brand -->
			<a
				class="block text-left text-slate-100 mr-0 inline-block whitespace-nowrap text-sm uppercase font-bold grid place-content-center "
				href="/"
			>
				<img class="w-40 object-fit rounded-[999px]" src={logo} alt="" />
			</a>
			<!-- Divider -->
			<hr class="my-4 md:min-w-full" />
			<!-- user name -->
			<p class="text-center text-slate-100 text-sm font-bold">
				{$storeUser?.name}
			</p>

			<!-- Divider -->
			<hr class="my-4 md:min-w-full" />
			<!-- Heading -->
			<h6
				class="md:min-w-full text-slate-100 text-xs uppercase font-bold block pt-1 pb-4 no-underline"
			>
				Administración
			</h6>
			<!-- Navigation -->

			<ul class="md:flex-col md:min-w-full flex flex-col list-none">
				{#each routes.filter(
					(route) => route.access_level <= (access_levels.find((level) => level.key === $storeUser?.role)?.id || 1)
					&& route.group === 'management'
				) as route, index}
				<li class="items-center">
					<a
						href="{route.path}"
						class="text-xs uppercase py-3 font-bold block {pathname === route.path
							? 'text-lime-500 hover:text-lime-600'
							: 'text-slate-200 hover:text-slate-100'}"
					>
						<i
							class="fas  {route.icon} mr-2 text-sm {pathname === route.path ? 'opacity-75' : 'text-slate-300'}"
						/>
						{route.label}
					</a>
				</li>
				{/each}
			</ul>

			<!-- Divider -->
			<hr class="my-4 md:min-w-full" />
			<!-- Heading -->
			<h6
				class="md:min-w-full text-slate-100 text-xs uppercase font-bold block pt-1 pb-4 no-underline"
			>
				Datos
			</h6>
			<!-- Navigation -->

			<ul class="md:flex-col md:min-w-full flex flex-col list-none md:mb-4">
				{#each routes.filter(
					(route) => route.access_level <= (access_levels.find((level) => level.key === $storeUser?.role)?.id || 1)
					&& route.group === 'data'
				) as route, index}
				<li class="items-center">
					<a
						href="{route.path}"
						class="text-xs uppercase py-3 font-bold block {pathname === route.path
							? 'text-lime-500 hover:text-lime-600'
							: 'text-slate-200 hover:text-slate-100'}"
					>
						<i
							class="fas {route.icon} mr-2 text-sm {pathname === route.path ? 'opacity-75' : 'text-slate-300'}"
						/>
						{route.label}
					</a>
				</li>
				{/each}
			</ul>
		</div>
		<button>
			<!-- svelte-ignore a11y-click-events-have-key-events -->
			<span
				class="text-red-500 mr-2 text-sm font-bold"
				on:click={async () => {
					authToken.flush();
					storeUser.flush();
					await goto('/auth');
				}}
			>
				Salir
			</span>
		</button>
	</div>
</nav>
