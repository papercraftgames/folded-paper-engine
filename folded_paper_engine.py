import bpy
import os
from pathlib import Path
from bpy_extras.io_utils import ImportHelper 
from bpy.types import Operator, OperatorFileListElement
from bpy.props import CollectionProperty, StringProperty
bl_info = {
    "name": "Folded Paper Engine",
    "author": "Papercraft Games",
    "description": "",
    "blender": (4, 4, 0),
    "version": (0, 0, 10),
    "location": "",
    "warning": ""
}
def item_to_dict(item):
    return {attr: getattr(item, attr) for attr in dir(item) if not callable(getattr(item, attr)) and not attr.startswith("__")}
def add_keyframe_to_channel(obj, prop_name, frame, value):
    # Add or update the property value
    obj[prop_name] = value
    # Ensure the action exists
    if not obj.animation_data:
        obj.animation_data_create()
    if not obj.animation_data.action:
        obj.animation_data.action = bpy.data.actions.new(obj.name + "Action")
    # Find or create the specific fcurve for this property
    fcurve = next((fc for fc in obj.animation_data.action.fcurves if fc.data_path == f'["{prop_name}"]'), None)
    if not fcurve:
        fcurve = obj.animation_data.action.fcurves.new(data_path='["' + prop_name + '"]')
        fcurve.lock = True
    # Insert or update the keyframe
    keyframe = next((k for k in fcurve.keyframe_points if k.co[0] == frame), None)
    if keyframe:
        keyframe.co[1] = value
    else:
        fcurve.keyframe_points.insert(frame, value)
def remove_keyframe_from_channel(obj, prop_name, frame):
    # Find the specific fcurve for this property
    fcurve = next((fc for fc in obj.animation_data.action.fcurves if fc.data_path == f'["{prop_name}"]'), None)
    if fcurve:
        # Find and remove the specific keyframe
        keyframe_index = next((i for i, k in enumerate(fcurve.keyframe_points) if k.co[0] == float(frame)), None)
        if keyframe_index is not None:
            fcurve.keyframe_points.remove(fcurve.keyframe_points[keyframe_index])
def is_bpy_prop_collection(obj):
    return hasattr(obj, "add") and hasattr(obj, "remove")
def split_path(path):
    return path.split('.')
def get_value_by_path(obj, path):
    parts = split_path(path)
    for part in parts[:-1]:
        if obj is None:
            return None  # Prevents errors when encountering None
        if is_bpy_prop_collection(obj):
            obj = obj[int(part)]
        else:
            obj = getattr(obj, part, None)  # Avoids crashing on missing attributes
    if obj is None:
        return None
    if is_bpy_prop_collection(obj):
        return obj[int(parts[-1])] if int(parts[-1]) < len(obj) else None
    else:
        return getattr(obj, parts[-1], None)
def set_value_by_path(obj, path, value):
    parts = split_path(path)
    for part in parts[:-1]:
        if is_bpy_prop_collection(obj):
            obj = obj[int(part)]
        else:
            obj = getattr(obj, part)
    if is_bpy_prop_collection(obj):
        obj[int(parts[-1])] = value
    else:
        setattr(obj, parts[-1], value)
def get_frame_number():
    try:
        action = bpy.context.object.animation_data.action
        groups = action.groups
        for g in groups:
            for c in g.channels:
                if c.select:
                    for k in c.keyframe_points:
                        if k.select_control_point:
                            return k.co[0]
    except:
        return 0
def find_file_upwards(starting_path, target_file):
    current_path = os.path.abspath(starting_path)
    while True:
        file_path = os.path.join(current_path, target_file)
        if os.path.isfile(file_path):
            relative_path = os.path.relpath(starting_path, current_path)
            return relative_path
        # Move one level up in the directory hierarchy
        current_path = os.path.dirname(current_path)
        # Check if we have reached the root directory
        if current_path == os.path.dirname(current_path):
            break
    return None
def do_redraw_all():
    for area in bpy.context.screen.areas:
        area.tag_redraw()
class DefaultsPropertyGroup(bpy.types.PropertyGroup):
    key: bpy.props.StringProperty()
    value: bpy.props.StringProperty()
    value_is_function: bpy.props.BoolProperty()
class AddItemOperator(Operator):
    bl_idname = "folded_paper_engine.add_item_operator"
    bl_label = "Add Item"
    bl_description = "Add an item"
    defaults: bpy.props.CollectionProperty(type=DefaultsPropertyGroup)
    context_object_path: bpy.props.StringProperty()
    prop_name: bpy.props.StringProperty()
    on_add: bpy.props.StringProperty()
    context_base: bpy.props.StringProperty()
    def execute(self, context):
        context_base = getattr(context, self.context_base) if self.context_base else context.object
        context_object = get_value_by_path(context_base, self.context_object_path)
        prop = getattr(context_object, self.prop_name)
        item = prop.add()
        if self.defaults:
            for default in self.defaults:
                key = default.key
                if default.value_is_function:
                    value = eval(default.value)
                else:
                    value = default.value
                setattr(item, key, value)
        if self.on_add:
            eval(self.on_add)
        do_redraw_all()
        return {'FINISHED'}
class RemoveItemOperator(Operator):
    bl_idname = "folded_paper_engine.remove_item_operator"
    bl_label = "Remove Item"
    bl_description = "Remove an item"
    context_object_path: bpy.props.StringProperty()
    prop_name: bpy.props.StringProperty()
    item_index: bpy.props.IntProperty()
    on_remove: bpy.props.StringProperty()
    context_base: bpy.props.StringProperty()
    def execute(self, context):
        context_base = getattr(context, self.context_base) if self.context_base else context.object
        context_object = get_value_by_path(context_base, self.context_object_path)
        prop = getattr(context_object, self.prop_name)
        item = item_to_dict(prop[self.item_index])
        prop.remove(self.item_index)
        if self.on_remove:
            eval(self.on_remove)
        do_redraw_all()
        return {'FINISHED'}
class FileBrowserItem(bpy.types.PropertyGroup):
    path: bpy.props.StringProperty(name="Path", subtype="FILE_PATH")
class FileBrowserOperator(Operator, ImportHelper):
    bl_idname = "folded_paper_engine.file_browser_operator"
    bl_label = "Select"
    bl_description = "Browse for a file or files"
    directory : StringProperty(subtype='DIR_PATH')
    files : CollectionProperty(type=OperatorFileListElement)
    # Properties
    context_object_path: bpy.props.StringProperty()
    prop_name: bpy.props.StringProperty()
    context_base: bpy.props.StringProperty()
    description: bpy.props.StringProperty()
    multiple: bpy.props.BoolProperty(default=False)
    # Only accept the designated file types/extensions
    filename_ext = ""
    filter_glob: bpy.props.StringProperty(
        default="",
        options={'HIDDEN'},
    )
    @classmethod
    def description(cls, context, properties):
        specific_description = properties.description if properties.description else cls.bl_description
        return specific_description
    def execute(self, context):
        # Get the property group
        context_base = getattr(context, self.context_base) if self.context_base else context.object
        prop_group = get_value_by_path(context_base, self.context_object_path)
        base = Path(self.directory)
        target_file = 'project.godot'
        result = find_file_upwards(base, target_file)
        target_base = result
        if result:
            target_base = f'res://{result}'
        else:
            target_base = 'res://'
        if self.multiple:
            # Get the collection property
            collection_prop = getattr(prop_group, self.prop_name)
            for fi in self.files:
                fbi = collection_prop.add()
                fbi.path = f'{target_base}/{fi.name}'
        else:
            # Get the string property
            setattr(prop_group, self.prop_name, f'{target_base}/{self.files[0].name}')
        # Call the redraw function
        do_redraw_all()
        return {'FINISHED'}
class ClearValueOperator(bpy.types.Operator):
    bl_idname = "folded_paper_engine.clear_value_operator"
    bl_label = "Clear Value"
    bl_description = "Clear the value"
    context_object_path: bpy.props.StringProperty() 
    prop_name: bpy.props.StringProperty()
    context_base: bpy.props.StringProperty()
    def execute(self, context):
        try:
            context_base = getattr(context, self.context_base) if self.context_base else context.object
            context_object = get_value_by_path(context_base, self.context_object_path)
            del context_object[self.prop_name]
        except:
            pass
        do_redraw_all()
        return {'FINISHED'}
