; #########################################################################

      .386
      .model flat, stdcall  ; 32 bit memory model
      option casemap :none  ; case sensitive

      include GbaBmp.inc     ; local includes for this file

.data
fileopen dd 0
bmpointer dd 0
titlename db 'AGB Bitmap Converter - '
titlename2 db 50 dup(0)
BMPwid dd 0
BMPhei dd 0
BMPpal dd 0
BMPpix dd 0
hWnd2 dd 0
taunt dd 0
stringgen db 10 dup(0)
strstk db 9 dup(0)
paintstring db 200 dup(0)
secradio dd 0

            sel5b db "Bits: &  ",0
            sel5c db "Width: &      Height: &      ",0

hfilepal dd 0
hfilebin dd 0
filewritebuffer dd 0
temp1 dd 0
temp2 dd 0
onetile dd 16 dup(0)
           

; #########################################################################

.code

start:
      invoke GetModuleHandle, NULL
      mov hInstance, eax

      invoke GetCommandLine
      mov CommandLine, eax

      invoke WinMain,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
      invoke ExitProcess,eax

; #########################################################################

WinMain proc hInst     :DWORD,
             hPrevInst :DWORD,
             CmdLine   :DWORD,
             CmdShow   :DWORD

      ;====================
      ; Put LOCALs on stack
      ;====================

      LOCAL wc   :WNDCLASSEX
      LOCAL msg  :MSG
      LOCAL Wwd  :DWORD
      LOCAL Wht  :DWORD
      LOCAL Wtx  :DWORD
      LOCAL Wty  :DWORD

      ;==================================================
      ; Fill WNDCLASSEX structure with required variables
      ;==================================================

      invoke LoadIcon,hInst,500    ; icon ID
      mov hIcon, eax

      szText szClassName,"Project_Class"

      mov wc.cbSize,         sizeof WNDCLASSEX
      mov wc.style,          CS_HREDRAW or CS_VREDRAW \
                             or CS_BYTEALIGNWINDOW
      mov wc.lpfnWndProc,    offset WndProc
      mov wc.cbClsExtra,     NULL
      mov wc.cbWndExtra,     NULL
      m2m wc.hInstance,      hInst
      mov wc.hbrBackground,  COLOR_BTNFACE+1
      mov wc.lpszMenuName,   NULL
      mov wc.lpszClassName,  offset szClassName
      m2m wc.hIcon,          hIcon
        invoke LoadCursor,NULL,IDC_ARROW
      mov wc.hCursor,        eax
      m2m wc.hIconSm,        hIcon

      invoke RegisterClassEx, ADDR wc

      ;================================
      ; Centre window at following size
      ;================================

      mov Wwd, 300
      mov Wht, 75

      invoke GetSystemMetrics,SM_CXSCREEN
      invoke TopXY,Wwd,eax
      mov Wtx, eax

      invoke GetSystemMetrics,SM_CYSCREEN
      invoke TopXY,Wht,eax
      mov Wty, eax

      invoke CreateWindowEx,WS_EX_LEFT,
                            ADDR szClassName,
                            ADDR szDisplayName,
                            WS_OVERLAPPED or WS_SYSMENU,
                            Wtx,Wty,Wwd,Wht,
                            NULL,NULL,
                            hInst,NULL
      mov   hWnd,eax

      invoke LoadMenu,hInst,600  ; menu ID
      invoke SetMenu,hWnd,eax

      invoke ShowWindow,hWnd,SW_SHOWNORMAL
      invoke UpdateWindow,hWnd

      ;===================================
      ; Loop until PostQuitMessage is sent
      ;===================================

    StartLoop:
      invoke GetMessage,ADDR msg,NULL,0,0
      cmp eax, 0
      je ExitLoop
      invoke TranslateMessage, ADDR msg
      invoke DispatchMessage,  ADDR msg
      jmp StartLoop
    ExitLoop:

      return msg.wParam

WinMain endp

; #########################################################################

WndProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD







    LOCAL var    :DWORD
    LOCAL var2   :DWORD
    LOCAL var3   :DWORD
    LOCAL caW    :DWORD
    LOCAL caH    :DWORD
    LOCAL Rct    :RECT
    LOCAL hDC    :DWORD
    LOCAL Ps     :PAINTSTRUCT

    LOCAL buffer1[128]:BYTE  ; these are two spare buffers
    LOCAL buffer2[256]:BYTE  ; for text manipulation etc..

    .if uMsg == WM_COMMAND
    ;======== menu commands ========
        .if wParam == 1000
           jmp @F
             szTitleO   db "Open A Bitmap",0
             szFilterO  db "Bitmap Files",0,"*.BMP",0,0
           @@:
    
           invoke FillBuffer,ADDR szFileName,length szFileName,0
           invoke GetFileName,hWin,ADDR szTitleO,ADDR szFilterO
    
           cmp szFileName[0],0   ;<< zero if cancel pressed in dlgbox
           je @F
           ; file name returned in szFileName
          ; invoke MessageBox,hWin,ADDR szFileName,
          ;                   ADDR szDisplayName,MB_OK

            invoke CreateFile,ADDR szFileName,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_FLAG_SEQUENTIAL_SCAN,NULL
            .if eax != INVALID_HANDLE_VALUE
               mov [var],eax
               invoke GetFileSize,eax,NULL
               mov [var2],eax 
               push eax
               invoke GlobalAlloc,GMEM_FIXED,eax
               pop edx               
               .if eax != NULL
                    mov [bmpointer],eax
                    mov ebx,[var]
                    
                    invoke ReadFile,ebx,eax,edx,addr fileopen,NULL

                    mov eax,[bmpointer]
                    mov bx,[eax]
                    mov ax,'MB'
                    .if ax == bx
                    mov eax,[fileopen]
                    mov ebx,[var2]
                    mov [fileopen],0
                    .if eax == ebx
                        mov [fileopen],1
                        mov ebx,[bmpointer]
                        mov eax,[ebx+10]
                        add eax,ebx
                        mov [BMPpix],eax
                        mov eax,[ebx+18]
                        mov [BMPwid],eax
                        mov eax,[ebx+22]
                        cmp eax,65536
                        jb ok3
                        mov edx,0
                        sub edx,eax
                        mov eax,edx
                        ok3:
                        mov [BMPhei],eax
                        xor eax,eax
                        mov ax,[ebx+28]
                        .if eax != 8
                      
                                .if eax != 24
                                    szText notbits,"Currently this program only supports 8-bit and 24-bit bitmaps... Please save your bitmap in one of these formats and try again."
                                    invoke MessageBox,hWin,ADDR notbits,ADDR szDisplayName,MB_OK
                                    jmp getoutfree
                                .endif
                      
                        .endif    
                        mov eax,[ebx+30]
                        .if eax != 0
                            szText notcomp,"Currently this program does not support compressed bitmaps... Please save your bitmap in a different format."
                            invoke MessageBox,hWin,ADDR notcomp,ADDR szDisplayName,MB_OK
                            jmp getoutfree
                        .endif

                        
                        mov eax,OFFSET szFileName
                        mov ebx,OFFSET szFileName
                        loopfix1:
                        inc eax
                        mov dl,[eax]
                        cmp dl,'\'
                        jnz loopfix2
                        mov ebx,eax
                        loopfix2:
                        cmp dl,0
                        jnz loopfix1
                        mov eax,OFFSET titlename2

                        loopfix3:
                        inc ebx
                        mov dl,[ebx]
                        cmp dl,'.'
                        jz loopfix4
                        mov [eax],dl
                        inc eax
                        jmp loopfix3
                        loopfix4:
                        mov bl,0
                        mov [eax],bl

                        invoke SetWindowText,hWin,ADDR titlename


                        mov edx,[BMPhei]
                        add edx,45
                        mov ebx,[BMPwid]
                        cmp ebx,300
                        ja okay4
                        mov ebx,300
                        okay4:



                        invoke SetWindowPos,hWin,HWND_TOP,0,0,ebx,edx,SWP_NOMOVE or SWP_NOCOPYBITS                       
                        mov [secradio],0
