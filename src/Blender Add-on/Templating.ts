enum INTERNAL_PROPERTY_NAMES {
  FPE_INTERNAL_EXPANDED = "FPE_INTERNAL_EXPANDED"
}

export const addIndentDepth = (
  content: string = "",
  indexLevel: number = 0
): string =>
  content
    .split("\n")
    .map((line) => `${"    ".repeat(indexLevel)}${line}`)
    .join("\n");

export const PropTypeMap = {
  string: "StringProperty",
  int: "IntProperty",
  number: "FloatProperty",
  boolean: "BoolProperty",
  node: "StringProperty",
  file: "StringProperty",
  files: "CollectionProperty",
  image: "StringProperty",
  images: "StringProperty",
  collection: "CollectionProperty",
  object: "PointerProperty",
  enum: "EnumProperty",
  hidden: "StringProperty",
  operator: "Operator",
  color: "FloatVectorProperty",
};

export type SpecificPanelConfig = Record<string, any>;

export type BlenderPanelPropertyProps<PanelConfigType extends SpecificPanelConfig = SpecificPanelConfig> = {
  name: string;
  label: string;
  type: keyof typeof PropTypeMap;
  description: string;
  hidden?: boolean;
  disableClearValue?: boolean;
  config?: PanelConfigType;
  defaultValue?: any;
  getter?: string;
  setter?: string;
  operatorType?: string;
  subType?: string;
  subItemLabel?: string;
  subItemLabelField?: string;
  subItemDefaultValues?: {
    key: string;
    value: string;
    valueIsFunction?: boolean;
  }[];
  subItemProperties?: BlenderPanelPropertyProps[];
  onAddSubItem?: string;
  onRemoveSubItem?: string;
};

export type ExtraArgsHandler = (prop: BlenderPanelPropertyProps) => string;

export type FileBrowserConfig = {
  filter_glob?: string;
};
export type NumericInputConfig = {
  min?: string;
  max?: string;
};
export type EnumItem = {
  id: string;
  label?: string;
  description?: string;
};
export type EnumInputConfig = {
  items?: EnumItem[];
};
export type InputTemplateFunction = (
  prop: BlenderPanelPropertyProps,
  pathPrefix: string,
  nestingLevel: number,
  contextBase?: string,
  layoutObject?: string,
) => string;

export const numericExtraArgsHandler: ExtraArgsHandler = ({config}) => config ? [
  `min=${config.min}`,
  `max=${config.max}`,
].join(", ") : '';

export const enumExtraArgsHandler: ExtraArgsHandler = ({config}) => {
  const itemStrings: string[] = [];

  if (config) {
    const {
      items = [],
    }: EnumInputConfig = config as unknown as EnumInputConfig;

    for (const itm of items) {
      const {
        id,
        label,
        description,
      } = itm;

      itemStrings.push(`("${id}", "${label ?? id}", "${description ?? label ?? id}")`)
    }
  }

  return `items=[
    ${itemStrings.join(",\n    ")}
]`;
};

export const PropTypeExtraArgsMap: Partial<
  Record<keyof typeof PropTypeMap, string | ExtraArgsHandler>
> = {
  files: "type=FileBrowserItem",
  images: "type=FileBrowserItem",
  int: numericExtraArgsHandler,
  number: numericExtraArgsHandler,
  enum: enumExtraArgsHandler,
  color: "subtype='COLOR', size=4, default=(1.0, 1.0, 1.0, 1.0), min=0.0, max=1.0",
};

export const PropTypeOmitFromPropertyGroup: Partial<
  Record<keyof typeof PropTypeMap, boolean>
> = {
  operator: true,
};

export const defaultInputTemplate: InputTemplateFunction = (
  {name, type},
  _pathPrefix,
  nestingLevel,
  _contextBase = "",
  layoutObject = "row",
) => `${layoutObject}.prop(prop_parent${nestingLevel ?? 0}, '${name}')`;

