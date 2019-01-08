.386
.model flat,stdcall
option casemap:none

include ..\RequiredIncs.inc
include IoEXML.inc

.code

start:
	invoke GetModuleHandle, NULL
	mov hInstance,eax

	invoke GetCommandLine
	mov CommandLine, eax

	invoke InitCommonControls 
	mov icex.dwSize, sizeof INITCOMMONCONTROLSEX
	mov	icex.dwICC, ICC_DATE_CLASSES or ICC_USEREX_CLASSES or ICC_INTERNET_CLASSES\
				 or ICC_ANIMATE_CLASS or ICC_HOTKEY_CLASS or ICC_PAGESCROLLER_CLASS\
				 or ICC_COOL_CLASSES
	invoke InitCommonControlsEx, addr icex

	invoke WinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
	invoke ExitProcess, eax


WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL hwnd:HWND

	mov wc.cbSize, SIZEOF WNDCLASSEX
	mov wc.style, CS_HREDRAW or CS_VREDRAW
	mov wc.lpfnWndProc, OFFSET WndProc
	mov wc.cbClsExtra, NULL
	mov wc.cbWndExtra, NULL
	push hInstance
	pop wc.hInstance
	mov wc.hbrBackground, COLOR_BTNFACE + 1
	mov wc.lpszMenuName, NULL
	mov wc.lpszClassName, OFFSET szClassName
	
	invoke LoadIcon, NULL, IDI_APPLICATION
	mov wc.hIcon, eax
	mov wc.hIconSm, eax
	
	invoke LoadCursor, NULL, IDC_ARROW
	mov wc.hCursor, eax
	
	invoke RegisterClassEx, addr wc
	INVOKE CreateWindowEx, NULL, ADDR szClassName, ADDR szAppName,\
           WS_OVERLAPPEDWINDOW,\
           CW_USEDEFAULT, CW_USEDEFAULT, 225, 450,\
           NULL, NULL, hInst, NULL
	mov hwnd, eax
									
	invoke ShowWindow, hwnd, SW_SHOWNORMAL
	invoke UpdateWindow, hwnd
	
	.WHILE TRUE
		invoke GetMessage, ADDR msg,NULL,0,0
		.BREAK .IF (!eax)
		invoke TranslateMessage, ADDR msg
		invoke DispatchMessage, ADDR msg
	.ENDW
	
	mov eax, msg.wParam
	ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM			
	LOCAL pParsingErr: PIXMLDOMParseError					
   	LOCAL pAttribute: PIXMLDOMAttribute
   	LOCAL pAttributeOld: PIXMLDOMAttribute   	
   	LOCAL pElementSub: PIXMLDOMElement    
	LOCAL dwLine: DWORD
	LOCAL dwLinePos: DWORD
	LOCAL lpReason: DWORD
	LOCAL ErrorCode: DWORD
	LOCAL szMsgBuff[MAX_PATH]: BYTE					
	LOCAL bIsSuccessful: WORD
	LOCAL lpXMLBuff: DWORD
	LOCAL lpwXMLBuff: DWORD	
	LOCAL dwBuffSize: DWORD
	LOCAL bstr: BSTR
	LOCAL var: VARIANT
	LOCAL pElement:	PIXMLDOMElement	
			
	.IF uMsg == WM_DESTROY								
		coinvoke pRoot, IXMLDOMElement, Release								
		coinvoke pDoc, IXMLDOMDocument, Release											  	

		invoke PostQuitMessage, NULL				
		invoke CoUninitialize
		
	.ELSEIF uMsg == WM_CREATE
		invoke CoInitialize, NULL
		
		invoke CreateWindowEx, 0, StrM("SysTreeView32"), 0,\
				WS_CHILD or WS_VISIBLE or TVS_HASLINES or TVS_HASBUTTONS or TVS_LINESATROOT,\
				10, 10, 200, 400, hWnd, 0, hInstance, 0								
		mov	hTreeView, eax
		invoke SetWindowLong, hTreeView, GWL_WNDPROC, TreeViewProc
		mov	OldTreeViewProc, eax		

		invoke CoCreateInstance, addr CLSID_DOMDocument, NULL, CLSCTX_INPROC_SERVER or CLSCTX_LOCAL_SERVER, \
									addr IID_IXMLDOMDocument, addr pDoc
		
		coinvoke pDoc, IXMLDOMDocument, put_async, VARIANT_FALSE
				
		invoke AddChild, pDoc, StrM("root"), addr pRoot
		invoke SetNodeAttribute, pRoot, StrM("created"), StrM("using dom") 											

		invoke AddChild, pRoot, StrM("node1"), addr pElement				
		invoke SetNodeValue, pElement, StrM("Text1")
		invoke FreeNode, pElement
		  		
		invoke AddChild, pRoot, StrM("node2"), addr pElement				
		invoke SetNodeValue, pElement, StrM("Text2")
		invoke SetNodeAttribute, pElement, StrM("created"), StrM("using dom") 
		invoke FreeNode, pElement  		   			      	

   		invoke AddChild, pRoot, StrM("node3"), addr pElement
   		invoke AddChild, pElement, StrM("subnode1"), addr pElementSub				
		invoke FreeNode, pElementSub
		invoke AddChild, pElement, StrM("subnode2"), addr pElementSub				
		invoke FreeNode, pElementSub  		   			      	
		invoke AddChild, pElement, StrM("subnode3"), addr pElementSub				
		invoke FreeNode, pElementSub  		   			      	  		   			      
  				
   		coinvoke pDoc, IXMLDOMDocument, get_xml, addr bstr   		  
   		invoke MessageBoxW,0,bstr,0,0

   		mov var.vt, VT_BSTR
		invoke StrToBstr, addr filename
   		mov var.bstrVal, eax
   		coinvoke pDoc, IXMLDOMDocument, save, var

		invoke LoadXMLFile, addr filename	
		mov lpXMLBuff, eax	
		Invoke MultiByteToWideChar, CP_ACP, 0, lpXMLBuff, -1, lpwXMLBuff, 0
		.if eax != 0
			shl eax, 1
			mov dwBuffSize, eax
			inc eax			
			invoke GlobalAlloc, GPTR, eax
			mov lpwXMLBuff, eax
			Invoke MultiByteToWideChar, CP_ACP, 0, lpXMLBuff, -1, lpwXMLBuff, dwBuffSize
			invoke FreeBstr, addr bstr
			invoke GlobalFree, lpXMLBuff
		.else
			invoke FreeBstr, addr bstr
			invoke GlobalFree, lpXMLBuff
			ret
		.endif				
		coinvoke pDoc, IXMLDOMDocument, loadXML, lpwXMLBuff, addr bIsSuccessful				
		invoke GlobalFree, lpwXMLBuff							
		.if eax == S_OK
			invoke AddTreeViewNode, hTreeView, NULL, TVI_ROOT, StrM("XML Document")
			mov hRoot, eax
			coinvoke pDoc, IXMLDOMDocument, get_documentElement, addr pElement
			.if pElement			
				invoke ParseXML, hTreeView, pElement, hRoot
			.endif
			invoke SendMessage, hTreeView, TVM_EXPAND, TVE_EXPAND, hRoot 			
			
		.else								
			coinvoke pDoc, IXMLDOMDocument, get_parseError, addr pParsingErr			
			coinvoke pParsingErr, IXMLDOMParseError, get_line, addr dwLine
			coinvoke pParsingErr, IXMLDOMParseError, get_linepos, addr dwLinePos
			coinvoke pParsingErr, IXMLDOMParseError, get_reason, addr lpReason
			coinvoke pParsingErr, IXMLDOMParseError, get_errorCode, addr ErrorCode			
			invoke wsprintf, addr szMsgBuff, StrM("Error 0x%.8X on line %d, position %d"), ErrorCode, dwLine, dwLinePos
			invoke MessageBox, 0, addr szMsgBuff, 0, 0 			
			invoke SysFreeString, lpReason 						 	 
		.endif			   		
								  																						
	.else
		invoke DefWindowProc, hWnd, uMsg, wParam, lParam		
		ret
	.endif
	
	xor eax, eax
	ret