;                        invoke GetClientRect,hWin,ADDR Rct
;                        invoke InvalidateRect,hWin,ADDR Rct,TRUE
                        
                    .endif
                    .else

                    getoutfree:
                    mov eax,[bmpointer]
                    invoke GlobalFree,eax
                    mov [fileopen],0



                    .endif
               .endif
               mov eax,[var]
               invoke CloseHandle,eax
            .endif
            


           @@:

        .elseif wParam == 1001
  ; jmp shortcir
           jmp @F
             szTitleS   db "Save file as",0
             szFilterS  db "Binary File",0,"*.bin",0,0
           @@:
           .if fileopen == 1
    
           invoke FillBuffer,ADDR szFileName,length szFileName,0
           invoke SaveFileName,hWin,ADDR szTitleS,ADDR szFilterS
    
           cmp szFileName[0],0   ;<< zero if cancel pressed in dlgbox
           je @F
           ; file name returned in szFileName
           ;invoke MessageBox,hWin,ADDR szFileName,
           ;                  ADDR szDisplayName,MB_OK    
        szText DlgName,"MyDialog"
        shortcir:
	invoke DialogBoxParam, hInstance, ADDR DlgName,NULL,addr DlgProc,NULL



        
           @@:
           .else
            szText nobmpload,"You must load a bitmap before you can export it!  =P"
            invoke MessageBox,hWin,ADDR nobmpload,ADDR szDisplayName,MB_OK
            

            .endif

        .endif
        .if wParam == 1010
            invoke SendMessage,hWin,WM_SYSCOMMAND,SC_CLOSE,NULL
        .elseif wParam == 1900
            jmp @F
            aboutbox DB 'GBA-Bmp Version 1.00 by sgstair (sgstair@hotmail.com)',13,'Written in Pure Assembly language!!  =)',13,'(Check for the newest version of this and my other programs at http://gbdev.8k.com)',0
            @@:
            invoke MessageBox,hWin,ADDR aboutbox, ADDR szDisplayName,MB_OK
           
        .endif
    ;====== end menu commands ======

    .elseif uMsg == WM_CREATE

    .elseif uMsg == WM_SIZE

    .elseif uMsg == WM_PAINT
        invoke BeginPaint,hWin,ADDR Ps
          mov hDC, eax
          invoke Paint_Proc,hWin,hDC
        invoke EndPaint,hWin,ADDR Ps
        return 0

    .elseif uMsg == WM_CLOSE
       
    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
        return 0 
    .endif

    invoke DefWindowProc,hWin,uMsg,wParam,lParam

    ret

WndProc endp





DlgProc proc hWin   :DWORD,
             uMsg   :DWORD,
             wParam :DWORD,
             lParam :DWORD

        LOCAL   Rct:RECT
        LOCAL   hDC:DWORD
        LOCAL   Ps:PAINTSTRUCT

	.IF uMsg==WM_INITDIALOG
            mov [taunt],0
            szText txtButton,"button"
            szText wName1,"Export bitmap in Character mode (8x8 256color tiles)"
            szText wName2,"Export bitmap in Bitmapped Mode (8 bit)"
            szText wName3,"Export bitmap in Full-Color Bitmapped mode (16 bit)"
            mov ebx,[bmpointer]
            add ebx,28
            mov ax,[ebx]


        .if ax == 8
        
            invoke CreateWindowEx,NULL,ADDR txtButton,ADDR wName1,WS_CHILD or WS_VISIBLE or BS_AUTORADIOBUTTON,10,120,400,16,hWin,0,hInstance,NULL
            invoke CreateWindowEx,NULL,ADDR txtButton,ADDR wName2,WS_CHILD or WS_VISIBLE or BS_AUTORADIOBUTTON,10,145,400,16,hWin,1,hInstance,NULL
            invoke CreateWindowEx,NULL,ADDR txtButton,ADDR wName3,WS_CHILD or WS_VISIBLE or BS_AUTORADIOBUTTON,10,170,400,16,hWin,2,hInstance,NULL

        .else    
        
            invoke CreateWindowEx,NULL,ADDR txtButton,ADDR wName1,WS_CHILD or WS_VISIBLE or BS_AUTORADIOBUTTON or WS_DISABLED,10,120,400,16,hWin,0,hInstance,NULL
            invoke CreateWindowEx,NULL,ADDR txtButton,ADDR wName2,WS_CHILD or WS_VISIBLE or BS_AUTORADIOBUTTON or WS_DISABLED,10,145,400,16,hWin,1,hInstance,NULL
            invoke CreateWindowEx,NULL,ADDR txtButton,ADDR wName3,WS_CHILD or WS_VISIBLE or BS_AUTORADIOBUTTON,10,170,400,16,hWin,2,hInstance,NULL

        .endif
	
	.ELSEIF uMsg==WM_CLOSE
		invoke EndDialog, hWin,NULL
	.ELSEIF uMsg==WM_COMMAND
		mov eax,wParam
		.IF lParam==0
		
		.ELSE
			mov edx,wParam
			shr edx,16
			.if dx==BN_CLICKED
				.IF ax==9000
                            mov ebx,[bmpointer]
                            mov edx,[ebx+28]
                            mov ebx,[secradio]
                            .if ebx != 0
                            invoke ExportBM,edx,ebx,hWin
                            invoke EndDialog, hWin,NULL
                            .else
                            mov [taunt],1
                        invoke GetClientRect,hWin,ADDR Rct
                        invoke InvalidateRect,hWin,ADDR Rct,TRUE
                            .endif
                        .ELSEIF ax==9001
				invoke EndDialog, hWin,NULL
                        .elseif ax==0
                        mov [secradio],1
                        .elseif ax==1
                        mov [secradio],2
                        .elseif ax==2
                        mov [secradio],3
                        
				.ENDIF

                        invoke GetClientRect,hWin,ADDR Rct
                        invoke InvalidateRect,hWin,ADDR Rct,TRUE

			.ENDIF
		.ENDIF
	.ELSEIF uMsg==WM_PAINT

            invoke BeginPaint,hWin,ADDR Ps
            mov hDC, eax
            invoke SetBkMode,hDC,TRANSPARENT

            invoke GetClientRect,hWin,ADDR Rct
            mov eax,Rct.top
            mov ebx,Rct.left
            add eax,5
            add ebx,5
            mov Rct.top,eax
            mov Rct.left,ebx

 mov ebx,[bmpointer]
            add ebx,28
            xor eax,eax
            mov ax,[ebx]

            invoke makestr,eax,ADDR sel5b,6,ADDR strstk
