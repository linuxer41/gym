<script lang="ts">
	import { goto } from "$app/navigation";
	import { rpcService } from "$lib/core/services";
	import { authToken, storeUser } from "$lib/core/store";

	let email: string;
	let password: string;
 async function login() {
	try {
		const response = await rpcService.login({
			email,
			pass:password
		})
		if(!response.ok)
			throw new Error("Invalid credentials")
		const data: {user: User, token: string} = await response.json()
		authToken.sync(data.token)
		storeUser.sync(data.user)
		await goto("/")
		
	} catch (error) {
		console.log(error)
	}
}
</script>

<div class="container mx-auto px-4 h-full">
	<div class="flex content-center items-center justify-center h-full">
		<div class="w-full lg:w-4/12 px-4">
			<div
				class="relative flex flex-col min-w-0 break-words w-full mb-6 shadow-lg rounded-lg bg-stale-700 border-0"
			>
				<div class="rounded-t mb-0 px-6 py-6">
					<div class="text-center mb-3">
						<h6 class="text-stale-500 text-sm font-bold">Inicia sesión</h6>
					</div>
					<!-- <div class="btn-wrapper text-center">
              <button
                class="bg-white active:bg-stale-50 text-stale-700 font-normal px-4 py-2 rounded outline-none focus:outline-none mr-2 mb-1 uppercase shadow hover:shadow-md inline-flex items-center font-bold text-xs ease-linear transition-all duration-150"
                type="button"
              >
                <img alt="..." class="w-5 mr-1" src="{github}" />
                Github
              </button>
              <button
                class="bg-white active:bg-stale-50 text-stale-700 font-normal px-4 py-2 rounded outline-none focus:outline-none mr-1 mb-1 uppercase shadow hover:shadow-md inline-flex items-center font-bold text-xs ease-linear transition-all duration-150"
                type="button"
              >
                <img alt="..." class="w-5 mr-1" src="{google}" />
                Google
              </button>
            </div> -->
					<hr class="mt-6 border-b-1 border-stale-300" />
				</div>
				<div class="flex-auto px-4 lg:px-10 py-10 pt-0">
					<!-- <div class="text-stale-400 text-center mb-3 font-bold">
              <small> O iniciar sesión con credenciales</small>
            </div> -->
					<form>
						<div class="relative w-full mb-3">
							<label class="block uppercase text-stale-600 text-xs font-bold mb-2" for="grid-email">
								Email
							</label>
							<input
								id="grid-email"
								type="email"
								class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
								placeholder="Email"
								bind:value={email}
							/>
						</div>

						<div class="relative w-full mb-3">
							<label
								class="block uppercase text-stale-600 text-xs font-bold mb-2"
								for="grid-password"
							>
								Clave
							</label>
							<input
								id="grid-password"
								type="password"
								class="border-0 px-3 py-3 placeholder-stale-300 text-stale-600 bg-white rounded text-sm shadow focus:outline-none focus:ring w-full ease-linear transition-all duration-150"
								placeholder="Clave"
								bind:value={password}
							/>
						</div>
						<div>
							<label class="inline-flex items-center cursor-pointer">
								<input
									id="customCheckLogin"
									type="checkbox"
									class="form-checkbox border-0 rounded text-stale-700 ml-1 w-5 h-5 ease-linear transition-all duration-150"
								/>
								<span class="ml-2 text-sm font-semibold text-stale-600"> Recordar </span>
							</label>
						</div>

						<div class="text-center mt-6">
							<button
								class="bg-stale-800 text-white active:bg-stale-600 text-sm font-bold uppercase px-6 py-3 rounded shadow hover:shadow-lg outline-none focus:outline-none mr-1 mb-1 w-full ease-linear transition-all duration-150"
								type="button"
								on:click={login}
							>
								Ingresar
							</button>
						</div>
					</form>
				</div>
			</div>
			<!-- <div class="flex flex-wrap mt-6 relative">
          <div class="w-1/2">
            <a href="#pablo" on:click={(e) => e.preventDefault()} class="text-stale-200">
              <small>¿Se te olvidó tu contraseña?</small>
            </a>
          </div>
        </div> -->
		</div>
	</div>
</div>
