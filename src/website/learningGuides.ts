export type LearningGuide = {
  slug: string;
  title: string;
  shortTitle: string;
  description: string;
  image: string;
};

export const learningGuides = [
  { slug: "godot-inventory-system", title: "How to Build an Inventory System in Godot", shortTitle: "Godot Inventory System", description: "Model item data, stacking, pickup rules, and UI without tying your inventory to level objects.", image: "/docs/thumbs/inventory.png" },
  { slug: "godot-trigger-system", title: "How to Build a Trigger System in Godot", shortTitle: "Godot Trigger Systems", description: "Build reusable 3D trigger zones with Area3D, collision layers, signals, and named gameplay events.", image: "/docs/thumbs/triggers.png" },
  { slug: "interactive-objects-godot", title: "How to Make Interactive Objects in Godot", shortTitle: "Interactive Objects", description: "Choose between proximity areas, ray casts, and direct input to make doors, switches, and props react.", image: "/docs/thumbs/physics.png" },
  { slug: "dialogue-triggers-godot", title: "How to Trigger Dialogue in Godot", shortTitle: "Dialogue Triggers", description: "Keep dialogue data, trigger conditions, presentation, and gameplay effects cleanly separated.", image: "/docs/thumbs/conversations.png" },
  { slug: "animation-frame-events-godot", title: "How to Add Animation Frame Events in Godot", shortTitle: "Animation Frame Events", description: "Fire sounds, hitboxes, particles, and scene changes at exact moments in an animation.", image: "/docs/thumbs/animation.png" },
  { slug: "blender-to-godot-gameplay-import", title: "Blender to Godot: Import Gameplay with Your Scene", shortTitle: "Blender to Godot Gameplay", description: "Carry gameplay intent through glTF custom properties instead of rebuilding every object after import.", image: "/docs/thumbs/pipeline.png" },
  { slug: "godot-scene-metadata", title: "How to Use Scene Metadata in Godot", shortTitle: "Godot Scene Metadata", description: "Use metadata for authored level settings such as sky color, event IDs, spawn roles, and item kinds.", image: "/docs/thumbs/scene-settings.png" },
  { slug: "holdable-items-godot", title: "How to Make Holdable Items in Godot", shortTitle: "Holdable Items", description: "Build physics-aware pickup, carry, use, and drop behavior without letting props clip through walls.", image: "/docs/thumbs/inventory.png" },
  { slug: "build-levels-in-blender-for-godot", title: "How to Build Godot Levels in Blender", shortTitle: "Build Levels in Blender", description: "Organize transforms, collision, naming, reusable scenes, and exports for a dependable level pipeline.", image: "/docs/thumbs/sub-scene.png" },
  { slug: "instant-game-mechanics", title: "What Are Instant Game Mechanics?", shortTitle: "Instant Game Mechanics", description: "A practical workflow for authoring common gameplay while you build the level, then extending it in code.", image: "/docs/thumbs/characters.png" },
] satisfies LearningGuide[];
