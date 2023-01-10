<script lang="ts">
	// components for this layout
	import Sidebar from '$lib/components/Sidebar/Sidebar.svelte';
	import { onMount } from 'svelte';

	const backgrounds = [
		'/wallpers/john-arano-h4i9G-de7Po-unsplash.jpg',
		'/wallpers/ryan-de-hamer-WIPIAJW2-P8-unsplash.jpg',
		'/wallpers/victor-freitas-hOuJYX2K5DA-unsplash.jpg',
		'/wallpers/victor-freitas-vjkM-0m34KU-unsplash.jpg'
	];
	let backgound = backgrounds[Math.floor(Math.random() * backgrounds.length)];
	// onMount(() => {
	// 	// change background image every 10 seconds
	// 	setInterval(() => {
	// 		backgound = backgrounds[Math.floor(Math.random() * backgrounds.length)];
	// 		const el = document.getElementById('main-content');
	// 		if (el) el.style.backgroundImage = `url(${backgound})`;
	// 	}, 10000);
	// });
</script>

<div class="grid w-full h-screen grid-cols-[250px_1fr] overflow-hidden">
	<Sidebar />
	<div class="grid bg-gray-700 w-full h-full overflow-hidden" id="main-content">
		<!-- <AdminNavbar /> -->
		<slot />
	</div>
</div>

<style>
	.bg-image {
		background-image: url('/wallpers/victor-freitas-vjkM-0m34KU-unsplash.jpg');
		transition: out_image_bg 60000ms linear;
	}
	/* @keyframes change {
    from {
      background-image: url('/wallpers/victor-freitas-vjkM-0m34KU-unsplash.jpg');
    }
    to {
      background-image: url('/wallpers/victor-freitas-hOuJYX2K5DA-unsplash.jpg');
    }
  } */
	@keyframes out_image_bg {
		from {
			opacity: 1;
		}
		to {
			opacity: 0;
		}
	}
</style>