WndProc endp

TreeViewProc proc hWin:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

	mov	eax, uMsg

	.if(eax == WM_COMMAND)
	
	.elseif(eax == WM_LBUTTONDOWN)

	.elseif(eax == WM_LBUTTONUP)

	.elseif(eax == WM_LBUTTONDBLCLK)

	.elseif(eax == WM_RBUTTONDOWN)

	.endif

	invoke CallWindowProc, OldTreeViewProc, hWin, uMsg, wParam, lParam

	ret
TreeViewProc endp

AddTreeViewNode proc hWnd:HWND, hParentItem:DWORD, hInsertAfter:DWORD, pszText:DWORD
	LOCAL tvins: TV_INSERTSTRUCT

	m2m	tvins.hParent, hParentItem
	m2m	tvins.hInsertAfter, hInsertAfter	
	mov	tvins.item._mask, TVIF_TEXT
	m2m	tvins.item.pszText, pszText
	invoke SendMessage, hWnd, TVM_INSERTITEM, 0, addr tvins			
	ret
AddTreeViewNode endp

ParseXML proc hWnd:HWND, pNode:PIXMLDOMElement, ht:HTREEITEM
	LOCAL pChilds: PIXMLDOMNodeList 
	LOCAL pChildnode: PIXMLDOMNode	
	LOCAL s: BSTR
	LOCAL pszBuff: DWORD
	LOCAL lenBuff: DWORD
	LOCAL i: DWORD
	LOCAL iMax: DWORD
	LOCAL ht2: HTREEITEM
	LOCAL bhasChildNodes: WORD
	LOCAL dwChildsCount: DWORD	
					
	coinvoke pNode, IXMLDOMElement, get_nodeTypeString, addr s	
	invoke lstrcmpW, s, addr wszElement	
    .if eax == 0    	 
    	coinvoke pNode, IXMLDOMElement, get_nodeName, addr s
    	invoke BstrToStr, s				
		mov pszBuff, eax							
		invoke AddTreeViewNode, hWnd, ht, TVI_LAST, pszBuff
		mov ht2, eax  	
		invoke GlobalFree, pszBuff					
	.else
		invoke lstrcmpW, s, addr wszText
		.if eax == 0
			coinvoke pNode, IXMLDOMElement, get_text, addr s
			invoke BstrToStr, s				
			mov pszBuff, eax					
			invoke AddTreeViewNode, hWnd, ht, TVI_LAST, pszBuff
			mov ht2, eax  		
			invoke GlobalFree, pszBuff									
		.else		
			coinvoke pNode, IXMLDOMElement, get_nodeName, addr s			    
			invoke BstrToStr, s				
			mov pszBuff, eax			
			invoke AddTreeViewNode, hWnd, ht, TVI_LAST, pszBuff
			mov ht2, eax			
			invoke GlobalFree, pszBuff															
		.endif		
	.endif
			
	coinvoke pNode, IXMLDOMElement, hasChildNodes, addr bhasChildNodes 	
	.if bhasChildNodes					
		coinvoke pNode, IXMLDOMElement, get_childNodes, addr pChilds				
		coinvoke pChilds, IXMLDOMNodeList, get_length, addr dwChildsCount		  		
		m2m iMax, dwChildsCount		 
		mov i, 0				
		.while TRUE							
			coinvoke pChilds, IXMLDOMNodeList, get_item, i, addr pChildnode									
			invoke ParseXML, hWnd, pChildnode, ht2
			inc i
			mov ebx, iMax
			cmp i, ebx
			je Exit
		.endw		
	.endif
