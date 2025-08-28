extends RefCounted
class_name guiPlaceholderElements


static var noMatch:guiElement=guiElement.new(
	null,
	&"",
	[&"FailedAction",&"NoMatch"],
)
static var alreadyExists:guiElement=guiElement.new(
	null,
	&"",
	[&"FailedAction",&"AlreadyExists"],
)
static var generalFail:guiElement=guiElement.new(
	null,
	&"",
	[&"FailedAction",&"UnSpecified"],
)