;            sel5c db "Width: &      Height: &",0

            mov eax,[BMPwid]
            invoke makestr,eax,ADDR sel5c,7,ADDR strstk
            mov al,' '
            mov [ebx],al
            inc ebx
            mov [ebx],al
            inc ebx
            mov [ebx],al
            mov eax,[BMPhei]
            invoke makestr,eax,ADDR sel5c,22,ADDR strstk
            mov al,' '
            mov [ebx],al
            inc ebx
            mov [ebx],al
            inc ebx
            mov [ebx],al


            mov eax,[secradio]
            .if al==0
            szText nosel,"Select an export option to continue..."
            szText noselTaunt,"Come on... At least select an export option before you click export.",13,13,"Didn't you read the caption?",13,"Select an export option to continue..."
            mov eax,[taunt]
            .if eax==0
            invoke DrawText,hDC,ADDR nosel,-1,ADDR Rct,NULL
            .else
            invoke DrawText,hDC,addr noselTaunt,-1,addr Rct,NULL
            .endif
            .elseif al==1
            szText sel1a,"Exporting as 8x8 tiles in 256-color mode..."
            szText sel2a,"Exporting in 8-bit Bitmapped Mode..." 
            szText sel3a,"Exporting in 16-bit Bitmapped Mode..."
            szText xprt1,"Saving 1 file as .bin   Bitmapped graphics."
            szText xprt2,"Saving 2 files as .pal   512 byte Palette  and  .bin   Bitmapped Graphics"
            szText sel5a,"Source bitmap:"



            invoke DrawText,hDC,ADDR sel1a,-1,addr Rct,NULL
            mov eax,Rct.top
            add eax,14
            mov Rct.top,eax
            invoke DrawText,hDC,ADDR xprt2,-1,addr Rct,NULL
            mov eax,Rct.top
            add eax,14
            mov Rct.top,eax
            invoke DrawText,hDC,ADDR sel5a,-1,addr Rct,NULL
       
            mov eax,Rct.top
            add eax,14
            mov Rct.top,eax
            invoke DrawText,hDC,ADDR sel5b,-1,addr Rct,NULL
            mov eax,Rct.top
            add eax,14
            mov Rct.top,eax
            invoke DrawText,hDC,ADDR sel5c,-1,addr Rct,NULL
            

            .elseif al==2


            invoke DrawText,hDC,ADDR sel2a,-1,addr Rct,NULL
            mov eax,Rct.top
            add eax,14
            mov Rct.top,eax
            invoke DrawText,hDC,ADDR xprt2,-1,addr Rct,NULL
            mov eax,Rct.top
            add eax,14
            mov Rct.top,eax
            invoke DrawText,hDC,ADDR sel5a,-1,addr Rct,NULL
    
            mov eax,Rct.top
            add eax,14
            mov Rct.top,eax
            invoke DrawText,hDC,ADDR sel5b,-1,addr Rct,NULL
            mov eax,Rct.top
            add eax,14
            mov Rct.top,eax
            invoke DrawText,hDC,ADDR sel5c,-1,addr Rct,NULL
            

            .elseif al==3


            invoke DrawText,hDC,ADDR sel3a,-1,addr Rct,NULL
            mov eax,Rct.top
            add eax,14
            mov Rct.top,eax
            invoke DrawText,hDC,ADDR xprt1,-1,addr Rct,NULL
            mov eax,Rct.top
            add eax,14
            mov Rct.top,eax
            invoke DrawText,hDC,ADDR sel5a,-1,addr Rct,NULL
                       

            mov eax,Rct.top
            add eax,14
            mov Rct.top,eax
            invoke DrawText,hDC,ADDR sel5b,-1,addr Rct,NULL
            mov eax,Rct.top
            add eax,14
            mov Rct.top,eax
            invoke DrawText,hDC,ADDR sel5c,-1,addr Rct,NULL
            


            .endif

            invoke EndPaint,hWin,ADDR Ps
            return 0
            
      .ELSE
		mov eax,FALSE
		ret

	.ENDIF