Exit:	
    ret
ParseXML endp

LoadXMLFile proc lpFileName:DWORD
	LOCAL hFile: DWORD
	LOCAL lpBuff: DWORD
	LOCAL dwRead: DWORD
	
	invoke CreateFile, lpFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING,\
											FILE_ATTRIBUTE_NORMAL, 0
	.if eax != INVALID_HANDLE_VALUE
		mov	hFile, eax
		invoke GetFileSize, hFile, NULL
		push eax
		inc	eax
		invoke GlobalAlloc, GPTR, eax
		mov	lpBuff, eax
		invoke GlobalLock, lpBuff
		pop	edx
		invoke ReadFile, hFile, lpBuff, edx, addr dwRead, NULL
		invoke CloseHandle, hFile
		mov eax, lpBuff		
	.else
		invoke MessageBox, NULL, StrM("Can not Open XML File"), addr szAppName, \
									MB_OK or MB_ICONERROR
		mov	eax, FALSE
	.endif
	ret

LoadXMLFile endp

AppendChildToParent proc pChild:PIXMLDOMNode, pParent:PIXMLDOMNode
    LOCAL pNode: PIXMLDOMNode
    
    coinvoke pParent, IXMLDOMNode, appendChild, pChild, addr pNode
    .if eax != S_OK
    	.if pNode
    		coinvoke pNode, IXMLDOMNode, Release 
    	.endif
    .endif
    ret
