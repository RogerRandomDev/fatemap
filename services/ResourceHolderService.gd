extends RefCounted
class_name ResourceHolderService

static var heldResources:Array=[]


static func addResource(resource:Resource)->void:
	if heldResources.has(resource):return
	heldResources.push_back(resource)

static func removeResource(resource:Resource)->void:
	if not heldResources.has(resource):return
	heldResources.erase(resource)

static func getResources()->Array:
	return heldResources