mov eax,TRUE
ret


DlgProc endp



getbitmapblock proc loc:DWORD,xx:DWORD,yy:DWORD

local x1:dword
local y1:dword
local yadd:DWORD
push ecx
mov edx,loc

mov y1,0
ylo:
    mov x1,0
    xlo:
        mov eax,x1
        mov ebx,xx
        shl ebx,3
        add eax,ebx
        mov ebx,y1
        mov ecx,yy
        shl ecx,3
        add ebx,ecx
        invoke GetPix,ax,bx
               
        mov [edx],al
        inc edx
        inc [x1]
        mov eax,[x1]
        cmp eax,8
        jnz xlo
    inc [y1]
    mov eax,[y1]
    cmp eax,8
    jnz ylo
       
pop ecx
ret

getbitmapblock endp



ExportBM proc bits:DWORD,opt:DWORD,hWin:DWORD
LOCAL x1    :DWORD
LOCAL x2    :DWORD
local xf    :DWORD
local y1    :DWORD
local y2    :DWORD
local yf    :DWORD
local FileH :DWORD
local memH  :DWORD



mov ebx,OFFSET szFileName
looph1:
inc ebx
mov al,[ebx]
cmp al,'.'
jz looph2
cmp al,0
jz looph2
jmp looph1

looph2:
mov eax,'nib.'
mov [ebx],eax
add ebx,4
mov al,0
mov [ebx],al


.if opt==1
    .if bits==8


       invoke CreateFile,ADDR szFileName,GENERIC_WRITE,FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,NULL
        .if eax != INVALID_HANDLE_VALUE
        mov [hfilebin],eax
        mov ebx,[BMPpix]
        mov eax,[BMPhei]
        mov edx,[BMPwid]
        shr eax,3
        shr edx,3

        mov [xf],edx
        mov [yf],eax
               

        mov y1,0
        h8byloop:
            mov x1,0
            h8bxloop:
                mov eax,x1
                mov edx,y1
                invoke getbitmapblock,ADDR onetile,eax,edx

                push ebx
                mov eax,[hfilebin]
                invoke WriteFile,eax,ADDR onetile,64,ADDR temp1,NULL
                pop ebx

                inc [x1]
                mov edx,[xf]
                cmp [x1],edx
                jnz h8bxloop
            
            inc [y1]
            mov edx,[yf]
            cmp [y1],edx
            jnz h8byloop
            

        mov eax,[hfilebin]
        invoke CloseHandle,eax
        
        .else
        mov eax,2430
        jmp critikal
        .endif







mov ebx,OFFSET szFileName

looph1a:
inc ebx
mov al,[ebx]
cmp al,'.'
jz looph2a
cmp al,0
jz looph2a
jmp looph1a

