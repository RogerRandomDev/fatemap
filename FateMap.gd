@tool
extends RefCounted
class_name FateMap
## a class that exists so i can group all my scripts
## together to prevent any collisions with other people

# NECESSARY
class MaterialService extends "res://services/MaterialService.gd":pass
class compilerService extends "res://services/compilerService.gd":pass

class ObjectModel extends "res://models/objectModel.gd":pass

class ObjectParameters extends "res://models/utility/objectParameterTypes.gd":pass
class ObjectDataResource extends "res://models/resources/objectDataResource.gd":pass
class ObjectPhysicalDataResource extends "res://models/resources/objectPhysicalDataResource.gd":pass

# EDITOR REQUIRED

class signalService extends "res://services/signalService.gd":pass



class GUIService extends "res://services/GUIService.gd":pass
class GUIToolbarService extends "res://services/GUIToolbarService.gd":pass

class InputService extends "res://services/InputService.gd":pass

class MeshEditService extends "res://services/MeshEditService.gd":pass
class ParameterService extends "res://services/ParameterService.gd":pass


class PhysicalObjectService extends "res://services/PhysicalObjectService.gd":pass
class StringVarTypedService extends "res://services/StringVarTypedService.gd":pass
class ToolMethodService extends "res://services/ToolMethodService.gd":pass
class UndoRedoService extends "res://services/UndoRedoService.gd":pass

class PhysicalObjectInputController extends "res://models/utility/physicalObjectInputController.gd":pass



class objectMeshModel extends "res://models/objectMeshModel.gd":pass
class PhysicalObjectModel extends "res://models/physicalObjectModel.gd":pass
class SpecializedCylinderMesh extends "res://models/specializedCylinderMesh.gd":pass

class meshEditMode extends "res://models/meshEditModes/meshEditMode.gd":pass
