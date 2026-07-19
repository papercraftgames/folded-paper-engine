const SITE_NAME = "Folded Paper Engine";
const SITE_URL = "https://foldedpaperengine.com";
const DEFAULT_OG_IMAGE_PATH = "/assets/images/web-splash.png";

type PageSeo = {
  description: string;
  image?: string;
  heading?: string;
};

const PAGE_SEO: Record<string, PageSeo> = {
  "/": {
    description:
      "Folded Paper Engine is a Blender-to-Godot addon that lets you tag gameplay in Blender, export standard GLTF or GLB scenes, and import them into Godot with gameplay behavior wired up automatically.",
    image: "/assets/images/web-splash.png",
    heading: "Instant Game Mechanics from Blender to Godot",
  },
  "/blender-panel-docs": {
    description:
      "Learn every Folded Paper Engine Blender panel, from player and trigger setup to audio, inventory, scene settings, export steps, and property reference details.",
    image: "/assets/images/blender-panel-splash.png",
  },
  "/godot-feature-docs": {
    description:
      "Set up the Folded Paper Engine Godot addon, load Blender-authored GLB or GLTF scenes, and understand the runtime features that turn imported metadata into working gameplay.",
    image: "/assets/images/godot-feature-splash.png",
  },
  "/youtube-tutorials": {
    description:
      "Watch Folded Paper Engine tutorials covering Blender-to-Godot workflows, trigger setups, runtime features, and practical level-building techniques.",
    image: "/assets/images/guide-splash.png",
  },
  "/guides": {
    description:
      "Solve real Blender-to-Godot game development problems with artist-first Folded Paper Engine guides, then explore the complete FPE feature reference.",
    image: "/assets/images/guide-splash.png",
    heading: "Blender-to-Godot Game Development Guides",
  },
  "/docs/fpe-animation-and-events": {
    description:
      "Learn how Folded Paper Engine handles Blender animations and frame events in Godot, including cutscenes, doors, VFX timing, and event-driven playback.",
    image: "/docs/thumbs/animation.png",
  },
  "/docs/fpe-audio": {
    description:
      "Configure Folded Paper Engine audio with Blender speaker settings, autoplay, looping, background music, trigger-driven playback, and practical troubleshooting tips.",
    image: "/docs/thumbs/audio.png",
  },
  "/docs/fpe-cameras": {
    description:
      "Set up player cameras, cinematic camera switching, and camera best practices for Folded Paper Engine scenes built in Blender and played in Godot.",
    image: "/docs/thumbs/cameras.png",
  },
  "/docs/fpe-characters-players-and-cameras": {
    description:
      "Understand Folded Paper Engine players, characters, NPCs, and following cameras, including first-person and third-person setup for Blender-to-Godot scenes.",
    image: "/docs/thumbs/characters.png",
  },
  "/docs/fpe-conversations": {
    description:
      "Build dialogue systems in Folded Paper Engine with conversation resources, reply progression, speaker setup, and gameplay-triggered conversations in Godot.",
    image: "/docs/thumbs/conversations.png",
  },
  "/docs/fpe-input": {
    description:
      "Review Folded Paper Engine input defaults, controller support, and advanced runtime remapping for keyboard, mouse, and gamepad-driven Godot projects.",
    image: "/docs/thumbs/input.png",
  },
  "/docs/fpe-inventory-and-holdables": {
    description:
      "Set up inventory items, holdable objects, slot-based storage, hold zones, and deposit flows in Folded Paper Engine across Blender and Godot.",
    image: "/docs/thumbs/inventory.png",
  },
  "/docs/fpe-physics-and-colliders": {
    description:
      "Learn how Folded Paper Engine maps Blender-authored physics data to Godot rigid bodies, collider generation, gravity overrides, and movement settings.",
    image: "/docs/thumbs/physics.png",
  },
  "/docs/fpe-pipeline": {
    description:
      "Follow the Folded Paper Engine runtime lifecycle from GLB import and pointer capture to feature registration, scene loading, and cleanup in Godot.",
    image: "/docs/thumbs/pipeline.png",
  },
  "/docs/fpe-scene-settings": {
    description:
      "Configure Folded Paper Engine scene settings for environment color, gravity, background music, and reusable scene events authored from Blender.",
    image: "/docs/thumbs/scene-settings.png",
  },
  "/docs/fpe-subscenes-and-levels": {
    description:
      "Use Folded Paper Engine sub-scenes and level loading for doors, hubs, streamed interiors, fade transitions, and GLB-based scene changes in Godot.",
    image: "/docs/thumbs/sub-scene.png",
  },
  "/docs/fpe-triggers-commands": {
    description:
      "Create trigger zones, scene events, and no-code command chains in Folded Paper Engine for doors, cutscenes, conversations, cameras, and level transitions.",
    image: "/docs/thumbs/triggers.png",
  },
  "/docs/fpe-troubleshooting": {
    description:
      "Fix common Folded Paper Engine issues with Blender export settings, GLB import metadata, runtime triggers, audio playback, and scene transitions.",
    image: "/docs/thumbs/troubleshooting.png",
  },
  "/docs/fpe-ui": {
    description:
      "Learn how Folded Paper Engine handles UI elements, cursors, menu interactions, overlays, and Blender-authored in-world interface objects in Godot.",
    image: "/docs/thumbs/ui-elements.png",
  },
  "/godot-api-docs": {
    description:
      "Browse the Folded Paper Engine Godot addon API reference, including classes, properties, methods, signals, and runtime helpers used by the Blender-to-Godot workflow.",
    image: "/assets/images/godot-feature-splash.png",
  },
};