looph2a:
mov eax,'lap.'
mov [ebx],eax
add ebx,4
mov al,0
mov [ebx],al

       invoke CreateFile,ADDR szFileName,GENERIC_WRITE,FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,NULL
        .if eax != INVALID_HANDLE_VALUE
            mov [hfilepal],eax
            mov edx,0
            palloopa:

            invoke BtoGBA,dl
                mov ebx, OFFSET filewritebuffer
                mov [ebx],al
                inc ebx
                mov [ebx],ah
                mov eax,[hfilepal]
                push edx
                invoke WriteFile,eax,ADDR filewritebuffer,2,ADDR temp1,NULL
                pop edx
                inc edx
                cmp edx,256
                jnz palloopa

               
            
            

        mov eax,[hfilebin]
        invoke CloseHandle,eax
        
        .else
        mov eax,2430
        jmp critikal
        .endif






    .else
    szText errora,"Error 580-a occurred.  Something happened that should never have happened...",13,"Please email sgstair@hotmail.com with the error number."
    invoke MessageBox,hWin,ADDR errora,ADDR szDisplayName,MB_OK
    .endif
.elseif opt==2
    .if bits==8
       invoke CreateFile,ADDR szFileName,GENERIC_WRITE,FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,NULL
        .if eax != INVALID_HANDLE_VALUE
        mov [hfilebin],eax
        mov ebx,[BMPpix]
        mov eax,[BMPhei]
        mov edx,[BMPwid]
        
        dec eax
        mul edx
        add ebx,eax
        mov y1,0
        a24byloop:
            mov x1,0
            a23bxloop:
                xor edx,edx
                xor eax,eax
                mov al,[ebx]
                inc ebx
                mov edx, OFFSET filewritebuffer
                mov [edx],al   
                mov eax,[hfilebin]
                push ebx
                invoke WriteFile,eax,ADDR filewritebuffer,1,ADDR temp1,NULL
                pop ebx
                inc [x1]
                mov edx,[BMPwid]

                cmp [x1],edx
                jnz a23bxloop
            
            shl edx,1
            sub ebx,edx
            inc [y1]
            mov edx,[BMPhei]
            cmp [y1],edx
            jnz a24byloop
            

        mov eax,[hfilebin]
        invoke CloseHandle,eax
        
        .else
        mov eax,2430
        jmp critikal
        .endif


mov ebx,OFFSET szFileName

looph1b:
inc ebx
mov al,[ebx]
cmp al,'.'
jz looph2b
cmp al,0
jz looph2b
jmp looph1b

looph2b:
mov eax,'lap.'
mov [ebx],eax
add ebx,4
mov al,0
mov [ebx],al

       invoke CreateFile,ADDR szFileName,GENERIC_WRITE,FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,NULL
        .if eax != INVALID_HANDLE_VALUE
            mov [hfilepal],eax
            mov edx,0
            palloopb:

            invoke BtoGBA,dl
                mov ebx, OFFSET filewritebuffer
                mov [ebx],al
                inc ebx
                mov [ebx],ah
                mov eax,[hfilepal]
                push edx
                invoke WriteFile,eax,ADDR filewritebuffer,2,ADDR temp1,NULL
                pop edx
                inc edx
                cmp edx,256
                jnz palloopb

               
            
            

        mov eax,[hfilebin]
        invoke CloseHandle,eax
        
        .else
        mov eax,2430
        jmp critikal
        .endif





    .else
    szText errorb,"Error 580-b occurred.  Something happened that should never have happened...",13,"Please email sgstair@hotmail.com with the error number."
    invoke MessageBox,hWin,ADDR errorb,ADDR szDisplayName,MB_OK
    .endif
.elseif opt==3
    .if bits==8
        invoke CreateFile,ADDR szFileName,GENERIC_WRITE,FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,NULL
        .if eax != INVALID_HANDLE_VALUE
        mov [hfilebin],eax
        mov ebx,[BMPpix]
        mov eax,[BMPhei]
        mov edx,[BMPwid]
        
        dec eax
        mul edx
        add ebx,eax
        mov y1,0
        a24cyloop:
            mov x1,0
            a23cxloop:
                xor edx,edx
                xor eax,eax
                mov al,[ebx]
                inc ebx

                invoke BtoGBA,al
                mov edx, OFFSET filewritebuffer
                mov [edx],ah
                inc edx
                mov [edx],al
                mov eax,[hfilebin]
                push ebx
                invoke WriteFile,eax,ADDR filewritebuffer,2,ADDR temp1,NULL
                pop ebx
                inc [x1]
                mov edx,[BMPwid]

                cmp [x1],edx
                jnz a23cxloop
            
            shl edx,1
            sub ebx,edx
            inc [y1]
            mov edx,[BMPhei]
            cmp [y1],edx
            jnz a24cyloop
            

        mov eax,[hfilebin]
        invoke CloseHandle,eax
        
        .else
        mov eax,2430
        jmp critikal
        .endif


