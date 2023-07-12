<script lang="ts">
	import { productService, purchaseService, saleService } from '$lib/core/services';
	import { snackBar, storeUser } from '$lib/core/store';
	import { onMount } from 'svelte';
	import FormLayer from '../forms/FormLayer.svelte';
	export let type: 'sale' | 'purchase' = 'sale';
	export let title = type === 'sale' ? 'Nueva venta' : 'Nueva compra';
	let products: Product[] = [];
	let keyword = '';
	let selectedProduct: Product;

	function roundMoney(value:number, decimals = 2) {
		return Number((value || 0).toFixed(decimals));
	}

	function setEmptyCart(cart_type: 'sale' | 'purchase') {
		return {
			id: '',
			client: null,
			cart_type,
			items: []
		} as Cart
	}
	let cart = setEmptyCart(type);

	function addToCart(item: Product){
		try {
			// check if item is already in cart
			const index = cart.items.findIndex((i) => i.id === item.id);
			if (index >= 0) {
				// check stock
				if (item.stock < cart.items[index].quantity + 1) {
					throw new Error('No hay suficiente stock lara el producto: ' + item.name);
				}
				cart.items[index].quantity += 1;
			} else {
				cart.items.push({
					...item,
					quantity: 1,
					discount: 0
				});
			}
			cart = { ...cart };
		} catch (error: any) {
			snackBar.show({
				message: error.message,
				type: 'error'
			});
		}
	}

	function removeFromCart(item: Product){
		try {
			// check if item is already in cart
			const index = cart.items.findIndex((i) => i.id === item.id);
			if (index >= 0) {
				cart.items.splice(index, 1);
			}
			cart = { ...cart };
		} catch (error: any) {
			snackBar.show({
				message: error.message,
				type: 'error'
			});
		}
		
	}

	function subtractFromCart(item: Product){
		try {
			// check if item is already in cart
			const index = cart.items.findIndex((i) => i.id === item.id);
			if (index >= 0) {
				if (cart.items[index].quantity - 1 <= 0) {
					cart.items.splice(index, 1);
				} else {
					cart.items[index].quantity -= 1;
				}
			}
			cart = { ...cart };
		} catch (error: any) {
			snackBar.show({
				message: error.message,
				type: 'error'
			});
		}
	}



	async function submit() {
		try {
			if (!cart?.items.length) {
				throw new Error('No hay productos en el carrito');
			}
			let res: any;
			const data = {
				//...cart,
				client_id: cart.client?.id || null,
				user_id: $storeUser.id,
				items: cart.items.map((i) => ({
					...i,
					product_id: i.id,
					quantity: i.quantity,
					discount: i.discount
				})),
				total: roundMoney(cart.items.reduce((acc, i) => acc + i.quantity * i.price, 0))
			} as  Partial<Purchase | Sale>;
			if (type === 'purchase') {
				res = await purchaseService.create(data)
			} else {
				res = await saleService.create(data)
			}
			cart = setEmptyCart(type);
			await searchProduct();
			snackBar.show({
				message:
					type === 'purchase'
						? 'Compra registrada con exito'
						: 'Venta registrada con exito',
				type: 'success'
			});
		} catch (error: any) {
			console.debug(error);
			snackBar.show({
				message: error.message,
				type: 'error'
			});
		}
	}

	async function searchProduct() {
		try {
			selectedProduct = null as any;
			products = (
				await productService.query({
					or: [
						{
							field: 'name',
							value: keyword,
							operator: 'ilike'
						},
						{
							field: 'code',
							value: keyword,
							operator: 'eq'
						},
					],
					pageSize: 10,
					page: 0,
					orderBy: 'name',
				})
			).data;
			if (products.length > 0) {
				selectedProduct = products[0];
			}
		} catch (error: any) {
			snackBar.show({
				message: error.message,
				type: 'error'
			});
		}
	}

	onMount(async () => {
		await searchProduct();
	});
</script>

<FormLayer
	{title}
	on:confirm={async () => {
		await submit();
	}}
	on:close
	hasConfirm={false}
