<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';

	// core components
	import NotificationDropdown from '$lib/components/Dropdowns/NotificationDropdown.svelte';
	import UserDropdown from '$lib/components/Dropdowns/UserDropdown.svelte';
	import { authToken, storeUser } from '$lib/core/store';

	$: pathname = $page.url.pathname;
	const logo = '/logos/endor-logo.jpg';
</script>

<nav
	class="shadow-xl bg-white flex flex-wrap items-center justify-between relative w-full z-10 py-4 px-6"
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
				class="block text-left md:pb-2 text-slate-600 mr-0 inline-block whitespace-nowrap text-sm uppercase font-bold p-4 px-0"
				href="/"
			>
				<img class="w-40" src={logo} alt="" />
			</a>
			<!-- Divider -->
			<hr class="my-4 md:min-w-full" />
			<!-- user name -->
			<p class="text-center text-slate-600 text-sm font-bold">
				{$storeUser?.name}
			</p>

			<!-- Divider -->
			<hr class="my-4 md:min-w-full" />
			<!-- Heading -->
			<h6
				class="md:min-w-full text-slate-500 text-xs uppercase font-bold block pt-1 pb-4 no-underline"
			>
				Administración
			</h6>
			<!-- Navigation -->

			<ul class="md:flex-col md:min-w-full flex flex-col list-none">
				<li class="items-center">
					<a
						href="/"
						class="text-xs uppercase py-3 font-bold block {pathname === '/'
							? 'text-lime-500 hover:text-lime-600'
							: 'text-slate-700 hover:text-slate-500'}"
					>
						<i
							class="fas fa-tv mr-2 text-sm {pathname === '/' ? 'opacity-75' : 'text-slate-300'}"
						/>
						Gym
					</a>
				</li>
				<li class="items-center">
					<a
						href="/statistics"
						class="text-xs uppercase py-3 font-bold block {pathname === '/statistics'
							? 'text-lime-500 hover:text-lime-600'
							: 'text-slate-700 hover:text-slate-500'}"
					>
						<i
							class="fas fa-tv mr-2 text-sm {pathname === '/statistics'
								? 'opacity-75'
								: 'text-slate-300'}"
						/>
						Estadisticas
					</a>
				</li>

				<li class="items-center">
					<a
						href="/settings"
						class="text-xs uppercase py-3 font-bold block {pathname === '/settings'
							? 'text-lime-500 hover:text-lime-600'
							: 'text-slate-700 hover:text-slate-500'}"
					>
						<i
							class="fas fa-tools mr-2 text-sm {pathname === '/settings'
								? 'opacity-75'
								: 'text-slate-300'}"
						/>
						Ajustes
					</a>
				</li>
			</ul>

			<!-- Divider -->
			<hr class="my-4 md:min-w-full" />
			<!-- Heading -->
			<h6
				class="md:min-w-full text-slate-500 text-xs uppercase font-bold block pt-1 pb-4 no-underline"
			>
				Datos
			</h6>
			<!-- Navigation -->

			<ul class="md:flex-col md:min-w-full flex flex-col list-none md:mb-4">
				<li class="items-center">
					<a
						class="text-slate-700 hover:text-slate-500 text-xs uppercase py-3 font-bold block"
						href="/database/clients"
					>
						<i class="fas fa-users text-slate-300 mr-2 text-sm" />
						Clientes
					</a>
				</li>
				<li class="items-center">
					<a
						class="text-slate-700 hover:text-slate-500 text-xs uppercase py-3 font-bold block"
						href="/database/users"
					>
						<i class="fas fa-user text-slate-300 mr-2 text-sm" />
						Usuarios
					</a>
				</li>
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