class ACTIVITY_TYPES_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    ActivityType: bpy.props.EnumProperty(
    name="Activity Type",
    description="The type of activity",
    default='ALL',
    items=[
        ("ALL", "All", "All activities"),
        ("UI_CONTROLS", "UI Controls", "User interface control activities"),
        ("PLAYER_CONTROLS", "Player Controls", "Player control activities"),
        ("CHARACTER_MOVEMENT", "Character Movement", "Character movement activities"),
        ("TRIGGERS", "Triggers", "Trigger activities"),
        ("ANIMATIONS", "Animations", "Animation activities"),
        ("SOUNDS", "Sounds", "Sound activities"),
        ("BACKGROUND_MUSIC", "Background Music", "Background music activities"),
        ("PHYSICS", "Physics", "Physics activities"),
        ("SPRITE_ANIMATIONS", "Sprite Animations", "Sprite animation activities")
    ]
    )
class EVENT_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    EventName: bpy.props.StringProperty(
    name="Event Name",
    description="The name of the event"
    )
class VIEW3D_PT_SCENE_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    SkyColor: bpy.props.FloatVectorProperty(
    name="Sky Color",
    description="Select the sky color for the scene",
    subtype='COLOR', size=4, default=(1.0, 1.0, 1.0, 1.0), min=0.0, max=1.0
    )
    BackgroundMusic: bpy.props.CollectionProperty(
    name="Background Music",
    description="Select the background music for the scene",
    type=FileBrowserItem
    )
    BackgroundMusicVolume: bpy.props.FloatProperty(
    name="Background Music Volume",
    description="The volume of the background music in decibels",
    default=-10
    )
    Gravity: bpy.props.FloatProperty(
    name="Gravity",
    description="The gravity of the scene in meters per second squared",
    default=20
    )
    SceneLoadEvents: bpy.props.CollectionProperty(
    name="Scene Load Events",
    description="Execute commands when the scene is loaded",
    type=EVENT_PT_FoldedPaperEnginePropertyGroup
    )
    SceneUnloadEvents: bpy.props.CollectionProperty(
    name="Scene Unload Events",
    description="Execute commands when the scene is unloaded",
    type=EVENT_PT_FoldedPaperEnginePropertyGroup
    )
class VIEW3D_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    Player: bpy.props.BoolProperty(
    name="Player",
    description="Create a player",
    default=False
    )
    Character: bpy.props.BoolProperty(
    name="Character",
    description="Create a character",
    default=False
    )
    Physics: bpy.props.BoolProperty(
    name="Physics",
    description="Apply physics to this object",
    default=False
    )
    Invisible: bpy.props.BoolProperty(
    name="Invisible",
    description="Set to true to make the object invisible",
    default=False
    )
    Water: bpy.props.BoolProperty(
    name="Water",
    description="Set to true to make the object a water plane",
    default=False
    )
    SpriteAnimate: bpy.props.FloatProperty(
    name="Sprite Animate",
    description="Set the sprite animation speed. All child node will be cycled through to create a sprite animation",
    default=0
    )
    Trigger: bpy.props.BoolProperty(
    name="Trigger",
    description="Set to true to trigger the configured commands (from the command palette) on interaction"
    )
    Speaker: bpy.props.BoolProperty(
    name="Speaker",
    description="Make this item a 3D speaker"
    )
    UIElement: bpy.props.BoolProperty(
    name="UI Element",
    description="Make this item a UI element"
    )
    SubScene: bpy.props.BoolProperty(
    name="Sub Scene",
    description="Load a sub scene in this item"
    )
    Holdable: bpy.props.BoolProperty(
    name="Holdable",
    description="Make this item holdable"
    )
    Groups: bpy.props.StringProperty(
    name="Groups",
    description="CSV: The groups for this item. Used in your own custom code"
    )
    ScriptPath: bpy.props.StringProperty(
    name="Script Path",
    description="Set the script for this item. WARNING: Only use this if you know what you are doing, this will overwrite any existing script/functionality"
    )
class COMMANDS_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    DispatchEvent: bpy.props.StringProperty(
    name="Dispatch Event",
    description="The name of the event to dispatch"
    )
    LoadLevel: bpy.props.StringProperty(
    name="Load Level",
    description="Load a level on trigger"
    )
    Animations: bpy.props.StringProperty(
    name="Animations",
    description="CSV: Play animations on trigger"
    )
    StopAnimations: bpy.props.StringProperty(
    name="Stop Animations",
    description="CSV: Stop animations on trigger"
    )
    SpeakerTrigger: bpy.props.StringProperty(
    name="Speaker Trigger",
    description="True to play this item as a speaker when intersecting with it. Or the name of a specific speaker to play"
    )
    SpeakerTriggerSelf: bpy.props.BoolProperty(
    name="Speaker Trigger Self",
    description="Play this item as a speaker when intersecting with it"
    )
    ActivateCamera: bpy.props.StringProperty(
    name="Activate Camera",
    description="Activate the selected camera"
    )
    ReactivatePlayerCamera: bpy.props.BoolProperty(
    name="Reactivate Player Camera",
    description="Reactivate the player's camera"
    )
    DeactivatePlayerControls: bpy.props.BoolProperty(
    name="Deactivate Player Controls",
    description="Deactivate the player's controls"
    )
    ReactivatePlayerControls: bpy.props.BoolProperty(
    name="Reactivate Player Controls",
    description="Reactivate the player's controls"
    )
    LoadSubScene: bpy.props.StringProperty(
    name="Load Sub Scene",
    description="Load a specific sub scene by item name"
    )
    UnloadSubScene: bpy.props.StringProperty(
    name="Unload Sub Scene",
    description="Unload a specific sub scene by item name"
    )
    UnloadThisSubScene: bpy.props.BoolProperty(
    name="Unload This Sub Scene",
    description="Unload this scene as a sub scene"
    )
    StartConversation: bpy.props.CollectionProperty(
    name="Start Conversation",
    description="Start one of the specified conversations. The conversation is selected by the names of the characters involved and the required characters list in the conversation",
    type=FileBrowserItem
    )
    PauseSpecificActivities: bpy.props.CollectionProperty(
    name="Pause Specific Activities",
    description="Pause the specified game activities",
    type=ACTIVITY_TYPES_PT_FoldedPaperEnginePropertyGroup
    )
    ResumeSpecificActivities: bpy.props.CollectionProperty(
    name="Resume Specific Activities",
    description="Resume the specified game activities",
    type=ACTIVITY_TYPES_PT_FoldedPaperEnginePropertyGroup
    )
    DeleteByGroup: bpy.props.StringProperty(
    name="Delete By Group",
    description="Delete items in the specified group"
    )
class SCENE_EVENT_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    EventName: bpy.props.StringProperty(
    name="Event Name",
    description="The name of the event"
    )
    Commands: bpy.props.PointerProperty(
    name="Commands",
    description="The commands to execute when the event occurs",
    type=COMMANDS_PT_FoldedPaperEnginePropertyGroup
    )
class TRIGGER_EVENT_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    TriggerType: bpy.props.EnumProperty(
    name="Trigger Type",
    description="The type of trigger (When/why the event is triggered)",
    default='ENTER',
    items=[
        ("ENTER", "Enter", "Triggered when a character, player, trigger or cursor enters the trigger"),
        ("EXIT", "Exit", "Triggered when a character, player, trigger or cursor exits the trigger"),
        ("INTERACTION", "Interaction", "Triggered when a player or cursor interacts with the trigger"),
        ("DEPOSIT", "Deposit", "Triggered when a player deposits an item into the trigger"),
        ("WITHDRAW", "Withdraw", "Triggered when a player withdraws an item from the trigger"),
        ("HOLD", "Hold", "Triggered when a player holds an item"),
        ("RELEASE", "Release", "Triggered when a player releases an item"),
        ("HOLDABLE_ITEMS_AVAILABLE", "Holdable Items Available", "Triggered when a player has available holdable items"),
        ("HOLDABLE_ITEMS_UNAVAILABLE", "Holdable Items Unavailable", "Triggered when a player no longer has available holdable items"),
        ("HOLD_ZONE_INTERACTION", "Hold Zone Interaction", "Triggered when a player's hold zone interacts with the trigger")
    ]
    )
    EventName: bpy.props.StringProperty(
    name="Event Name",
    description="The name of the event"
    )