mov ebx,OFFSET szFileName

looph1c:
inc ebx
mov al,[ebx]
cmp al,'.'
jz looph2c
cmp al,0
jz looph2c
jmp looph1c

looph2c:
mov eax,'lap.'
mov [ebx],eax
add ebx,4
mov al,0
mov [ebx],al

       invoke CreateFile,ADDR szFileName,GENERIC_WRITE,FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,NULL
        .if eax != INVALID_HANDLE_VALUE
            mov [hfilepal],eax
            mov edx,0
            palloopc:

            invoke BtoGBA,dl
                mov ebx, OFFSET filewritebuffer
                mov [ebx],al
                inc ebx
                mov [ebx],ah
                mov eax,[hfilepal]
                push edx
                invoke WriteFile,eax,ADDR filewritebuffer,2,ADDR temp1,NULL
                pop edx
                inc edx
                cmp edx,256
                jnz palloopc

               
            
            

        mov eax,[hfilebin]
        invoke CloseHandle,eax
        
        .else
        mov eax,2430
        jmp critikal
        .endif




    .elseif bits==24
        invoke CreateFile,ADDR szFileName,GENERIC_WRITE,FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,NULL
        .if eax != INVALID_HANDLE_VALUE
        mov [hfilebin],eax
        mov ebx,[BMPpix]
        mov eax,[BMPhei]
        mov edx,[BMPwid]
        
        dec eax
        mul edx
        mov edx,3
        mul edx
        add ebx,eax
        mov y1,0
        b24cyloop:
            mov x1,0
            b23cxloop:
                xor edx,edx
                xor eax,eax
                mov ah,[ebx]
                inc ebx
                mov al,[ebx]
                inc ebx
                mov dl,[ebx]
                inc ebx
                shl edx,16
                or eax,edx
                invoke DtoGBA,eax
                mov edx, OFFSET filewritebuffer
                mov [edx],ah
                inc edx
                mov [edx],al
                mov eax,[hfilebin]
                push ebx
                invoke WriteFile,eax,ADDR filewritebuffer,2,ADDR temp1,NULL
                pop ebx
                inc [x1]
                mov edx,[BMPwid]
                cmp [x1],edx
                jnz b23cxloop
            mov eax,6
            mul edx
            sub ebx,eax
            inc [y1]
            mov edx,[BMPhei]
            cmp [y1],edx
            jnz b24cyloop
            

        mov eax,[hfilebin]
        invoke CloseHandle,eax
        
        .else
        mov eax,2431
        jmp critikal
        .endif



    .else
    szText errorc,"Error 580-c occurred.  Something happened that should never have happened...",13,"Please email sgstair@hotmail.com with the error number."
    invoke MessageBox,hWin,ADDR errorc,ADDR szDisplayName,MB_OK
    .endif
.endif
ret


critikal:
szText horribleKritikal,"Oh, no!... Some awful bug jumped up and ate your file...",13,"Actually Something went wrong.  ",13,"Please email sgstair@hotmail.com!"

;invoke makestr,eax,ADDR horribleKritikal,92,ADDR strstk
szText bugstit,"bugsbugSbuGsbuGSbUgsbUgSbUGsbUGSBugsBugSBuGsBuGSBUgsBUgSBUGsBUGS"
invoke MessageBox,hWin,ADDR horribleKritikal,ADDR bugstit,MB_OK
ret


ExportBM endp

GetPix PROC x:WORD,y:WORD
push ebx
push edx
xor eax,eax
mov ax,y
mov ebx,[BMPhei]
dec ebx
sub ebx,eax
mov eax,[BMPwid]
mul ebx
xor ebx,ebx
mov bx,x
add ebx,eax
mov eax,[BMPpix]
add ebx,eax

mov al,[ebx]

pop edx
pop ebx
ret
GetPix endp