export const getFileInputTemplate = (multiple: boolean = false): InputTemplateFunction => (
  {
    name,
    label,
    type,
    description,
    config: {
      filter_glob = '*.*',
    } = {}
  }: BlenderPanelPropertyProps<FileBrowserConfig>,
  pathPrefix,
  nestingLevel,
  contextBase = "",
  layoutObject = "row",
) => `
${layoutObject}.label(text='${label}:')
prop = ${layoutObject}.prop(prop_parent${nestingLevel ?? 0}, '${name}')
op = ${layoutObject}.operator('folded_paper_engine.file_browser_operator', text='Browse', emboss=False)
op.context_object_path = f'${pathPrefix}'
op.prop_name = '${name}'
op.context_base = '${contextBase}'
op.description = '${description}'
op.multiple = ${multiple ? "True" : "False"}
op.filter_glob = ${type === "image" || type === "images" ? 'bpy.types.Image' : `'${filter_glob}'`}
`;

export const InputTemplateMap: Partial<Record<
  keyof typeof PropTypeMap,
  InputTemplateFunction
>> = {
  node: (
    {name},
    _pathPrefix,
    nestingLevel,
    _contextBase = "",
    layoutObject = "row",
  ) =>
    `${layoutObject}.prop_search(prop_parent${nestingLevel ?? 0}, '${name}', scene, 'objects')`,
  file: getFileInputTemplate(),
  files: getFileInputTemplate(true),
  image: getFileInputTemplate(),
  images: getFileInputTemplate(true),
  collection: (
    {
      name,
      label,
      subItemDefaultValues,
      subItemProperties,
      subItemLabel,
      subItemLabelField,
      onAddSubItem,
      onRemoveSubItem,
    },
    pathPrefix,
    nestingLevel,
    contextBase = "",
    layoutObject = "row",
  ) => `
${layoutObject}.label(text='${label}:')
${layoutObject}.prop(prop_parent${nestingLevel ?? 0}, '${name}')
op = ${layoutObject}.operator('folded_paper_engine.add_item_operator', text='', icon='ADD', emboss=False)
op.context_object_path = f'${pathPrefix}'
op.prop_name = '${name}'
${onAddSubItem ? `op.on_add = ${onAddSubItem}` : ""}
op.context_base = '${contextBase}'
${
    `
${
      subItemDefaultValues ?
        subItemDefaultValues
          .map(
            ({key, value, valueIsFunction}) => `
new_default = op.defaults.add()
new_default.key = '${key}'
new_default.value = ${value}
new_default.value_is_function = ${valueIsFunction ? "True" : "False"}
`
          )
          .join("\n") :
        ""
    }   

${
      subItemProperties
        ? `
prop_value = get_value_by_path(prop_parent${nestingLevel ?? 0}, '${name}')
for idx${nestingLevel ?? 0}, sub_item${nestingLevel ?? 0} in enumerate(prop_value):
    box${nestingLevel ?? 0} = layout.box()
    box_row${nestingLevel ?? 0} = box${nestingLevel ?? 0}.row()
    ${
          subItemLabelField
            ? `box_row${nestingLevel ?? 0}.label(text=str(get_value_by_path(sub_item${nestingLevel ?? 0}, '${subItemLabelField}')))`
            : subItemLabel ? `box_row${nestingLevel ?? 0}.label(text='${subItemLabel}')` : ""
        }
    op = box_row${nestingLevel ?? 0}.operator('folded_paper_engine.remove_item_operator', text='', icon='X', emboss=False)
    op.context_object_path = f'${pathPrefix}'
    op.prop_name = '${name}'
    op.item_index = idx${nestingLevel ?? 0}
    ${onRemoveSubItem ? `op.on_remove = ${onRemoveSubItem}` : ""}
    op.context_base = '${contextBase}'
    
    ${subItemProperties
          .map(
            (sI) => `
    ${BlenderPanelProperty(
              sI,
              `${pathPrefix}.${name}`,
              nestingLevel ?? 0,
              1,
              `sub_item${nestingLevel ?? 0}`,
              `box${nestingLevel ?? 0}`,
              contextBase
            )}
`
          )
          .join("\n")}
`
        : ""
    }
 
    `
  }
`,
  object: (
    {
      name,
      label,
      subItemProperties,
    },
    pathPrefix,
    nestingLevel,
    contextBase = "",
    layoutObject = "row",
  ) => `
prop_value${nestingLevel ?? 0} = get_value_by_path(prop_parent${nestingLevel ?? 0}, '${name}')
${layoutObject}.prop(prop_value${nestingLevel ?? 0}, '${INTERNAL_PROPERTY_NAMES.FPE_INTERNAL_EXPANDED}', text="", icon='TRIA_RIGHT' if not prop_value${nestingLevel ?? 0}.${INTERNAL_PROPERTY_NAMES.FPE_INTERNAL_EXPANDED} else 'TRIA_DOWN', emboss=False)
${
    subItemProperties
      ? `
col${nestingLevel ?? 0} = ${layoutObject}.column(align=True)
col${nestingLevel ?? 0}.label(text='${name}:')
if prop_value${nestingLevel ?? 0}.${INTERNAL_PROPERTY_NAMES.FPE_INTERNAL_EXPANDED}:
${subItemProperties
        .map(
          (sI) => `
${BlenderPanelProperty(
            sI,
            `${pathPrefix}.${name}`,
            (nestingLevel ?? 0) + 1,
            1,
            `prop_value${nestingLevel ?? 0}`,
            `col${nestingLevel ?? 0}`,
            contextBase,
            true,
          )}
`
        )
        .join("\n")}
`
      : ""
  }
`,
  hidden: () => "",
  operator: (
    {name, label, operatorType},
    pathPrefix,
    _nestingLevel,
    contextBase = "",
    layoutObject = "row",
  ) => `
op = ${layoutObject}.operator('${operatorType}', text='${label}')
op.context_object_path = f'${pathPrefix}'
op.prop_name = '${name}'
op.context_base = '${contextBase}'
    `,
  color: (
    {name},
    _pathPrefix,
    nestingLevel,
    _contextBase = "",
    layoutObject = "row",
  ) => `${layoutObject}.prop(prop_parent${nestingLevel ?? 0}, '${name}')`,
};

