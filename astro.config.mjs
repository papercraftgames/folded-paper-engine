// astro.config.mjs
import {defineConfig} from 'astro/config';
import react from "@astrojs/react";
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  srcDir: './src/website',
  outDir: './dist/website',
  site: 'https://foldedpaperengine.com',
  build: {
    format: "file",
  },
  integrations: [
    react(),
    sitemap({
      filter(page) {
        return !page.includes("/godot-api-docs/") && !page.includes("/docs/folded-paper-engine-guide");
      },
      serialize(item) {
        if (item.url === "https://foldedpaperengine.com/") {
          return {...item, url: "https://foldedpaperengine.com"};
        } else {
          return {
            ...item,
            url: `${item.url}.html`
          };
        }
      }
    }),
  ],
});
