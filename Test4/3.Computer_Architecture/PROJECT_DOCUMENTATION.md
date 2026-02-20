# 8086 System Utilities Suite - Professional Project Documentation

## 📋 Project Overview

A comprehensive system utilities suite written in pure 8086 assembly language, demonstrating advanced computer architecture concepts including interrupt handling, memory management, multi-base arithmetic, and real-time system monitoring.

## 🎯 Key Features

### 1. **System Information & Memory Status**
- Real-time memory availability detection using INT 12h
- Segment register display (CS, DS, SS)
- Demonstrates understanding of 8086 memory segmentation

### 2. **Precision Stopwatch Timer**
- Interactive start/stop/reset functionality
- Real-time counter with interrupt-based timing
- Keyboard input handling without blocking
- Shows mastery of INT 15h (timer) and INT 16h (keyboard) interrupts

### 3. **Multi-Base Calculator**
- Supports addition, subtraction, multiplication, and division
- Displays results in three formats:
  - Decimal (base 10)
  - Hexadecimal (base 16) with 0x prefix
  - Binary (base 2) - full 16-bit representation
- Division by zero protection
- Custom number input parsing

### 4. **Real-Time Memory Viewer**
- Live hexadecimal dump of data segment memory
- Address and value display
- Demonstrates direct memory access and manipulation

### 5. **CPU Performance Test**
- Executes 10,000 iterations of arithmetic operations
- Demonstrates loop optimization and register usage
- Shows understanding of CPU instruction cycles

## 🛠️ Technical Highlights

### Architecture Concepts Demonstrated

1. **Interrupt Service Routines (ISRs)**
   - INT 10h - Video services (screen clearing, cursor positioning)
   - INT 12h - Memory size detection
   - INT 15h - System services (timer delays)
   - INT 16h - Keyboard services
   - INT 21h - DOS services (I/O operations)

2. **Register Management**
   - Efficient use of general-purpose registers (AX, BX, CX, DX)
   - Stack operations (PUSH/POP) for register preservation
   - Segment registers (CS, DS, SS)

3. **Modular Programming**
   - 20+ separate procedures for code organization
   - Proper stack frame management
   - Reusable utility functions

4. **Number System Conversions**
   - Decimal to hexadecimal conversion algorithm
   - Decimal to binary conversion
   - ASCII to integer parsing

5. **Memory Organization**
   - .DATA segment with organized string tables
   - .CODE segment with structured procedures
   - .STACK segment for proper stack management

## 📝 Assembly Techniques Used

- **Bitwise Operations**: SHL, ROL, AND for bit manipulation
- **Arithmetic Instructions**: ADD, SUB, MUL, DIV with overflow handling
- **Conditional Jumps**: JE, JNE, JZ, JC for control flow
- **Loop Optimization**: Using CX register with LOOP instruction
- **String Operations**: Using LEA for effective address loading

## 🎨 User Interface Features

- Professional box-drawing characters (╔═╗║╚╝┌─┐│└┘)
- Color-coded menu system
- Clear screen management
- Formatted output with proper spacing
- Error handling and validation

## 🔧 Compilation Instructions

### Using MASM (Microsoft Macro Assembler):
```bash
masm pro.asm;
link pro.obj;
pro.exe
```

### Using TASM (Turbo Assembler):
```bash
tasm pro.asm
tlink pro.obj
pro.exe
```

### Using DOSBox (for modern systems):
```bash
# In DOSBox:
mount c c:\5th-year-eng-projects\Test4\3.Computer_Architecture
c:
masm pro.asm;
link pro.obj;
pro.exe
```

## 📊 Code Statistics

- **Total Lines**: ~650 lines of assembly code
- **Procedures**: 21 modular procedures
- **Features**: 5 major functional modules
- **Interrupts Used**: 5 different BIOS/DOS interrupts
- **Data Definitions**: 25+ string constants and variables

## 🎓 Educational Value

This project demonstrates:

1. **Low-level programming skills** - Direct hardware interaction
2. **Computer architecture understanding** - Memory, registers, interrupts
3. **Algorithm implementation** - Conversion algorithms, I/O handling
4. **Software engineering** - Code organization, modularity, documentation
5. **Problem-solving** - Multiple integrated features in one cohesive program

## 🚀 Advanced Concepts

- **Non-blocking input**: Using INT 16h function 01h to check for keypresses
- **Dynamic display updates**: Cursor positioning for real-time counter
- **Register preservation**: Proper PUSH/POP sequences in all procedures
- **Error handling**: Division by zero, invalid input validation
- **Memory efficiency**: Optimized string storage and variable usage

## 💡 Potential Enhancements

Future versions could include:
- Real-time clock display using INT 1Ah
- File system operations using INT 21h file services
- Graphics mode demonstrations using INT 10h
- Serial port communication
- Protected mode exploration

## 📖 References

- Intel 8086 Family User's Manual
- IBM PC BIOS Interrupt Reference
- DOS Programmer's Reference
- Art of Assembly Language Programming

---

**Author**: Computer Architecture Student  
**Course**: Computer Architecture & Organization  
**Date**: February 2026  
**Platform**: 8086/8088 Microprocessor  
**Assembler**: MASM/TASM Compatible