function normalizePathname(pathname: string): string {
  if (!pathname || pathname === "/" || pathname === "/index.html") {
    return "/";
  }

  return pathname.replace(/\.html$/, "").replace(/\/$/, "");
}

function toTitleCase(segment: string): string {
  return segment
    .split("-")
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

export function getSiteName(): string {
  return SITE_NAME;
}

export function getDefaultOgImagePath(): string {
  return DEFAULT_OG_IMAGE_PATH;
}

export function getPageSeo(pathname: string): PageSeo | undefined {
  return PAGE_SEO[normalizePathname(pathname)];
}

export function getPageTitle(pathname: string, title: string): string {
  const normalizedPathname = normalizePathname(pathname);

  if (normalizedPathname === "/") {
    return `${title} | ${SITE_NAME}`;
  }

  if (
    normalizedPathname === "/blender-panel-docs" ||
    normalizedPathname === "/godot-feature-docs" ||
    normalizedPathname.startsWith("/docs/")
  ) {
    return `${title} | ${SITE_NAME} Documentation`;
  }

  if (normalizedPathname.startsWith("/godot-api-docs")) {
    return `${title} | ${SITE_NAME} Godot API Reference`;
  }

  return `${title} | ${SITE_NAME}`;
}

export function buildStructuredData({
  pathname,
  title,
  description,
  canonical,
  imageUrl,
}: {
  pathname: string;
  title: string;
  description: string;
  canonical: string;
  imageUrl: string;
}): object[] {
  const normalizedPathname = normalizePathname(pathname);
  const segments = normalizedPathname === "/"
    ? []
    : normalizedPathname.split("/").filter(Boolean);

  const breadcrumbItems = [
    {
      "@type": "ListItem",
      position: 1,
      name: "Home",
      item: SITE_URL,
    },
    ...segments.map((segment, index) => {
      const isLast = index === segments.length - 1;
      const itemPath = `/${segments.slice(0, index + 1).join("/")}`;

      return {
        "@type": "ListItem",
        position: index + 2,
        name: isLast ? title : toTitleCase(segment),
        item: `${SITE_URL}${itemPath}`,
      };
    }),
  ];

  const data: object[] = [
    {
      "@context": "https://schema.org",
      "@type": "WebSite",
      name: SITE_NAME,
      url: SITE_URL,
      description,
    },
    {
      "@context": "https://schema.org",
      "@type": "Organization",
      name: "Papercraft Games",
      url: "https://papercraft.games",
      sameAs: [
        "https://github.com/papercraftgames/folded-paper-engine",
        "https://www.youtube.com/@PapercraftGamesOfficial",
        "https://bsky.app/profile/papercraftgames.bsky.social",
        "https://www.facebook.com/profile.php?id=61584265860990",
        "https://www.reddit.com/user/papercraftgames",
      ],
    },
    {
      "@context": "https://schema.org",
      "@type": "WebPage",
      name: title,
      url: canonical,
      description,
      image: imageUrl,
      isPartOf: {
        "@type": "WebSite",
        name: SITE_NAME,
        url: SITE_URL,
      },
    },
  ];

  if (breadcrumbItems.length > 1) {
    data.push({
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: breadcrumbItems,
    });
  }

  if (normalizedPathname === "/") {
    data.push({
      "@context": "https://schema.org",
      "@type": "SoftwareApplication",
      name: SITE_NAME,
      applicationCategory: "GameDevelopmentApplication",
      operatingSystem: "Blender 4.4+, Godot 4.4+",
      description,
      url: SITE_URL,
      image: imageUrl,
      offers: {
        "@type": "Offer",
        price: "0",
        priceCurrency: "USD",
      },
    });
  }

  return data;
}
