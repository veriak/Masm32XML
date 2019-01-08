include ..\Macros.inc
include ..\Public.inc
include ..\XML.inc

WinMain 							proto :DWORD, :DWORD, :DWORD, :DWORD
TreeViewProc						proto :HWND, :UINT, :WPARAM, :LPARAM
AddTreeViewNode						proto :HWND, :DWORD, :DWORD, :DWORD
ParseXML							proto :HWND, :PIXMLDOMElement, :HTREEITEM 
LoadXMLFile 						proto :DWORD
AppendChildToParent 				proto :PIXMLDOMNode, :PIXMLDOMNode
AddChild 							proto :PIXMLDOMElement, :DWORD, :PPIXMLDOMElement
SetNodeValue						proto :PIXMLDOMNode, :DWORD
SetNodeAttribute					proto :PIXMLDOMElement, :DWORD, :DWORD
FreeNode							proto :PIXMLDOMNode

.data
   	szClassName						db "MainWinClass", 0		
  	szAppName						db "IoEXML Parser", 0	
	szTreeViewClass					db 'SysTreeView32', 0
	filename						db 'test1.xml', 0		
			
	wszElement						WORD L(<element\0>)
	wszText							WORD L(<text\0>)										

.data?
	icex 							INITCOMMONCONTROLSEX  <?>
    hInstance 						HINSTANCE	?
    CommandLine 					LPSTR 		?	 	
		
	hTreeView						DWORD	?
	OldTreeViewProc					DWORD	?	
	hRoot							DWORD 	?	
	pDoc							PIXMLDOMDocument	?
	pRoot							PIXMLDOMElement		?	