DtoGBA PROC pal:DWORD       ;00bbggrr
push ebx
mov ebx,pal
and ebx,000000ffh
shr ebx,3
mov eax,ebx
mov ebx,pal
and ebx,0000f800h
shr ebx,6
or eax,ebx
mov ebx,pal
and ebx,00f80000h
shr ebx,9
or eax,ebx
pop ebx
ret
DtoGBA endp

WtoGBA PROC pal:WORD
push ebx
xor eax,eax
mov ax,pal
mov ebx,eax
and eax,000003ffh
and ebx,0000f800h
shr ebx,1
or eax,ebx
pop ebx
ret
WtoGBA endp

BtoGBA PROC pal:BYTE
push ebx
push edx
mov ebx,[bmpointer]
add ebx,54
xor eax,eax
mov al,pal
shl eax,2
add ebx,eax
mov eax,[ebx]
;change eax (00rrggbb) to (00bbggrr)
mov ebx,eax
mov bh,bl
shr ebx,8
mov al,ah
mov ah,bl
shl eax,8
mov al,bh
mov edx,eax
invoke DtoGBA,edx

pop edx
pop ebx
ret
BtoGBA endp



makestr proc num:DWORD,address:DWORD,adder:WORD,strstx:DWORD


mov eax,num
push ecx
xor ecx,ecx
mov ebx,strstx

mks1:
    cmp eax,10
    jb mks3
    mov edx,10
    div dl
    mov [ebx],ah
    mov ah,0
    inc ebx
    jmp mks1
mks3:
mov [ebx],al
mov ecx,address
xor eax,eax
mov ax,adder
add ecx,eax
inc ebx
mks2:
    dec ebx
    mov al,[ebx]
    add al,'0'
    mov [ecx],al
    inc ecx
    cmp ebx,strstx
    jnz mks2
    
mov ebx,ecx
pop ecx
xor al,al
mov [ebx],al
ret



makestr endp




; ########################################################################

TopXY proc wDim:DWORD, sDim:DWORD

    shr sDim, 1      ; divide screen dimension by 2
    shr wDim, 1      ; divide window dimension by 2
    mov eax, wDim    ; copy window dimension into eax
    sub sDim, eax    ; sub half win dimension from half screen dimension

    return sDim

TopXY endp

; #########################################################################

Paint_Proc proc hWin:DWORD, hDC:DWORD

    LOCAL btn_hi   :DWORD
    LOCAL btn_lo   :DWORD
    LOCAL Rct      :RECT

    invoke GetSysColor,COLOR_BTNHIGHLIGHT
    mov btn_hi, eax

    invoke GetSysColor,COLOR_BTNSHADOW
    mov btn_lo, eax
    
    ;invoke MessageBox,hWin,ADDR szClassName,ADDr szClassName,MB_OK


    mov eax,[fileopen]
    .if eax == 1
         ; invoke MessageBox,hWin,ADDR szClassName,ADDr szClassName,MB_OK

        ;  mov ax,DIB_RGB_COLORS
        ;  push ax                       ;34     dib_rgb_colors      int
        ;  mov ebx,[bmpointer]
        ;  add ebx,14
        ;  push ebx                      ;32     bitmapinfoheader    dword
        ;  mov ebx,[BMPpix]
        ;  push ebx                      ;28     bmppix      dword
        ;  mov ebx,[BMPhei]
        ;  push bx                       ;24     bmphei      int
        ;  xor eax,eax
        ;  push ax                       ;22     0           int
        ;  push eax                      ;20     0,0         int,int
        ;  push ebx                      ;16     bmphei      dword
        ;  mov ebx,[BMPwid]
        ;  push ebx                      ;12     bmpwid      dword
        ;  push eax                      ;8      0,0         int,int
        ;  mov eax,hDC
        ;  push eax                      ;4      hdc         dword
        ;  call SetDIBitsToDevice
        ;  add esp,34
        mov ebx,[bmpointer]
        add ebx,14
                 invoke SetDIBitsToDevice,hDC,0,0,[BMPwid],[BMPhei],0,0,0,[BMPhei],[BMPpix],ebx,0


        .else
        
        invoke SetBkMode,hDC,TRANSPARENT
       invoke GetClientRect,hWin, ADDR Rct
       szText loadmess,"Load a Bitmap Image using File>Open"
       invoke DrawText,hDC,ADDR loadmess,-1,ADDR Rct,DT_CENTER 
       
       
          
        

    .endif

    return 0

Paint_Proc endp

; ########################################################################

end start
