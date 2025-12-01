-- ============================================
-- Library Management System - Database Schema
-- ============================================
-- Author: Your Name
-- Date: December 2024
-- Description: Complete database schema for library management system
-- ============================================

-- Create database
DROP DATABASE IF EXISTS LibraryManagementSystem;
CREATE DATABASE LibraryManagementSystem;
USE LibraryManagementSystem;

-- ============================================
-- Table: Authors
-- Description: Stores information about book authors
-- ============================================
CREATE TABLE Authors (
    author_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_year INT,
    nationality VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_author_name (last_name, first_name)
);

-- ============================================
-- Table: Categories
-- Description: Book categories and classifications
-- ============================================
CREATE TABLE Categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- Table: Books
-- Description: Main book inventory with availability tracking
-- ============================================
CREATE TABLE Books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(200) NOT NULL,
    isbn VARCHAR(13) UNIQUE NOT NULL,
    author_id INT,
    category_id INT,
    publication_year INT,
    publisher VARCHAR(100),
    total_copies INT DEFAULT 1,
    available_copies INT DEFAULT 1,
    price DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES Authors(author_id) ON DELETE SET NULL,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id) ON DELETE SET NULL,
    INDEX idx_title (title),
    INDEX idx_isbn (isbn),
    INDEX idx_author (author_id),
    INDEX idx_category (category_id),
    CHECK (available_copies >= 0),
    CHECK (available_copies <= total_copies)
);

-- ============================================
-- Table: Members
-- Description: Library member profiles and status
-- ============================================
CREATE TABLE Members (
    member_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    address TEXT,
    membership_date DATE NOT NULL,
    membership_status ENUM('Active', 'Inactive', 'Suspended') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_member_email (email),
    INDEX idx_member_status (membership_status),
    INDEX idx_member_name (last_name, first_name)
);

-- ============================================
-- Table: Staff
-- Description: Library staff information
-- ============================================
CREATE TABLE Staff (
    staff_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    position VARCHAR(50),
    hire_date DATE NOT NULL,
    salary DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_staff_email (email),
    INDEX idx_staff_position (position)
);

-- ============================================
-- Table: Loans
-- Description: Book borrowing records with status tracking
-- ============================================
CREATE TABLE Loans (
    loan_id INT PRIMARY KEY AUTO_INCREMENT,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    staff_id INT,
    loan_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    status ENUM('Active', 'Returned', 'Overdue') DEFAULT 'Active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES Members(member_id) ON DELETE CASCADE,
    FOREIGN KEY (staff_id) REFERENCES Staff(staff_id) ON DELETE SET NULL,
    INDEX idx_loan_status (status),
    INDEX idx_loan_member (member_id),
    INDEX idx_loan_book (book_id),
    INDEX idx_loan_dates (loan_date, due_date),
    CHECK (due_date > loan_date),
    CHECK (return_date IS NULL OR return_date >= loan_date)
);

-- ============================================
-- Table: Fines
-- Description: Overdue fines and payment tracking
-- ============================================
CREATE TABLE Fines (
    fine_id INT PRIMARY KEY AUTO_INCREMENT,
    loan_id INT NOT NULL,
    member_id INT NOT NULL,
    fine_amount DECIMAL(10, 2) NOT NULL,
    fine_date DATE NOT NULL,
    payment_status ENUM('Unpaid', 'Paid', 'Waived') DEFAULT 'Unpaid',
    payment_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (loan_id) REFERENCES Loans(loan_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES Members(member_id) ON DELETE CASCADE,
    INDEX idx_fine_status (payment_status),
    INDEX idx_fine_member (member_id),
    CHECK (fine_amount >= 0),
    CHECK (payment_date IS NULL OR payment_date >= fine_date)
);

-- ============================================
-- Table: Reservations
-- Description: Book reservation queue for unavailable books
-- ============================================
CREATE TABLE Reservations (
    reservation_id INT PRIMARY KEY AUTO_INCREMENT,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    reservation_date DATE NOT NULL,
    status ENUM('Pending', 'Fulfilled', 'Cancelled') DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (book_id) REFERENCES Books(book_id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES Members(member_id) ON DELETE CASCADE,
    INDEX idx_reservation_status (status),
    INDEX idx_reservation_book (book_id),
    INDEX idx_reservation_member (member_id)
);

-- ============================================
-- Display schema information
-- ============================================
SELECT 'Database schema created successfully!' AS Status;
SELECT 'Total tables created: 8' AS Info;

-- Show all tables
SHOW TABLES;