class FRAME_EVENT_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    FrameNumber: bpy.props.IntProperty(
    name="Frame Number",
    description="Frame number for the command"
    )
    FrameTime: bpy.props.FloatProperty(
    name="Frame Time",
    description="Frame time for the command"
    )
    EventName: bpy.props.StringProperty(
    name="Event Name",
    description="The name of the event"
    )
class VIEW3D_PT_SCENE_EVENTS_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    SceneEvents: bpy.props.CollectionProperty(
    name="Scene Events",
    description="Execute commands when a scene event occurs",
    type=SCENE_EVENT_PT_FoldedPaperEnginePropertyGroup
    )
class VIEW3D_TRIGGER_EVENTS_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    TriggerGroups: bpy.props.StringProperty(
    name="Trigger Groups",
    description="The trigger groups for this item"
    )
    TriggerEvents: bpy.props.CollectionProperty(
    name="Trigger Events",
    description="The Scene Events that will be triggered when this item is a trigger",
    type=TRIGGER_EVENT_PT_FoldedPaperEnginePropertyGroup
    )
class VIEW3D_INVENTORY_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    InventoryItemKind: bpy.props.StringProperty(
    name="Inventory Item Kind",
    description="The Inventory Item Kind"
    )
    InventoryItemQuantity: bpy.props.IntProperty(
    name="Inventory Item Quantity",
    description="The Inventory Item Quantity"
    )
class VIEW3D_SPEAKER_SETTINGS_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    SpeakerFile: bpy.props.StringProperty(
    name="Speaker File",
    description="Path to the audio file for this speaker"
    )
    SpeakerLoop: bpy.props.BoolProperty(
    name="Speaker Loop",
    description="Loop the speaker audio"
    )
    SpeakerVolume: bpy.props.FloatProperty(
    name="Speaker Volume",
    description="Volume of the speaker in decibels",
    default=20
    )
    SpeakerMaxDistance: bpy.props.FloatProperty(
    name="Speaker Max Distance",
    description="Maximum distance for the speaker to be heard",
    default=100
    )
    SpeakerAutoplay: bpy.props.BoolProperty(
    name="Speaker Autoplay",
    description="Autoplay the speaker audio immediately"
    )
class VIEW3D_CHARACTER_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    WalkSpeedMultiplier: bpy.props.FloatProperty(
    name="Walk Speed Multiplier",
    description="A multiplier for the character's walk speed",
    default=1
    )
    RunSpeedMultiplier: bpy.props.FloatProperty(
    name="Run Speed Multiplier",
    description="A multiplier for the character's run speed (Which is already affected by the Walk Speed Multiplier)",
    default=1
    )
    JumpForceMultiplier: bpy.props.FloatProperty(
    name="Jump Force Multiplier",
    description="A multiplier for the character's jump force",
    default=1
    )
    IdleAnimation: bpy.props.StringProperty(
    name="Idle Animation",
    description="The name of the idle animation"
    )
    WalkAnimation: bpy.props.StringProperty(
    name="Walk Animation",
    description="The name of the walk animation"
    )
    RunAnimation: bpy.props.StringProperty(
    name="Run Animation",
    description="The name of the run animation"
    )
    JumpAnimation: bpy.props.StringProperty(
    name="Jump Animation",
    description="The name of the jump animation"
    )
    TalkAnimation: bpy.props.StringProperty(
    name="Talk Animation",
    description="The name of the talk animation"
    )
    WanderingBounds: bpy.props.StringProperty(
    name="Wandering Bounds",
    description="The object representing the area where the character can wander"
    )
    FaceMotionDirection: bpy.props.BoolProperty(
    name="Face Motion Direction",
    description="Face the motion direction"
    )
class VIEW3D_PHYSICS_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    Mass: bpy.props.FloatProperty(
    name="Mass",
    description="Set the collision object mass",
    default=1
    )
    Friction: bpy.props.FloatProperty(
    name="Friction",
    description="Set the collision object friction",
    default=0,
    min=0.0, max=1.0
    )
    Bounciness: bpy.props.FloatProperty(
    name="Bounciness",
    description="Set the collision object bounciness",
    default=0,
    min=0.0, max=1.0
    )
    ContinuousCollisionDetection: bpy.props.BoolProperty(
    name="Continuous Collision Detection",
    description="Enable continuous collision detection"
    )
class DOPESHEET_EDITOR_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    Autoplay: bpy.props.BoolProperty(
    name="Autoplay",
    description="Set to true to play this animation automatically",
    default=False
    )
    Loop: bpy.props.BoolProperty(
    name="Loop",
    description="Set to true to loop this animation",
    default=False
    )
class DOPESHEET_EDITOR_FRAME_EVT_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    FrameEvents: bpy.props.CollectionProperty(
    name="Frame Events",
    description="Frames that trigger events",
    type=FRAME_EVENT_PT_FoldedPaperEnginePropertyGroup
    )
class MATERIAL_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    RenderPriority: bpy.props.IntProperty(
    name="Render Priority",
    description="Set the render priority for this material",
    default=0
    )
    Reflective: bpy.props.FloatProperty(
    name="Reflective",
    description="Set the reflectivity of this material",
    default=0,
    min=0.0, max=1.0
    )
    ReplaceWithMaterial: bpy.props.StringProperty(
    name="Replace With Material",
    description="Replace this material with the specified material"
    )
class VIEW3D_UI_ELEMENT_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    UICursor: bpy.props.BoolProperty(
    name="UI Cursor",
    description="Make this item a UI cursor"
    )
    UICursorDepth: bpy.props.FloatProperty(
    name="UI Cursor Depth",
    description="Set the UI cursor depth",
    default=10
    )
    UICursorSelectAnimation: bpy.props.StringProperty(
    name="UI Cursor Select Animation",
    description="The name of the UI cursor select animation"
    )
    UICursorLookAtCamera: bpy.props.BoolProperty(
    name="UI Cursor Look At Camera",
    description="Make the UI cursor always look at the camera"
    )
    UIOption: bpy.props.BoolProperty(
    name="UI Option",
    description="Make this item a UI option"
    )
    UIOptionCommandDelay: bpy.props.FloatProperty(
    name="UI Option Command Delay",
    description="Set the UI option command delay in milliseconds",
    default=0
    )
class VIEW3D_SUB_SCENE_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    SceneFile: bpy.props.StringProperty(
    name="Scene File",
    description="Path to the scene file for this sub scene"
    )
    AutoLoad: bpy.props.BoolProperty(
    name="Auto Load",
    description="Automatically load the sub scene when the parent scene loads"
    )
    Pause: bpy.props.BoolProperty(
    name="Pause",
    description="Pause the parent scene when the sub scene is loaded"
    )
    ResumeOnUnload: bpy.props.BoolProperty(
    name="Resume On Unload",
    description="Resume the parent scene when the sub scene is unloaded"
    )
    UnloadDelay: bpy.props.FloatProperty(
    name="Unload Delay",
    description="Delay in milliseconds before unloading the sub scene",
    default=0
    )
class VIEW3D_PLAYER_CONTROLS_PT_FoldedPaperEnginePropertyGroup(bpy.types.PropertyGroup):
    FPE_INTERNAL_EXPANDED: bpy.props.BoolProperty(
    name="Expanded",
    description="Whether the group is expanded or not",
    default=False
    )
    ThirdPerson: bpy.props.BoolProperty(
    name="Third Person",
    description="Enable full third person controls"
    )
    FirstPerson: bpy.props.BoolProperty(
    name="First Person",
    description="Enable first person controls"
    )
    CanHoldItems: bpy.props.BoolProperty(
    name="Can Hold Items",
    description="Enable holding items"
    )
    HoldZoneDistance: bpy.props.FloatProperty(
    name="Hold Zone Distance",
    description="The distance from the player to the area where items can/will be held",
    default=1
    )
    HoldZoneSize: bpy.props.FloatProperty(
    name="Hold Zone Size",
    description="The size of the area where items can/will be held",
    default=0.25
    )
    HoldZoneScene: bpy.props.StringProperty(
    name="Hold Zone Scene",
    description="A scene to load into the player\'s hold zone. The parent of this scene will be a `HoldZone` with holdable item related signals"
    )
    StandardCameraHeight: bpy.props.FloatProperty(
    name="Standard Camera Height",
    description="The standard height of the camera",
    default=1.5
    )
    StandardCameraDistance: bpy.props.FloatProperty(
    name="Standard Camera Distance",
    description="The standard distance of the camera",
    default=3
    )
