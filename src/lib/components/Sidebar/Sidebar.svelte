<script lang="ts">
	import { page } from '$app/stores';

	// core components
	import NotificationDropdown from '$lib/components/Dropdowns/NotificationDropdown.svelte';
	import UserDropdown from '$lib/components/Dropdowns/UserDropdown.svelte';

	let collapseShow = 'hidden';

	function toggleCollapseShow(classes: string) {
		collapseShow = classes;
	}

	$: pathname = $page.url.pathname;
	const logo = '/logos/endor-logo.jpg';
</script>

<nav
	class="shadow-xl bg-white flex flex-wrap items-center justify-between relative w-full z-10 py-4 px-6"
>
	<div
		class="md:flex-col md:items-stretch md:min-h-full md:flex-nowrap px-0 flex flex-wrap items-center justify-between w-full mx-auto"
	>
		<!-- Toggler -->
		<button
			class="cursor-pointer text-black opacity-50 md:hidden px-3 py-1 text-xl leading-none bg-transparent rounded border border-solid border-transparent"
			type="button"
			on:click={() => toggleCollapseShow('bg-white m-2 py-3 px-6')}
		>
			<i class="fas fa-bars" />
		</button>
		<!-- Brand -->
		<a
			class="md:block text-left md:pb-2 text-stale-600 mr-0 inline-block whitespace-nowrap text-sm uppercase font-bold p-4 px-0"
			href="/"
		>
			<img class="w-40" src={logo} alt="" />
		</a>
		<!-- User -->
		<ul class="md:hidden items-center flex flex-wrap list-none">
			<li class="inline-block relative">
				<NotificationDropdown />
			</li>
			<li class="inline-block relative">
				<UserDropdown />
			</li>
		</ul>
		<!-- Collapse -->
		<div
			class="md:flex md:flex-col md:items-stretch md:opacity-100 md:relative md:mt-4 md:shadow-none shadow absolute top-0 left-0 right-0 z-40 overflow-y-auto overflow-x-hidden h-auto items-center flex-1 rounded {collapseShow}"
		>
			<!-- Collapse header -->
			<div class="md:min-w-full md:hidden block pb-4 mb-4 border-b border-solid border-stale-200">
				<div class="flex flex-wrap">
					<div class="w-6/12 h-12">
						<a
							class="md:block text-left md:pb-2 text-stale-600 mr-0 inline-block whitespace-nowrap text-sm uppercase font-bold p-4 px-0"
							href="/"
						>
							<img src={logo} alt="" />
						</a>
					</div>
					<div class="w-6/12 flex justify-end">
						<button
							type="button"
							class="cursor-pointer text-black opacity-50 md:hidden px-3 py-1 text-xl leading-none bg-transparent rounded border border-solid border-transparent"
							on:click={() => toggleCollapseShow('hidden')}
						>
							<i class="fas fa-times" />
						</button>
					</div>
				</div>
			</div>
			<!-- Form -->
			<form class="mt-6 mb-4 md:hidden">
				<div class="mb-3 pt-0">
					<input
						type="text"
						placeholder="Search"
						class="border-0 px-3 py-2 h-12 border border-solid border-stale-500 placeholder-stale-300 text-stale-600 bg-white rounded text-base leading-snug shadow-none outline-none focus:outline-none w-full font-normal"
					/>
				</div>
			</form>

			<!-- Divider -->
			<hr class="my-4 md:min-w-full" />
			<!-- Heading -->
			<h6
				class="md:min-w-full text-stale-500 text-xs uppercase font-bold block pt-1 pb-4 no-underline"
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
							: 'text-stale-700 hover:text-stale-500'}"
					>
						<i
							class="fas fa-tv mr-2 text-sm {pathname === '/' ? 'opacity-75' : 'text-stale-300'}"
						/>
						Gym
					</a>
				</li>
				<li class="items-center">
					<a
						href="/permissions"
						class="text-xs uppercase py-3 font-bold block {pathname === '/permissions'
							? 'text-lime-500 hover:text-lime-600'
							: 'text-stale-700 hover:text-stale-500'}"
					>
						<i
							class="fas fa-tv mr-2 text-sm {pathname === '/permissions'
								? 'opacity-75'
								: 'text-stale-300'}"
						/>
						Estadisticas
					</a>
				</li>

				<li class="items-center">
					<a
						href="/settings"
						class="text-xs uppercase py-3 font-bold block {pathname === '/settings'
							? 'text-lime-500 hover:text-lime-600'
							: 'text-stale-700 hover:text-stale-500'}"
					>
						<i
							class="fas fa-tools mr-2 text-sm {pathname === '/settings'
								? 'opacity-75'
								: 'text-stale-300'}"
						/>
						Ajustes
					</a>
				</li>

				<!-- <li class="items-center">
          <a
            href="/tables"
            class="text-xs uppercase py-3 font-bold block {pathname === '/tables' ? 'text-lime-500 hover:text-lime-600':'text-stale-700 hover:text-stale-500'}"
          >
            <i
              class="fas fa-table mr-2 text-sm {pathname === '/tables' ? 'opacity-75' : 'text-stale-300'}"
            ></i>
            Tables
          </a>
        </li>

        <li class="items-center">
          <a
            
            href="/maps"
            class="text-xs uppercase py-3 font-bold block {pathname === '/maps' ? 'text-lime-500 hover:text-lime-600':'text-stale-700 hover:text-stale-500'}"
          >
            <i
              class="fas fa-map-marked mr-2 text-sm {pathname === '/maps' ? 'opacity-75' : 'text-stale-300'}"
            ></i>
            Maps
          </a>
        </li> -->
			</ul>

			<!-- Divider -->
			<hr class="my-4 md:min-w-full" />
			<!-- Heading -->
			<h6
				class="md:min-w-full text-stale-500 text-xs uppercase font-bold block pt-1 pb-4 no-underline"
			>
				Datos
			</h6>
			<!-- Navigation -->

			<ul class="md:flex-col md:min-w-full flex flex-col list-none md:mb-4">
				<li class="items-center">
					<a
						class="text-stale-700 hover:text-stale-500 text-xs uppercase py-3 font-bold block"
						href="/database/clients"
					>
						<i class="fas fa-users text-stale-300 mr-2 text-sm" />
						Clientes
					</a>
				</li>
				<li class="items-center">
					<a
						class="text-stale-700 hover:text-stale-500 text-xs uppercase py-3 font-bold block"
						href="/database/users"
					>
						<i class="fas fa-user text-stale-300 mr-2 text-sm" />
						Usuarios
					</a>
				</li>

				<!-- <li class="items-center">
          <a
            
            class="text-stale-700 hover:text-stale-500 text-xs uppercase py-3 font-bold block"
            href="/database/plans"
          >
            <i class="fas fa-clipboard-list text-stale-300 mr-2 text-sm"></i>
            Planes
          </a>
        </li>
        <li class="items-center">
          <a
            
            class="text-stale-700 hover:text-stale-500 text-xs uppercase py-3 font-bold block"
            href="/database/memberships"
          >
            <i class="fas fa-clipboard-list text-stale-300 mr-2 text-sm"></i>
            Menbresias
          </a>
        </li> -->
			</ul>
		</div>
	</div>
</nav>