export const BlenderPanelProperty = (
  prop: BlenderPanelPropertyProps,
  pathPrefix: string,
  nestingLevel: number,
  indentLevel: number = 0,
  propParent?: string,
  layoutObject: string = "layout",
  contextBase: string = "",
  propParentIsObject: boolean = false,
) => {
  const {name, type, hidden = false, disableClearValue = false} = prop;
  const currentPath = propParent && !propParentIsObject
    ? `${pathPrefix}.{idx${nestingLevel ?? 0}}`
    : pathPrefix;

  return hidden || type === "hidden"
    ? ""
    : addIndentDepth(
      `
row${nestingLevel ?? 0} = ${layoutObject}.row()
${
        !PropTypeOmitFromPropertyGroup[type] && !disableClearValue
          ? `
op = row${nestingLevel ?? 0}.operator('folded_paper_engine.clear_value_operator', text='', icon='X', emboss=False)
op.context_object_path = f'${currentPath}'
op.prop_name = '${name}'
op.context_base = '${contextBase}'
`
          : ""
      }
prop_parent${nestingLevel ?? 0} = ${
        propParent
          ? propParent
          : `get_value_by_path(context.${
            contextBase ? contextBase : "object"
          }, f'${currentPath}')`
      }
${
        InputTemplateMap[type]
          ? InputTemplateMap[type](prop, currentPath, nestingLevel ?? 0, contextBase, `row${nestingLevel ?? 0}`)
          : defaultInputTemplate(prop, currentPath, nestingLevel ?? 0, contextBase, `row${nestingLevel ?? 0}`)
      }

`,
      indentLevel
    );
};

