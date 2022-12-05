<script>
	// components for this layout
	import FooterSmall from '$lib/components/Footers/FooterSmall.svelte';

	// pages for this layout
	// import Login from "views/auth/Login.svelte";
	// import Register from "views/auth/Register.svelte";

	const registerBg2 = '../assets/img/register_bg_2.png';
</script>

<div>
	<main>
		<section class="relative w-full h-full py-40 min-h-screen">
			<div
				class="absolute top-0 w-full h-full bg-slate-800 bg-no-repeat bg-full"
				style="background-image: url({registerBg2});"
			/>
			<slot />
			<FooterSmall absolute={true} />
		</section>
	</main>
</div>