>
<div class="h-full">
	<div class="flex h-full">
	  <!-- Parte izquierda - Listado de productos -->
	  <div class="w-3/5 pr-4 border-r border-gray-300">
		<div class="flex justify-between items-center mb-4">
		  <h2 class="text-2xl font-bold">Listado de productos</h2>
		  <input type="text" class="border border-gray-300 rounded px-4 py-2" placeholder="Buscar producto"
		  bind:value={keyword}
		  on:keyup={async () => {
			  await searchProduct();
		  }} 
		 
		  >
		</div>
		<table class="min-w-full border border-gray-300">
		  <thead>
			<tr>
			  <th class="py-2 px-4 bg-gray-200 font-semibold text-left">Producto</th>
			  <th class="py-2 px-4 bg-gray-200 font-semibold text-left">Precio</th>
			  <th class="py-2 px-4 bg-gray-200 font-semibold text-left">Stock</th>
			  <th class="py-2 px-4 bg-gray-200 font-semibold text-left">Acciones</th>
			</tr>
		  </thead>
		  <tbody>
			{#each products as product}
			<tr>
				<td class="py-2 px-4">{product.name}</td>
				<td class="py-2 px-4">{roundMoney(product.stock)}</td>
				<td class="py-2 px-4">${roundMoney(product.price)}</td>
				<td class="py-2 px-4">
				  <button class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-4 rounded"
					on:click={() => addToCart(product)}
				  >Agregar al carrito</button>
				</td>
			  </tr>
			{/each}
		  </tbody>
		</table>
	  </div>
  
	  <!-- Parte derecha - Carrito de compras -->
	  <div class="w-2/5 ml-4">
		<div class="flex justify-between items-center mb-4">
		  <h2 class="text-2xl font-bold">Carrito de compras</h2>
		  <button class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-4 rounded"
			on:click={submit}
		  >
		{#if type==='purchase'}
			Registrar compra
		{:else}
			Registrar venta
		{/if}
		</button>
		</div>
		<div class="w-full">
			{#if cart.items.length}
			<table class="min-w-full divide-y divide-gray-200">
				<thead class="bg-gray-50">
					<tr>
					<th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
						Nombre
					</th>
					<th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
						Cantidad
					</th>
					<th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
						Precio
					</th>
					</tr>
				</thead>
				<tbody class="bg-white divide-y divide-gray-200">
					{#each cart.items as item}
					<tr>
					<td class="px-6 py-4 whitespace-nowrap">
						<div class="flex items-center">
						<div class="text-sm text-gray-900">{item.name}</div>
						</div>
					</td>
					<td class="px-6 py-4 whitespace-nowrap">
						<div class="flex items-center">
						<button class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-1 px-2 rounded mr-2"
							on:click={() => addToCart(item)}>
							<i class="fas fa-plus"></i>
						</button>
						<span class="text-sm text-gray-900">{item.quantity}</span>
						<button class="bg-red-500 hover:bg-red-600 text-white font-semibold py-1 px-2 rounded ml-2"
							on:click={() => subtractFromCart(item)}>
							<i class="fas fa-minus"></i>
						</button>
						<button class="bg-red-500 hover:bg-red-600 text-white font-semibold py-1 px-2 rounded ml-2"
							on:click={() => removeFromCart(item)}>
							<i class="fas fa-trash-alt"></i>
						</button>
						</div>
					</td>
					<td class="px-6 py-4 whitespace-nowrap">
						<div class="text-sm text-gray-900">${roundMoney(item.quantity * item.price)}</div>
					</td>
					</tr>
					{/each}
				</tbody>
			</table>
			{:else}
			<div class="text-center text-gray-500">No hay productos en el carrito</div>
			{/if}
		</div>
		<div class="border-t border-gray-300 mt-4 pt-4">
		  <div class="flex justify-between">
			<span>Subtotal:</span>
			<span>$
				{
				roundMoney(cart.items.reduce((acc, item) => acc + item.quantity * item.price, 0))
				}
			</span>
		  </div>
		  <div class="flex justify-between">
			<span>Impuestos:</span>
			<span>$0.00</span>
		  </div>
		  <div class="flex justify-between font-semibold">
			<span>Total:</span>
			<span>$
				{
				roundMoney(cart.items.reduce((acc, item) => acc + item.quantity * item.price, 0))
				}
			</span>
		  </div>
		</div>
	  </div>
	</div>
  </div>
  
</FormLayer>