class VIEW3D_PT_SCENE_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'Scene'
    bl_idname = 'VIEW3D_PT_SCENE_FoldedPaperEngine'
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'Folded Paper Engine'
    bl_order = 1
    bl_options = {'DEFAULT_CLOSED'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.scene, 'fpe_scene_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.scene, 'fpe_scene_context_props')
        scene = context.scene
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_scene_context_props'
        op.prop_name = 'SkyColor'
        op.context_base = 'scene'
        prop_parent0 = get_value_by_path(context.scene, f'fpe_scene_context_props')
        row0.prop(prop_parent0, 'SkyColor')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_scene_context_props'
        op.prop_name = 'BackgroundMusic'
        op.context_base = 'scene'
        prop_parent0 = get_value_by_path(context.scene, f'fpe_scene_context_props')
        row0.label(text='Background Music:')
        prop = row0.prop(prop_parent0, 'BackgroundMusic')
        op = row0.operator('folded_paper_engine.file_browser_operator', text='Browse', emboss=False)
        op.context_object_path = f'fpe_scene_context_props'
        op.prop_name = 'BackgroundMusic'
        op.context_base = 'scene'
        op.description = 'Select the background music for the scene'
        op.multiple = True
        op.filter_glob = '*.wav;*.ogg;*.mp3'
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_scene_context_props'
        op.prop_name = 'BackgroundMusicVolume'
        op.context_base = 'scene'
        prop_parent0 = get_value_by_path(context.scene, f'fpe_scene_context_props')
        row0.prop(prop_parent0, 'BackgroundMusicVolume')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_scene_context_props'
        op.prop_name = 'Gravity'
        op.context_base = 'scene'
        prop_parent0 = get_value_by_path(context.scene, f'fpe_scene_context_props')
        row0.prop(prop_parent0, 'Gravity')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_scene_context_props'
        op.prop_name = 'SceneLoadEvents'
        op.context_base = 'scene'
        prop_parent0 = get_value_by_path(context.scene, f'fpe_scene_context_props')
        row0.label(text='Scene Load Events:')
        row0.prop(prop_parent0, 'SceneLoadEvents')
        op = row0.operator('folded_paper_engine.add_item_operator', text='', icon='ADD', emboss=False)
        op.context_object_path = f'fpe_scene_context_props'
        op.prop_name = 'SceneLoadEvents'
        op.context_base = 'scene'
        prop_value = get_value_by_path(prop_parent0, 'SceneLoadEvents')
        for idx0, sub_item0 in enumerate(prop_value):
            box0 = layout.box()
            box_row0 = box0.row()
            box_row0.label(text=str(get_value_by_path(sub_item0, 'EventName')))
            op = box_row0.operator('folded_paper_engine.remove_item_operator', text='', icon='X', emboss=False)
            op.context_object_path = f'fpe_scene_context_props'
            op.prop_name = 'SceneLoadEvents'
            op.item_index = idx0
            op.context_base = 'scene'
            row0 = box0.row()
            op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
            op.context_object_path = f'fpe_scene_context_props.SceneLoadEvents.{idx0}'
            op.prop_name = 'EventName'
            op.context_base = 'scene'
            prop_parent0 = sub_item0
            row0.prop(prop_parent0, 'EventName')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_scene_context_props'
        op.prop_name = 'SceneUnloadEvents'
        op.context_base = 'scene'
        prop_parent0 = get_value_by_path(context.scene, f'fpe_scene_context_props')
        row0.label(text='Scene Unload Events:')
        row0.prop(prop_parent0, 'SceneUnloadEvents')
        op = row0.operator('folded_paper_engine.add_item_operator', text='', icon='ADD', emboss=False)
        op.context_object_path = f'fpe_scene_context_props'
        op.prop_name = 'SceneUnloadEvents'
        op.context_base = 'scene'
        prop_value = get_value_by_path(prop_parent0, 'SceneUnloadEvents')
        for idx0, sub_item0 in enumerate(prop_value):
            box0 = layout.box()
            box_row0 = box0.row()
            box_row0.label(text=str(get_value_by_path(sub_item0, 'EventName')))
            op = box_row0.operator('folded_paper_engine.remove_item_operator', text='', icon='X', emboss=False)
            op.context_object_path = f'fpe_scene_context_props'
            op.prop_name = 'SceneUnloadEvents'
            op.item_index = idx0
            op.context_base = 'scene'
            row0 = box0.row()
            op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
            op.context_object_path = f'fpe_scene_context_props.SceneUnloadEvents.{idx0}'
            op.prop_name = 'EventName'
            op.context_base = 'scene'
            prop_parent0 = sub_item0
            row0.prop(prop_parent0, 'EventName')
class VIEW3D_PT_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'Folded Paper Engine'
    bl_idname = 'VIEW3D_PT_FoldedPaperEngine'
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'Item'
    bl_order = 2
    bl_options = {'HEADER_LAYOUT_EXPAND'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.object, 'fpe_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.object, 'fpe_context_props')
        scene = context.scene
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'Player'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_context_props')
        row0.prop(prop_parent0, 'Player')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'Character'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_context_props')
        row0.prop(prop_parent0, 'Character')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'Physics'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_context_props')
        row0.prop(prop_parent0, 'Physics')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'Invisible'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_context_props')
        row0.prop(prop_parent0, 'Invisible')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'Water'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_context_props')
        row0.prop(prop_parent0, 'Water')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'SpriteAnimate'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_context_props')
        row0.prop(prop_parent0, 'SpriteAnimate')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'Trigger'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_context_props')
        row0.prop(prop_parent0, 'Trigger')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'Speaker'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_context_props')
        row0.prop(prop_parent0, 'Speaker')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'UIElement'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_context_props')
        row0.prop(prop_parent0, 'UIElement')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'SubScene'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_context_props')
        row0.prop(prop_parent0, 'SubScene')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'Holdable'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_context_props')
        row0.prop(prop_parent0, 'Holdable')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'Groups'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_context_props')
        row0.prop(prop_parent0, 'Groups')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'ScriptPath'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_context_props')
        row0.label(text='Script Path:')
        prop = row0.prop(prop_parent0, 'ScriptPath')
        op = row0.operator('folded_paper_engine.file_browser_operator', text='Browse', emboss=False)
        op.context_object_path = f'fpe_context_props'
        op.prop_name = 'ScriptPath'
        op.context_base = ''
        op.description = 'Set the script for this item. WARNING: Only use this if you know what you are doing, this will overwrite any existing script/functionality'
        op.multiple = False
        op.filter_glob = '*.gd'
class VIEW3D_PT_SCENE_EVENTS_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'Scene Events'
    bl_idname = 'VIEW3D_PT_SCENE_EVENTS_FoldedPaperEngine'
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'Folded Paper Engine'
    bl_order = 3
    bl_options = {'DEFAULT_CLOSED'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.scene, 'fpe_scene_events_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.scene, 'fpe_scene_events_context_props')
        scene = context.scene
        row0 = layout.row()
        prop_parent0 = get_value_by_path(context.scene, f'fpe_scene_events_context_props')
        row0.label(text='Scene Events:')
        row0.prop(prop_parent0, 'SceneEvents')
        op = row0.operator('folded_paper_engine.add_item_operator', text='', icon='ADD', emboss=False)
        op.context_object_path = f'fpe_scene_events_context_props'
        op.prop_name = 'SceneEvents'
        op.context_base = 'scene'
        prop_value = get_value_by_path(prop_parent0, 'SceneEvents')
        for idx0, sub_item0 in enumerate(prop_value):
            box0 = layout.box()
            box_row0 = box0.row()
            box_row0.label(text=str(get_value_by_path(sub_item0, 'EventName')))
            op = box_row0.operator('folded_paper_engine.remove_item_operator', text='', icon='X', emboss=False)
            op.context_object_path = f'fpe_scene_events_context_props'
            op.prop_name = 'SceneEvents'
            op.item_index = idx0
            op.context_base = 'scene'
            row0 = box0.row()
            op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
            op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}'
            op.prop_name = 'EventName'
            op.context_base = 'scene'
            prop_parent0 = sub_item0
            row0.prop(prop_parent0, 'EventName')
            row0 = box0.row()
            op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
            op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}'
            op.prop_name = 'Commands'
            op.context_base = 'scene'
            prop_parent0 = sub_item0
            prop_value0 = get_value_by_path(prop_parent0, 'Commands')
            row0.prop(prop_value0, 'FPE_INTERNAL_EXPANDED', text="", icon='TRIA_RIGHT' if not prop_value0.FPE_INTERNAL_EXPANDED else 'TRIA_DOWN', emboss=False)
            col0 = row0.column(align=True)
            col0.label(text='Commands:')
            if prop_value0.FPE_INTERNAL_EXPANDED:
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'DispatchEvent'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.prop(prop_parent1, 'DispatchEvent')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'LoadLevel'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.label(text='Load Level:')
                prop = row1.prop(prop_parent1, 'LoadLevel')
                op = row1.operator('folded_paper_engine.file_browser_operator', text='Browse', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'LoadLevel'
                op.context_base = 'scene'
                op.description = 'Load a level on trigger'
                op.multiple = False
                op.filter_glob = '*.scn;*.tscn;*.glb;*.gltf'
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'Animations'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.prop(prop_parent1, 'Animations')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'StopAnimations'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.prop(prop_parent1, 'StopAnimations')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'SpeakerTrigger'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.prop(prop_parent1, 'SpeakerTrigger')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'SpeakerTriggerSelf'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.prop(prop_parent1, 'SpeakerTriggerSelf')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'ActivateCamera'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.prop_search(prop_parent1, 'ActivateCamera', scene, 'objects')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'ReactivatePlayerCamera'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.prop(prop_parent1, 'ReactivatePlayerCamera')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'DeactivatePlayerControls'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.prop(prop_parent1, 'DeactivatePlayerControls')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'ReactivatePlayerControls'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.prop(prop_parent1, 'ReactivatePlayerControls')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'LoadSubScene'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.prop_search(prop_parent1, 'LoadSubScene', scene, 'objects')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'UnloadSubScene'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.prop_search(prop_parent1, 'UnloadSubScene', scene, 'objects')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'UnloadThisSubScene'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.prop(prop_parent1, 'UnloadThisSubScene')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'StartConversation'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.label(text='Start Conversation:')
                prop = row1.prop(prop_parent1, 'StartConversation')
                op = row1.operator('folded_paper_engine.file_browser_operator', text='Browse', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'StartConversation'
                op.context_base = 'scene'
                op.description = 'Start one of the specified conversations. The conversation is selected by the names of the characters involved and the required characters list in the conversation'
                op.multiple = True
                op.filter_glob = '*.tres;*.res'
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'PauseSpecificActivities'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.label(text='Pause Specific Activities:')
                row1.prop(prop_parent1, 'PauseSpecificActivities')
                op = row1.operator('folded_paper_engine.add_item_operator', text='', icon='ADD', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'PauseSpecificActivities'
                op.context_base = 'scene'
                new_default = op.defaults.add()
                new_default.key = 'ActivityType'
                new_default.value = 'ALL'
                new_default.value_is_function = False
                prop_value = get_value_by_path(prop_parent1, 'PauseSpecificActivities')
                for idx1, sub_item1 in enumerate(prop_value):
                    box1 = layout.box()
                    box_row1 = box1.row()
                    box_row1.label(text=str(get_value_by_path(sub_item1, 'ActivityType')))
                    op = box_row1.operator('folded_paper_engine.remove_item_operator', text='', icon='X', emboss=False)
                    op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                    op.prop_name = 'PauseSpecificActivities'
                    op.item_index = idx1
                    op.context_base = 'scene'
                    row1 = box1.row()
                    op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                    op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands.PauseSpecificActivities.{idx1}'
                    op.prop_name = 'ActivityType'
                    op.context_base = 'scene'
                    prop_parent1 = sub_item1
                    row1.prop(prop_parent1, 'ActivityType')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'ResumeSpecificActivities'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.label(text='Resume Specific Activities:')
                row1.prop(prop_parent1, 'ResumeSpecificActivities')
                op = row1.operator('folded_paper_engine.add_item_operator', text='', icon='ADD', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'ResumeSpecificActivities'
                op.context_base = 'scene'
                new_default = op.defaults.add()
                new_default.key = 'ActivityType'
                new_default.value = 'ALL'
                new_default.value_is_function = False
                prop_value = get_value_by_path(prop_parent1, 'ResumeSpecificActivities')
                for idx1, sub_item1 in enumerate(prop_value):
                    box1 = layout.box()
                    box_row1 = box1.row()
                    box_row1.label(text=str(get_value_by_path(sub_item1, 'ActivityType')))
                    op = box_row1.operator('folded_paper_engine.remove_item_operator', text='', icon='X', emboss=False)
                    op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                    op.prop_name = 'ResumeSpecificActivities'
                    op.item_index = idx1
                    op.context_base = 'scene'
                    row1 = box1.row()
                    op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                    op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands.ResumeSpecificActivities.{idx1}'
                    op.prop_name = 'ActivityType'
                    op.context_base = 'scene'
                    prop_parent1 = sub_item1
                    row1.prop(prop_parent1, 'ActivityType')
                row1 = col0.row()
                op = row1.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
                op.context_object_path = f'fpe_scene_events_context_props.SceneEvents.{idx0}.Commands'
                op.prop_name = 'DeleteByGroup'
                op.context_base = 'scene'
                prop_parent1 = prop_value0
                row1.prop(prop_parent1, 'DeleteByGroup')
class VIEW3D_TRIGGER_EVENTS_PT_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'Trigger Events'
    bl_idname = 'VIEW3D_TRIGGER_EVENTS_PT_FoldedPaperEngine'
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'Folded Paper Engine'
    bl_order = 4
    bl_options = {'DEFAULT_CLOSED'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.object, 'fpe_trigger_events_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.object, 'fpe_trigger_events_context_props')
        scene = context.scene
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_trigger_events_context_props'
        op.prop_name = 'TriggerGroups'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_trigger_events_context_props')
        row0.prop(prop_parent0, 'TriggerGroups')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_trigger_events_context_props'
        op.prop_name = 'TriggerEvents'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_trigger_events_context_props')
        row0.label(text='Trigger Events:')
        row0.prop(prop_parent0, 'TriggerEvents')
        op = row0.operator('folded_paper_engine.add_item_operator', text='', icon='ADD', emboss=False)
        op.context_object_path = f'fpe_trigger_events_context_props'
        op.prop_name = 'TriggerEvents'
        op.context_base = ''
        prop_value = get_value_by_path(prop_parent0, 'TriggerEvents')
        for idx0, sub_item0 in enumerate(prop_value):
            box0 = layout.box()
            box_row0 = box0.row()
            box_row0.label(text=str(get_value_by_path(sub_item0, 'EventName')))
            op = box_row0.operator('folded_paper_engine.remove_item_operator', text='', icon='X', emboss=False)
            op.context_object_path = f'fpe_trigger_events_context_props'
            op.prop_name = 'TriggerEvents'
            op.item_index = idx0
            op.context_base = ''
            row0 = box0.row()
            op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
            op.context_object_path = f'fpe_trigger_events_context_props.TriggerEvents.{idx0}'
            op.prop_name = 'TriggerType'
            op.context_base = ''
            prop_parent0 = sub_item0
            row0.prop(prop_parent0, 'TriggerType')
            row0 = box0.row()
            op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
            op.context_object_path = f'fpe_trigger_events_context_props.TriggerEvents.{idx0}'
            op.prop_name = 'EventName'
            op.context_base = ''
            prop_parent0 = sub_item0
            row0.prop(prop_parent0, 'EventName')
class VIEW3D_INVENTORY_PT_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'Inventory Item'
    bl_idname = 'VIEW3D_INVENTORY_PT_FoldedPaperEngine'
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'Folded Paper Engine'
    bl_order = 5
    bl_options = {'DEFAULT_CLOSED'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.object, 'fpe_inventory_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.object, 'fpe_inventory_context_props')
        scene = context.scene
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_inventory_context_props'
        op.prop_name = 'InventoryItemKind'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_inventory_context_props')
        row0.prop(prop_parent0, 'InventoryItemKind')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_inventory_context_props'
        op.prop_name = 'InventoryItemQuantity'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_inventory_context_props')
        row0.prop(prop_parent0, 'InventoryItemQuantity')
class VIEW3D_SPEAKER_SETTINGS_PT_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'Speaker Settings'
    bl_idname = 'VIEW3D_SPEAKER_SETTINGS_PT_FoldedPaperEngine'
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'Folded Paper Engine'
    bl_order = 6
    bl_options = {'DEFAULT_CLOSED'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.object, 'fpe_speaker_settings_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.object, 'fpe_speaker_settings_context_props')
        scene = context.scene
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_speaker_settings_context_props'
        op.prop_name = 'SpeakerFile'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_speaker_settings_context_props')
        row0.label(text='Speaker File:')
        prop = row0.prop(prop_parent0, 'SpeakerFile')
        op = row0.operator('folded_paper_engine.file_browser_operator', text='Browse', emboss=False)
        op.context_object_path = f'fpe_speaker_settings_context_props'
        op.prop_name = 'SpeakerFile'
        op.context_base = ''
        op.description = 'Path to the audio file for this speaker'
        op.multiple = False
        op.filter_glob = '*.wav;*.ogg;*.mp3'
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_speaker_settings_context_props'
        op.prop_name = 'SpeakerLoop'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_speaker_settings_context_props')
        row0.prop(prop_parent0, 'SpeakerLoop')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_speaker_settings_context_props'
        op.prop_name = 'SpeakerVolume'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_speaker_settings_context_props')
        row0.prop(prop_parent0, 'SpeakerVolume')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_speaker_settings_context_props'
        op.prop_name = 'SpeakerMaxDistance'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_speaker_settings_context_props')
        row0.prop(prop_parent0, 'SpeakerMaxDistance')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_speaker_settings_context_props'
        op.prop_name = 'SpeakerAutoplay'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_speaker_settings_context_props')
        row0.prop(prop_parent0, 'SpeakerAutoplay')
class VIEW3D_CHARACTER_PT_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'Character'
    bl_idname = 'VIEW3D_CHARACTER_PT_FoldedPaperEngine'
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'Folded Paper Engine'
    bl_order = 7
    bl_options = {'DEFAULT_CLOSED'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.object, 'fpe_character_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.object, 'fpe_character_context_props')
        scene = context.scene
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_character_context_props'
        op.prop_name = 'WalkSpeedMultiplier'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_character_context_props')
        row0.prop(prop_parent0, 'WalkSpeedMultiplier')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_character_context_props'
        op.prop_name = 'RunSpeedMultiplier'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_character_context_props')
        row0.prop(prop_parent0, 'RunSpeedMultiplier')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_character_context_props'
        op.prop_name = 'JumpForceMultiplier'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_character_context_props')
        row0.prop(prop_parent0, 'JumpForceMultiplier')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_character_context_props'
        op.prop_name = 'IdleAnimation'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_character_context_props')
        row0.prop(prop_parent0, 'IdleAnimation')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_character_context_props'
        op.prop_name = 'WalkAnimation'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_character_context_props')
        row0.prop(prop_parent0, 'WalkAnimation')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_character_context_props'
        op.prop_name = 'RunAnimation'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_character_context_props')
        row0.prop(prop_parent0, 'RunAnimation')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_character_context_props'
        op.prop_name = 'JumpAnimation'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_character_context_props')
        row0.prop(prop_parent0, 'JumpAnimation')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_character_context_props'
        op.prop_name = 'TalkAnimation'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_character_context_props')
        row0.prop(prop_parent0, 'TalkAnimation')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_character_context_props'
        op.prop_name = 'WanderingBounds'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_character_context_props')
        row0.prop_search(prop_parent0, 'WanderingBounds', scene, 'objects')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_character_context_props'
        op.prop_name = 'FaceMotionDirection'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_character_context_props')
        row0.prop(prop_parent0, 'FaceMotionDirection')
class VIEW3D_PHYSICS_PT_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'Physics'
    bl_idname = 'VIEW3D_PHYSICS_PT_FoldedPaperEngine'
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'Folded Paper Engine'
    bl_order = 8
    bl_options = {'DEFAULT_CLOSED'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.object, 'fpe_physics_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.object, 'fpe_physics_context_props')
        scene = context.scene
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_physics_context_props'
        op.prop_name = 'Mass'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_physics_context_props')
        row0.prop(prop_parent0, 'Mass')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_physics_context_props'
        op.prop_name = 'Friction'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_physics_context_props')
        row0.prop(prop_parent0, 'Friction')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_physics_context_props'
        op.prop_name = 'Bounciness'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_physics_context_props')
        row0.prop(prop_parent0, 'Bounciness')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_physics_context_props'
        op.prop_name = 'ContinuousCollisionDetection'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_physics_context_props')
        row0.prop(prop_parent0, 'ContinuousCollisionDetection')
class DOPESHEET_EDITOR_PT_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'Folded Paper Engine (Animation)'
    bl_idname = 'DOPESHEET_EDITOR_PT_FoldedPaperEngine'
    bl_space_type = 'DOPESHEET_EDITOR'
    bl_region_type = 'UI'
    bl_category = 'Action'
    bl_order = 9
    bl_options = {'DEFAULT_CLOSED'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.object, 'animation_data.action.fpe_anim_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.object, 'animation_data.action.fpe_anim_context_props')
        scene = context.scene
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'animation_data.action.fpe_anim_context_props'
        op.prop_name = 'Autoplay'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'animation_data.action.fpe_anim_context_props')
        row0.prop(prop_parent0, 'Autoplay')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'animation_data.action.fpe_anim_context_props'
        op.prop_name = 'Loop'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'animation_data.action.fpe_anim_context_props')
        row0.prop(prop_parent0, 'Loop')
class DOPESHEET_EDITOR_FRAME_EVT_PT_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'Folded Paper Engine (Frame Events)'
    bl_idname = 'DOPESHEET_EDITOR_FRAME_EVT_PT_FoldedPaperEngine'
    bl_space_type = 'DOPESHEET_EDITOR'
    bl_region_type = 'UI'
    bl_category = 'Action'
    bl_order = 10
    bl_options = {'DEFAULT_CLOSED'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.object, 'animation_data.action.fpe_frame_event_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.object, 'animation_data.action.fpe_frame_event_context_props')
        scene = context.scene
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'animation_data.action.fpe_frame_event_context_props'
        op.prop_name = 'FrameEvents'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'animation_data.action.fpe_frame_event_context_props')
        row0.label(text='Frame Events:')
        row0.prop(prop_parent0, 'FrameEvents')
        op = row0.operator('folded_paper_engine.add_item_operator', text='', icon='ADD', emboss=False)
        op.context_object_path = f'animation_data.action.fpe_frame_event_context_props'
        op.prop_name = 'FrameEvents'
        op.on_add = 'add_keyframe_to_channel(context.object, \'FPE_FRAME_EVENTS\', frame=context.scene.frame_current, value=context.scene.frame_current)'
        op.context_base = ''
        new_default = op.defaults.add()
        new_default.key = 'FrameNumber'
        new_default.value = 'bpy.context.scene.frame_current'
        new_default.value_is_function = True
        new_default = op.defaults.add()
        new_default.key = 'FrameTime'
        new_default.value = 'bpy.context.scene.frame_current / (bpy.context.scene.render.fps / bpy.context.scene.render.fps_base)'
        new_default.value_is_function = True
        prop_value = get_value_by_path(prop_parent0, 'FrameEvents')
        for idx0, sub_item0 in enumerate(prop_value):
            box0 = layout.box()
            box_row0 = box0.row()
            box_row0.label(text=str(get_value_by_path(sub_item0, 'FrameNumber')))
            op = box_row0.operator('folded_paper_engine.remove_item_operator', text='', icon='X', emboss=False)
            op.context_object_path = f'animation_data.action.fpe_frame_event_context_props'
            op.prop_name = 'FrameEvents'
            op.item_index = idx0
            op.on_remove = 'remove_keyframe_from_channel(context.object, \'FPE_FRAME_EVENTS\', frame=item[\'FrameNumber\'])'
            op.context_base = ''
            row0 = box0.row()
            op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
            op.context_object_path = f'animation_data.action.fpe_frame_event_context_props.FrameEvents.{idx0}'
            op.prop_name = 'EventName'
            op.context_base = ''
            prop_parent0 = sub_item0
            row0.prop(prop_parent0, 'EventName')
class MATERIAL_PT_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'Folded Paper Engine (Material)'
    bl_idname = 'MATERIAL_PT_FoldedPaperEngine'
    bl_space_type = 'PROPERTIES'
    bl_region_type = 'WINDOW'
    bl_context = 'material'
    bl_order = 11
    bl_options = {'DEFAULT_CLOSED'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.material, 'fpe_material_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.material, 'fpe_material_context_props')
        scene = context.scene
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_material_context_props'
        op.prop_name = 'RenderPriority'
        op.context_base = 'material'
        prop_parent0 = get_value_by_path(context.material, f'fpe_material_context_props')
        row0.prop(prop_parent0, 'RenderPriority')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_material_context_props'
        op.prop_name = 'Reflective'
        op.context_base = 'material'
        prop_parent0 = get_value_by_path(context.material, f'fpe_material_context_props')
        row0.prop(prop_parent0, 'Reflective')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_material_context_props'
        op.prop_name = 'ReplaceWithMaterial'
        op.context_base = 'material'
        prop_parent0 = get_value_by_path(context.material, f'fpe_material_context_props')
        row0.label(text='Replace With Material:')
        prop = row0.prop(prop_parent0, 'ReplaceWithMaterial')
        op = row0.operator('folded_paper_engine.file_browser_operator', text='Browse', emboss=False)
        op.context_object_path = f'fpe_material_context_props'
        op.prop_name = 'ReplaceWithMaterial'
        op.context_base = 'material'
        op.description = 'Replace this material with the specified material'
        op.multiple = False
        op.filter_glob = '*.tres;*.res'
class VIEW3D_UI_ELEMENT_PT_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'UI Element'
    bl_idname = 'VIEW3D_UI_ELEMENT_PT_FoldedPaperEngine'
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'Folded Paper Engine'
    bl_order = 12
    bl_options = {'DEFAULT_CLOSED'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.object, 'fpe_ui_element_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.object, 'fpe_ui_element_context_props')
        scene = context.scene
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_ui_element_context_props'
        op.prop_name = 'UICursor'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_ui_element_context_props')
        row0.prop(prop_parent0, 'UICursor')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_ui_element_context_props'
        op.prop_name = 'UICursorDepth'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_ui_element_context_props')
        row0.prop(prop_parent0, 'UICursorDepth')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_ui_element_context_props'
        op.prop_name = 'UICursorSelectAnimation'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_ui_element_context_props')
        row0.prop(prop_parent0, 'UICursorSelectAnimation')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_ui_element_context_props'
        op.prop_name = 'UICursorLookAtCamera'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_ui_element_context_props')
        row0.prop(prop_parent0, 'UICursorLookAtCamera')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_ui_element_context_props'
        op.prop_name = 'UIOption'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_ui_element_context_props')
        row0.prop(prop_parent0, 'UIOption')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_ui_element_context_props'
        op.prop_name = 'UIOptionCommandDelay'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_ui_element_context_props')
        row0.prop(prop_parent0, 'UIOptionCommandDelay')
class VIEW3D_SUB_SCENE_PT_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'Sub Scene'
    bl_idname = 'VIEW3D_SUB_SCENE_PT_FoldedPaperEngine'
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'Folded Paper Engine'
    bl_order = 13
    bl_options = {'DEFAULT_CLOSED'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.object, 'fpe_sub_scene_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.object, 'fpe_sub_scene_context_props')
        scene = context.scene
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_sub_scene_context_props'
        op.prop_name = 'SceneFile'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_sub_scene_context_props')
        row0.label(text='Scene File:')
        prop = row0.prop(prop_parent0, 'SceneFile')
        op = row0.operator('folded_paper_engine.file_browser_operator', text='Browse', emboss=False)
        op.context_object_path = f'fpe_sub_scene_context_props'
        op.prop_name = 'SceneFile'
        op.context_base = ''
        op.description = 'Path to the scene file for this sub scene'
        op.multiple = False
        op.filter_glob = '*.scn;*.tscn;*.glb;*.gltf'
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_sub_scene_context_props'
        op.prop_name = 'AutoLoad'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_sub_scene_context_props')
        row0.prop(prop_parent0, 'AutoLoad')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_sub_scene_context_props'
        op.prop_name = 'Pause'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_sub_scene_context_props')
        row0.prop(prop_parent0, 'Pause')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_sub_scene_context_props'
        op.prop_name = 'ResumeOnUnload'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_sub_scene_context_props')
        row0.prop(prop_parent0, 'ResumeOnUnload')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_sub_scene_context_props'
        op.prop_name = 'UnloadDelay'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_sub_scene_context_props')
        row0.prop(prop_parent0, 'UnloadDelay')
class VIEW3D_PLAYER_CONTROLS_PT_FoldedPaperEngine(bpy.types.Panel):
    bl_label = 'Player Controls'
    bl_idname = 'VIEW3D_PLAYER_CONTROLS_PT_FoldedPaperEngine'
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'Folded Paper Engine'
    bl_order = 14
    bl_options = {'DEFAULT_CLOSED'}
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.object, 'fpe_player_controls_context_props')
        return context_object is not None
    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.object, 'fpe_player_controls_context_props')
        scene = context.scene
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_player_controls_context_props'
        op.prop_name = 'ThirdPerson'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_player_controls_context_props')
        row0.prop(prop_parent0, 'ThirdPerson')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_player_controls_context_props'
        op.prop_name = 'FirstPerson'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_player_controls_context_props')
        row0.prop(prop_parent0, 'FirstPerson')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_player_controls_context_props'
        op.prop_name = 'CanHoldItems'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_player_controls_context_props')
        row0.prop(prop_parent0, 'CanHoldItems')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_player_controls_context_props'
        op.prop_name = 'HoldZoneDistance'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_player_controls_context_props')
        row0.prop(prop_parent0, 'HoldZoneDistance')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_player_controls_context_props'
        op.prop_name = 'HoldZoneSize'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_player_controls_context_props')
        row0.prop(prop_parent0, 'HoldZoneSize')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_player_controls_context_props'
        op.prop_name = 'HoldZoneScene'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_player_controls_context_props')
        row0.label(text='Hold Zone Scene:')
        prop = row0.prop(prop_parent0, 'HoldZoneScene')
        op = row0.operator('folded_paper_engine.file_browser_operator', text='Browse', emboss=False)
        op.context_object_path = f'fpe_player_controls_context_props'
        op.prop_name = 'HoldZoneScene'
        op.context_base = ''
        op.description = 'A scene to load into the player\'s hold zone. The parent of this scene will be a `HoldZone` with holdable item related signals'
        op.multiple = False
        op.filter_glob = '*.scn;*.tscn;*.glb;*.gltf'
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_player_controls_context_props'
        op.prop_name = 'StandardCameraHeight'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_player_controls_context_props')
        row0.prop(prop_parent0, 'StandardCameraHeight')
        row0 = layout.row()
        op = row0.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
        op.context_object_path = f'fpe_player_controls_context_props'
        op.prop_name = 'StandardCameraDistance'
        op.context_base = ''
        prop_parent0 = get_value_by_path(context.object, f'fpe_player_controls_context_props')
        row0.prop(prop_parent0, 'StandardCameraDistance')
def register():
    bpy.utils.register_class(DefaultsPropertyGroup)
    bpy.utils.register_class(AddItemOperator)
    bpy.utils.register_class(RemoveItemOperator)
    bpy.utils.register_class(FileBrowserItem)
    bpy.utils.register_class(FileBrowserOperator)
    bpy.utils.register_class(ClearValueOperator)
    bpy.utils.register_class(ACTIVITY_TYPES_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(EVENT_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(VIEW3D_PT_SCENE_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(VIEW3D_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(COMMANDS_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(SCENE_EVENT_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(TRIGGER_EVENT_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(FRAME_EVENT_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(VIEW3D_PT_SCENE_EVENTS_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(VIEW3D_TRIGGER_EVENTS_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(VIEW3D_INVENTORY_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(VIEW3D_SPEAKER_SETTINGS_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(VIEW3D_CHARACTER_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(VIEW3D_PHYSICS_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(DOPESHEET_EDITOR_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(DOPESHEET_EDITOR_FRAME_EVT_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(MATERIAL_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(VIEW3D_UI_ELEMENT_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(VIEW3D_SUB_SCENE_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(VIEW3D_PLAYER_CONTROLS_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.register_class(VIEW3D_PT_SCENE_FoldedPaperEngine)
    bpy.utils.register_class(VIEW3D_PT_FoldedPaperEngine)
    bpy.utils.register_class(VIEW3D_PT_SCENE_EVENTS_FoldedPaperEngine)
    bpy.utils.register_class(VIEW3D_TRIGGER_EVENTS_PT_FoldedPaperEngine)
    bpy.utils.register_class(VIEW3D_INVENTORY_PT_FoldedPaperEngine)
    bpy.utils.register_class(VIEW3D_SPEAKER_SETTINGS_PT_FoldedPaperEngine)
    bpy.utils.register_class(VIEW3D_CHARACTER_PT_FoldedPaperEngine)
    bpy.utils.register_class(VIEW3D_PHYSICS_PT_FoldedPaperEngine)
    bpy.utils.register_class(DOPESHEET_EDITOR_PT_FoldedPaperEngine)
    bpy.utils.register_class(DOPESHEET_EDITOR_FRAME_EVT_PT_FoldedPaperEngine)
    bpy.utils.register_class(MATERIAL_PT_FoldedPaperEngine)
    bpy.utils.register_class(VIEW3D_UI_ELEMENT_PT_FoldedPaperEngine)
    bpy.utils.register_class(VIEW3D_SUB_SCENE_PT_FoldedPaperEngine)
    bpy.utils.register_class(VIEW3D_PLAYER_CONTROLS_PT_FoldedPaperEngine)
    # Context Object Property Group Setup
    bpy.types.Action.FPE_FRAME_COMMANDS = bpy.props.BoolProperty()
    bpy.types.Scene.fpe_scene_context_props = bpy.props.PointerProperty(type=VIEW3D_PT_SCENE_FoldedPaperEnginePropertyGroup)
    bpy.types.Object.fpe_context_props = bpy.props.PointerProperty(type=VIEW3D_PT_FoldedPaperEnginePropertyGroup)
    bpy.types.Scene.fpe_scene_events_context_props = bpy.props.PointerProperty(type=VIEW3D_PT_SCENE_EVENTS_FoldedPaperEnginePropertyGroup)
    bpy.types.Object.fpe_trigger_events_context_props = bpy.props.PointerProperty(type=VIEW3D_TRIGGER_EVENTS_PT_FoldedPaperEnginePropertyGroup)
    bpy.types.Object.fpe_inventory_context_props = bpy.props.PointerProperty(type=VIEW3D_INVENTORY_PT_FoldedPaperEnginePropertyGroup)
    bpy.types.Object.fpe_speaker_settings_context_props = bpy.props.PointerProperty(type=VIEW3D_SPEAKER_SETTINGS_PT_FoldedPaperEnginePropertyGroup)
    bpy.types.Object.fpe_character_context_props = bpy.props.PointerProperty(type=VIEW3D_CHARACTER_PT_FoldedPaperEnginePropertyGroup)
    bpy.types.Object.fpe_physics_context_props = bpy.props.PointerProperty(type=VIEW3D_PHYSICS_PT_FoldedPaperEnginePropertyGroup)
    bpy.types.Action.fpe_anim_context_props = bpy.props.PointerProperty(type=DOPESHEET_EDITOR_PT_FoldedPaperEnginePropertyGroup)
    bpy.types.Action.fpe_frame_event_context_props = bpy.props.PointerProperty(type=DOPESHEET_EDITOR_FRAME_EVT_PT_FoldedPaperEnginePropertyGroup)
    bpy.types.Material.fpe_material_context_props = bpy.props.PointerProperty(type=MATERIAL_PT_FoldedPaperEnginePropertyGroup)
    bpy.types.Object.fpe_ui_element_context_props = bpy.props.PointerProperty(type=VIEW3D_UI_ELEMENT_PT_FoldedPaperEnginePropertyGroup)
    bpy.types.Object.fpe_sub_scene_context_props = bpy.props.PointerProperty(type=VIEW3D_SUB_SCENE_PT_FoldedPaperEnginePropertyGroup)
    bpy.types.Object.fpe_player_controls_context_props = bpy.props.PointerProperty(type=VIEW3D_PLAYER_CONTROLS_PT_FoldedPaperEnginePropertyGroup)
def unregister():
    bpy.utils.unregister_class(DefaultsPropertyGroup)
    bpy.utils.unregister_class(AddItemOperator)
    bpy.utils.unregister_class(RemoveItemOperator)
    bpy.utils.unregister_class(FileBrowserItem)
    bpy.utils.unregister_class(FileBrowserOperator)
    bpy.utils.unregister_class(ClearValueOperator)
    bpy.utils.unregister_class(ACTIVITY_TYPES_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(EVENT_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(VIEW3D_PT_SCENE_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(VIEW3D_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(COMMANDS_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(SCENE_EVENT_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(TRIGGER_EVENT_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(FRAME_EVENT_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(VIEW3D_PT_SCENE_EVENTS_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(VIEW3D_TRIGGER_EVENTS_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(VIEW3D_INVENTORY_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(VIEW3D_SPEAKER_SETTINGS_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(VIEW3D_CHARACTER_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(VIEW3D_PHYSICS_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(DOPESHEET_EDITOR_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(DOPESHEET_EDITOR_FRAME_EVT_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(MATERIAL_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(VIEW3D_UI_ELEMENT_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(VIEW3D_SUB_SCENE_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(VIEW3D_PLAYER_CONTROLS_PT_FoldedPaperEnginePropertyGroup)
    bpy.utils.unregister_class(VIEW3D_PT_SCENE_FoldedPaperEngine)
    bpy.utils.unregister_class(VIEW3D_PT_FoldedPaperEngine)
    bpy.utils.unregister_class(VIEW3D_PT_SCENE_EVENTS_FoldedPaperEngine)
    bpy.utils.unregister_class(VIEW3D_TRIGGER_EVENTS_PT_FoldedPaperEngine)
    bpy.utils.unregister_class(VIEW3D_INVENTORY_PT_FoldedPaperEngine)
    bpy.utils.unregister_class(VIEW3D_SPEAKER_SETTINGS_PT_FoldedPaperEngine)
    bpy.utils.unregister_class(VIEW3D_CHARACTER_PT_FoldedPaperEngine)
    bpy.utils.unregister_class(VIEW3D_PHYSICS_PT_FoldedPaperEngine)
    bpy.utils.unregister_class(DOPESHEET_EDITOR_PT_FoldedPaperEngine)
    bpy.utils.unregister_class(DOPESHEET_EDITOR_FRAME_EVT_PT_FoldedPaperEngine)
    bpy.utils.unregister_class(MATERIAL_PT_FoldedPaperEngine)
    bpy.utils.unregister_class(VIEW3D_UI_ELEMENT_PT_FoldedPaperEngine)
    bpy.utils.unregister_class(VIEW3D_SUB_SCENE_PT_FoldedPaperEngine)
    bpy.utils.unregister_class(VIEW3D_PLAYER_CONTROLS_PT_FoldedPaperEngine)
    # Context Object Property Group Teardown
    del bpy.types.Action.FPE_FRAME_COMMANDS
    del bpy.types.Scene.fpe_scene_context_props
    del bpy.types.Object.fpe_context_props
    del bpy.types.Scene.fpe_scene_events_context_props
    del bpy.types.Object.fpe_trigger_events_context_props
    del bpy.types.Object.fpe_inventory_context_props
    del bpy.types.Object.fpe_speaker_settings_context_props
    del bpy.types.Object.fpe_character_context_props
    del bpy.types.Object.fpe_physics_context_props
    del bpy.types.Action.fpe_anim_context_props
    del bpy.types.Action.fpe_frame_event_context_props
    del bpy.types.Material.fpe_material_context_props
    del bpy.types.Object.fpe_ui_element_context_props
    del bpy.types.Object.fpe_sub_scene_context_props
    del bpy.types.Object.fpe_player_controls_context_props
if __name__ == "__main__":
    register()