export const BlenderPropertyGroupProperty = (
  prop: BlenderPanelPropertyProps,
  indentLevel = 0
) => {
  const {
    name,
    label,
    type,
    description,
    defaultValue,
    getter,
    setter,
    subType,
  } = prop;
  const hasDefaultValue = typeof defaultValue !== "undefined";
  const extraArgs = typeof PropTypeExtraArgsMap[type] === "string" ? PropTypeExtraArgsMap[type] : (
    PropTypeExtraArgsMap[type] instanceof Function ?
      PropTypeExtraArgsMap[type](prop) :
      undefined
  );
  const args = [
    `name="${label}"`,
    `description="${description}"`,
    hasDefaultValue ? `default=${defaultValue}` : "",
    extraArgs ? extraArgs : "",
    getter ? `get=${getter}` : "",
    setter ? `set=${setter}` : "",
    subType ? `type=${subType}` : "",
  ]
    .filter((a) => a.length > 0)
    .join(",\n");

  return addIndentDepth(
    `
${name}: bpy.props.${
      PropTypeMap[type as keyof typeof PropTypeMap] || PropTypeMap.string
    }(
${args}
)`,
    indentLevel
  );
};

export const BlenderPropertyGroup = (
  {name, properties = []}: BlenderPanelProps,
  indentLevel: number = 0
) =>
  addIndentDepth(
    `
class ${name}PropertyGroup(bpy.types.PropertyGroup):
${[
      {
        name: INTERNAL_PROPERTY_NAMES.FPE_INTERNAL_EXPANDED,
        label: "Expanded",
        description: "Whether the group is expanded or not",
        type: "boolean",
        defaultValue: "False",
        hidden: true,
      } as BlenderPanelPropertyProps,
      ...properties,
    ]
      .filter((p) => !PropTypeOmitFromPropertyGroup[p.type])
      .map((p) => BlenderPropertyGroupProperty(p, indentLevel + 1))
      .join("\n")}

`,
    indentLevel
  );

export type BlenderPanelProps = {
  name: string;
  label: string;
  space: string;
  region: string;
  category?: string;
  panelContext?: string;
  contextObject: string;
  registerOn?: string;
  additionalCode?: string;
  noPoll?: boolean;
  contextBase?: string;
  properties: BlenderPanelPropertyProps[];
  defaultOpen?: boolean;
  noPanel?: boolean;
};

export const BlenderPanel = (
  {
    name,
    label,
    space,
    region,
    category = "",
    panelContext = "",
    contextObject,
    additionalCode = "",
    noPoll = false,
    contextBase = "",
    properties = [],
    defaultOpen = false,
  }: BlenderPanelProps,
  indentLevel: number = 0,
  order: number = 1,
) =>
  addIndentDepth(
    `
class ${name}(bpy.types.Panel):
    bl_label = '${label}'
    bl_idname = '${name}'
    bl_space_type = '${space}'
    bl_region_type = '${region}'
    ${category ? `bl_category = '${category}'` : ""}
    ${panelContext ? `bl_context = '${panelContext}'` : ""}
    bl_order = ${order}
    bl_options = {'${defaultOpen ? "HEADER_LAYOUT_EXPAND" : "DEFAULT_CLOSED"}'}

    ${
      !noPoll
        ? `
    @classmethod
    def poll(cls, context):
        context_object = get_value_by_path(context.${
          contextBase ? contextBase : "object"
        }, '${contextObject}')
        return context_object is not None
    `
        : ""
    }
        
${addIndentDepth(additionalCode, 1)}

    def draw(self, context):
        layout = self.layout
        context_object = get_value_by_path(context.${
      contextBase ? contextBase : "object"
    }, '${contextObject}')
        scene = context.scene
        
${properties
      .map((p) =>
        BlenderPanelProperty(
          p,
          contextObject,
          0,
          indentLevel + 2,
          undefined,
          undefined,
          contextBase
        )
      )
      .join("\n")}

`,
    indentLevel
  );