AppendChildToParent endp

AddChild proc pParent:PIXMLDOMElement, NodeName:DWORD, ppChild:PPIXMLDOMElement	 
	LOCAL bstr: BSTR		
		
	invoke StrToBstr, NodeName
	mov bstr, eax		
   	coinvoke pDoc, IXMLDOMDocument, createElement, bstr, ppChild
   	invoke FreeBstr, addr bstr	
   	mov eax, ppChild
   	mov eax, [eax]   	  
   	invoke AppendChildToParent, eax, pParent	
	ret
AddChild endp

SetNodeValue proc pNode:PIXMLDOMNode, Value:DWORD
	LOCAL bstr: BSTR
	
	invoke StrToBstr, Value
	mov bstr, eax
	coinvoke pNode, IXMLDOMNode, put_text, bstr
	invoke FreeBstr, addr bstr   
	ret		   			
SetNodeValue endp

SetNodeAttribute proc pNode:PIXMLDOMElement, Attribute:DWORD, Value:DWORD
	LOCAL pAttribute: PIXMLDOMAttribute
   	LOCAL pAttributeOld: PIXMLDOMAttribute   		
	LOCAL bstr: BSTR
	LOCAL var: VARIANT
	
	invoke StrToBstr, Attribute
	mov bstr, eax
	mov var.vt, VT_BSTR		
	invoke StrToBstr, Value 
   	mov var.bstrVal, eax   		
   		   		
  	coinvoke pDoc, IXMLDOMDocument, createAttribute, bstr, addr pAttribute  		  		   		   		
 	coinvoke pAttribute, IXMLDOMAttribute, put_value, var 		
   	coinvoke pNode, IXMLDOMElement, setAttributeNode, pAttribute, addr pAttributeOld   	
   	invoke FreeBstr, addr bstr  		   		
  	.if pAttributeOld
    	coinvoke pAttributeOld, IXMLDOMAttribute, Release
    	mov pAttributeOld, NULL
   	.endif
   	coinvoke pAttribute, IXMLDOMAttribute, Release
    mov pAttribute, NULL
   	invoke VariantClear, addr var		
	ret
SetNodeAttribute endp

FreeNode proc pNode:PIXMLDOMNode
	coinvoke pNode, IXMLDOMNode, Release
   	mov pNode, NULL
   	ret
FreeNode endp

end start
