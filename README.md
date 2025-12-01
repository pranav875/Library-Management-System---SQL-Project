#  Library Management System - SQL Database Project

A comprehensive SQL database project demonstrating advanced database design, complex queries, stored procedures, and triggers for managing a complete library system.

![SQL](https://img.shields.io/badge/SQL-MySQL-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Complete-success)

##  Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Database Schema](#database-schema)
- [Installation](#installation)
- [Usage](#usage)
- [Query Examples](#query-examples)
- [Technologies Used](#technologies-used)
- [Project Structure](#project-structure)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)
- [License](#license)

##  Overview

This project implements a fully functional library management database system that handles:
- Book inventory management
- Member registration and tracking
- Loan processing and returns
- Fine calculation for overdue books
- Staff management
- Book reservations
- Comprehensive reporting and analytics

The database follows normalization principles and implements referential integrity through foreign key constraints.

## ✨ Features

### Core Functionality
-  **Book Management**: Track books, authors, categories, and inventory
-  **Member Management**: Maintain member profiles and membership status
-  **Loan System**: Issue and return books with automated tracking
-  **Fine Management**: Calculate and track overdue fines
-  **Reservation System**: Allow members to reserve currently unavailable books
-  **Staff Operations**: Manage library staff and track who processed each loan

### Advanced Features
- 📊 **Analytics Queries**: Popular books, member activity, revenue reports
- 🔄 **Stored Procedures**: Automated book issuing and return processes
- 👁️ **Views**: Simplified access to frequently used data
- ⚡ **Triggers**: Automatic updates for book availability and overdue status
- 📈 **Reporting**: Comprehensive reports for management decisions

## 🗄️ Database Schema

### Entity Relationship Overview

The database consists of 8 interconnected tables:

1. **Authors** - Author information and biography
2. **Categories** - Book categories and classifications
3. **Books** - Complete book inventory with availability tracking
4. **Members** - Library member profiles and status
5. **Staff** - Library staff information
6. **Loans** - Book borrowing records
7. **Fines** - Overdue fine tracking and payment status
8. **Reservations** - Book reservation queue

### Key Relationships

```
Authors (1) -----> (N) Books
Categories (1) --> (N) Books
Books (1) -------> (N) Loans
Members (1) -----> (N) Loans
Staff (1) -------> (N) Loans
Loans (1) -------> (1) Fines
Books (1) -------> (N) Reservations
Members (1) -----> (N) Reservations
```

##  Installation

### Prerequisites
- MySQL Server 8.0 or higher
- MySQL Workbench (optional, for GUI)
- Command line access or any SQL client

### Setup Steps

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/library-management-sql.git
cd library-management-sql
```

2. **Create the database**
```bash
mysql -u root -p < schema.sql
```

3. **Load sample data**
```bash
mysql -u root -p LibraryManagementSystem < sample_data.sql
```

4. **Create stored procedures and triggers**
```bash
mysql -u root -p LibraryManagementSystem < procedures.sql
mysql -u root -p LibraryManagementSystem < views_triggers.sql
```

### Alternative: Manual Setup

1. Open MySQL Workbench or your preferred SQL client
2. Execute `schema.sql` to create database and tables
3. Execute `sample_data.sql` to populate with test data
4. Execute `procedures.sql` to create stored procedures
5. Execute `views_triggers.sql` to create views and triggers

## 💻 Usage

### Basic Operations

**Issue a book to a member:**
```sql
CALL IssueBook(1, 1, 1);
-- Parameters: book_id, member_id, staff_id
```

**Return a book:**
```sql
CALL ReturnBook(1);
-- Parameter: loan_id
```

**View available books:**
```sql
SELECT * FROM CurrentInventory WHERE available_copies > 0;
```

**Check member's current loans:**
```sql
SELECT * FROM Loans 
WHERE member_id = 1 AND status = 'Active';
```

### Running Queries

All query examples are available in `queries.sql`. You can execute them individually or run the entire file:

```bash
mysql -u root -p LibraryManagementSystem < queries.sql
```

##  Query Examples

### Find Most Popular Books
```sql
SELECT 
    b.title,
    CONCAT(a.first_name, ' ', a.last_name) AS author,
    COUNT(l.loan_id) AS times_borrowed
FROM Books b
LEFT JOIN Loans l ON b.book_id = l.book_id
LEFT JOIN Authors a ON b.author_id = a.author_id
GROUP BY b.book_id
ORDER BY times_borrowed DESC
LIMIT 10;
```

### Check Overdue Books
```sql
SELECT 
    m.first_name, m.last_name,
    b.title,
    l.due_date,
    DATEDIFF(CURDATE(), l.due_date) AS days_overdue
FROM Loans l
JOIN Members m ON l.member_id = m.member_id
JOIN Books b ON l.book_id = b.book_id
WHERE l.status = 'Overdue';
```

### Member Activity Report
```sql
SELECT 
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    COUNT(l.loan_id) AS total_books_borrowed,
    SUM(CASE WHEN l.status = 'Overdue' THEN 1 ELSE 0 END) AS overdue_count,
    COALESCE(SUM(f.fine_amount), 0) AS total_fines
FROM Members m
LEFT JOIN Loans l ON m.member_id = l.member_id
LEFT JOIN Fines f ON m.member_id = f.member_id
GROUP BY m.member_id;













---