export type BlenderAddonVersionNumber = {
  major: number;
  minor: number;
  patch: number;
};

export type BlenderAddonProps = {
  name: string;
  author: string;
  description: string;
  blender: BlenderAddonVersionNumber;
  version: BlenderAddonVersionNumber;
  location: string;
  warning: string;
  panels: BlenderPanelProps[];
};

export const BlenderAddon = ({
                               name,
                               author,
                               description,
                               blender,
                               version,
                               location,
                               warning,
                               panels,
                             }: BlenderAddonProps) =>
  `
import bpy
import os
from pathlib import Path
from bpy_extras.io_utils import ImportHelper 
from bpy.types import Operator, OperatorFileListElement
from bpy.props import CollectionProperty, StringProperty

bl_info = {
    "name": "${name}",
    "author": "${author}",
    "description": "${description}",
    "blender": (${blender.major}, ${blender.minor}, ${blender.patch}),
    "version": (${version.major}, ${version.minor}, ${version.patch}),
    "location": "${location}",
    "warning": "${warning}"
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

${panels.map((p) => BlenderPropertyGroup(p)).join("")}

${panels.filter(p => !p.noPanel).map((p, idx) => BlenderPanel(p, 0, idx + 1)).join("")}

def register():
    bpy.utils.register_class(DefaultsPropertyGroup)
    bpy.utils.register_class(AddItemOperator)
    bpy.utils.register_class(RemoveItemOperator)
    bpy.utils.register_class(FileBrowserItem)
    bpy.utils.register_class(FileBrowserOperator)
    bpy.utils.register_class(ClearValueOperator)
${addIndentDepth(
    panels
      .map((p) => `bpy.utils.register_class(${p.name}PropertyGroup)`)
      .join("\n"),
    1
  )}
${addIndentDepth(
    panels
      .filter(p => !p.noPanel)
      .map((p) => `bpy.utils.register_class(${p.name})`)
      .join("\n"),
    1
  )}
    # Context Object Property Group Setup
    bpy.types.Action.FPE_FRAME_COMMANDS = bpy.props.BoolProperty()
${addIndentDepth(
    panels
      .filter(p => !p.noPanel)
      .map(
        ({name, contextObject, registerOn = "Object"}) =>
          `bpy.types.${registerOn}.${contextObject
            .split(".")
            .pop()} = bpy.props.PointerProperty(type=${name}PropertyGroup)`
      )
      .join("\n"),
    1
  )}

def unregister():
    bpy.utils.unregister_class(DefaultsPropertyGroup)
    bpy.utils.unregister_class(AddItemOperator)
    bpy.utils.unregister_class(RemoveItemOperator)
    bpy.utils.unregister_class(FileBrowserItem)
    bpy.utils.unregister_class(FileBrowserOperator)
    bpy.utils.unregister_class(ClearValueOperator)
${addIndentDepth(
    panels
      .map((p) => `bpy.utils.unregister_class(${p.name}PropertyGroup)`)
      .join("\n"),
    1
  )}
${addIndentDepth(
    panels
      .filter(p => !p.noPanel)
      .map((p) => `bpy.utils.unregister_class(${p.name})`)
      .join("\n"),
    1
  )}
    # Context Object Property Group Teardown
    del bpy.types.Action.FPE_FRAME_COMMANDS
${addIndentDepth(
    panels
      .filter(p => !p.noPanel)
      .map(
        ({contextObject, registerOn = "Object"}) =>
          `del bpy.types.${registerOn}.${contextObject.split(".").pop()}`
      )
      .join("\n"),
    1
  )}

if __name__ == "__main__":
    register()
`
    .split("\n")
    .filter((l) => l.trim().length > 0)
    .join("\n");
