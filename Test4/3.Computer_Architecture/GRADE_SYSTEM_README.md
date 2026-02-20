# Student Grade Management System - 8086 Assembly Project

## 🎓 Project Overview

A complete database management system for student records, written in 8086 assembly language. This project demonstrates data structure implementation, sorting algorithms, statistical analysis, and advanced I/O operations.

## 🚀 Key Features

### 1. **Student Record Management**
- Add new student records with ID, name, and three subject grades
- Store up to 10 students in memory
- Dynamic data entry with validation
- Structured data storage using arrays

### 2. **Display & Search Functionality**
- Display all students in formatted table
- Search by student ID
- Professional table formatting with headers
- Shows ID, Name, Math, Physics, Chemistry grades, GPA, and letter grade

### 3. **GPA Calculation**
- Automatic GPA calculation from three grades
- Precision: 2 decimal places (stored as integer * 100)
- Real-time calculation as grades are entered

### 4. **Class Statistics**
- Calculate class average GPA
- Find highest GPA in class
- Find lowest GPA in class
- Display total number of students

### 5. **Bubble Sort Algorithm**
- Sort students by GPA (descending order)
- Demonstrates sorting algorithm implementation
- Swaps all associated data (ID, name, grades, GPA)
- Optimized with early exit when sorted

### 6. **Report Card Generation**
- Professional formatted report cards
- Complete student information display
- Letter grade assignment (A, B, C, D, F)

### 7. **Grade Distribution Analysis**
- Count students in each grade category
- A (90-100), B (80-89), C (70-79), D (60-69), F (0-59)
- Statistical visualization of class performance

## 💻 Technical Implementation

### Data Structures
```assembly
- Student Records: Array-based structure
- IDs: Array of words (2 bytes each)
- Names: 21-byte strings (20 chars + null terminator)
- Grades: Three arrays of words
- GPA: Array of words (value * 100 for precision)
```

### Key Algorithms Implemented

1. **Bubble Sort**
   - Time Complexity: O(n²)
   - Sorts by GPA with complete record swapping
   - Early termination optimization

2. **Linear Search**
   - Search by student ID
   - Sequential traversal through array

3. **Statistical Calculations**
   - Average: Sum of all GPAs / count
   - Max/Min: Linear scan with comparison

4. **Number Base Conversion**
   - ASCII to decimal conversion
   - Decimal to ASCII for display
   - Floating-point simulation (GPA * 100)

### Memory Management

- **Data Segment**: Organized string tables and arrays
- **Stack Segment**: 256 bytes for procedure calls
- **Register Usage**: Efficient register allocation
  - SI/DI: Array indexing
  - CX: Loop counters
  - AX/BX: Arithmetic operations
  - DX: I/O operations

### Advanced Features

1. **String Input with Backspace**
   - Character-by-character reading
   - Backspace handling for editing
   - 20-character limit enforcement

2. **Formatted Output**
   - Fixed-width columns
   - Decimal alignment
   - Professional table borders

3. **Input Validation**
   - Number range checking (0-100 for grades)
   - Database capacity checking
   - Empty database handling

4. **Error Handling**
   - Database full notification
   - Student not found messages
   - Invalid input warnings

## 📊 Assembly Techniques Demonstrated

### Instructions Used
- **Arithmetic**: ADD, SUB, MUL, DIV, INC, DEC
- **Logical**: AND, XOR, CMP, TEST
- **Data Transfer**: MOV, XCHG, PUSH, POP, LEA
- **Shift**: SHL, SHR (for array indexing)
- **Control**: JE, JNE, JGE, JLE, LOOP, CALL, RET
- **String**: LODSB, STOSB (for name copying)

### Interrupt Services
- **INT 10h**: Video services (clear screen, cursor positioning)
- **INT 16h**: Keyboard services (wait for key, check key)
- **INT 21h**: DOS services (character I/O, string output)

### Programming Concepts
- **Modular Design**: 30+ separate procedures
- **Parameter Passing**: Via registers and memory
- **Stack Management**: Proper PUSH/POP sequences
- **Array Manipulation**: Index calculations, traversal
- **Loop Optimization**: Efficient CX-based loops

## 🎨 User Interface

- **Box-drawing characters**: ╔═╗║╚╝┌─┐│└┘
- **Status symbols**: ✓ (success), ✗ (error)
- **Color-coded headers**: Professional menu system
- **Formatted tables**: Aligned columns with separators
- **Clear feedback**: Success/error messages

## 🔧 How to Run

### Compilation (MASM):
```bash
masm grade_system.asm;
link grade_system.obj;
grade_system.exe
```

### Compilation (TASM):
```bash
tasm grade_system.asm
tlink grade_system.obj
grade_system.exe
```

### Using DOSBox:
```bash
# Mount directory
mount c c:\5th-year-eng-projects\Test4\3.Computer_Architecture
c:

# Compile and run
masm grade_system.asm;
link grade_system.obj;
grade_system.exe
```

## 📈 Sample Usage

1. **Add Students**: Select option 1, enter ID, name, and three grades
2. **View All**: Select option 2 to see all students in table format
3. **Search**: Select option 3 and enter student ID to find specific student
4. **Statistics**: Select option 4 for class averages and extremes
5. **Sort**: Select option 5 to sort by GPA (highest to lowest)
6. **Report**: Select option 6 for professional report card
7. **Distribution**: Select option 7 to see grade distribution chart

## 🎯 Educational Objectives Met

1. **Data Structure Design**: Array-based record storage
2. **Algorithm Implementation**: Sorting, searching, statistics
3. **I/O Programming**: Formatted input/output, validation
4. **Memory Management**: Efficient data organization
5. **Code Organization**: Modular, maintainable structure
6. **User Interface**: Professional, user-friendly design
7. **Error Handling**: Robust input validation

## 📚 Concepts Demonstrated

### Computer Architecture
- Register-level programming
- Memory addressing modes
- Stack operations
- Interrupt-driven I/O

### Software Engineering
- Top-down design
- Procedural decomposition
- Code reusability
- Documentation

### Algorithms
- Sorting (Bubble Sort)
- Searching (Linear Search)
- Statistical analysis
- Data validation

## 💡 Advanced Features vs. Basic Implementation

| Feature | Basic | Advanced (This Project) |
|---------|-------|------------------------|
| Data Storage | Single student | Multiple students (array) |
| Calculations | Simple average | GPA with precision |
| Output | Plain text | Formatted tables |
| Sorting | None | Bubble sort algorithm |
| Search | None | ID-based search |
| Statistics | None | Average, min, max |
| Error Handling | None | Comprehensive validation |
| UI | Simple | Professional with boxes |

## 🔥 Why This Impresses

- **1000+ lines** of assembly code
- **7 major features** integrated seamlessly
- **Sorting algorithm** implementation (shows algorithm knowledge)
- **Database concepts** in assembly language
- **Statistical analysis** capabilities
- **Professional UI** with error handling
- **Complete system** - not just a demo

---

**Project Type**: Database Management System  
**Language**: 8086 Assembly (MASM/TASM)  
**Complexity**: Advanced  
**Lines of Code**: ~1000+  
**Procedures**: 30+  
**Features**: 7 major modules
