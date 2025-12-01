-- ============================================
-- Library Management System - Views and Triggers
-- ============================================
-- Author: Your Name
-- Date: December 2024
-- Description: Database views for quick access and triggers for automation
-- ============================================

USE LibraryManagementSystem;

-- ============================================
-- VIEWS
-- ============================================

-- View 1: Current Inventory
-- Purpose: Quick overview of all books and their availability
DROP VIEW IF EXISTS CurrentInventory;

CREATE VIEW CurrentInventory AS
SELECT 
    b.book_id,
    b.title,
    b.isbn,
    CONCAT(a.first_name, ' ', a.last_name) AS author,
    c.category_name,
    b.publication_year,
    b.publisher,
    b.total_copies,
    b.available_copies,
    (b.total_copies - b.available_copies) AS copies_on_loan,
    CASE 
        WHEN b.available_copies = 0 THEN 'Not Available'
        WHEN b.available_copies <= 2 THEN 'Low Stock'
        ELSE 'Available'
    END AS availability_status,
    b.price
FROM Books b
LEFT JOIN Authors a ON b.author_id = a.author_id
LEFT JOIN Categories c ON b.category_id = c.category_id;

-- View 2: Active Members
-- Purpose: List all active members with their current loan status
DROP VIEW IF EXISTS ActiveMembersView;

CREATE VIEW ActiveMembersView AS
SELECT 
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    m.email,
    m.phone,
    m.membership_date,
    DATEDIFF(CURDATE(), m.membership_date) AS days_as_member,
    COUNT(l.loan_id) AS active_loans,
    COALESCE(SUM(CASE WHEN f.payment_status = 'Unpaid' THEN f.fine_amount ELSE 0 END), 0) AS unpaid_fines
FROM Members m
LEFT JOIN Loans l ON m.member_id = l.member_id AND l.status = 'Active'
LEFT JOIN Fines f ON m.member_id = f.member_id AND f.payment_status = 'Unpaid'
WHERE m.membership_status = 'Active'
GROUP BY m.member_id, member_name, m.email, m.phone, m.membership_date;

-- View 3: Overdue Loans
-- Purpose: Quick access to all overdue loans with member contact info
DROP VIEW IF EXISTS OverdueLoansView;

CREATE VIEW OverdueLoansView AS
SELECT 
    l.loan_id,
    b.title AS book_title,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    m.email,
    m.phone,
    l.loan_date,
    l.due_date,
    DATEDIFF(CURDATE(), l.due_date) AS days_overdue,
    (DATEDIFF(CURDATE(), l.due_date) * 1.00) AS calculated_fine,
    COALESCE(f.fine_amount, 0) AS recorded_fine,
    COALESCE(f.payment_status, 'Not Recorded') AS payment_status
FROM Loans l
JOIN Books b ON l.book_id = b.book_id
JOIN Members m ON l.member_id = m.member_id
LEFT JOIN Fines f ON l.loan_id = f.loan_id
WHERE l.status = 'Overdue'
ORDER BY days_overdue DESC;

-- View 4: Book Popularity Ranking
-- Purpose: Rank books by borrowing frequency
DROP VIEW IF EXISTS BookPopularityView;

CREATE VIEW BookPopularityView AS
SELECT 
    b.book_id,
    b.title,
    CONCAT(a.first_name, ' ', a.last_name) AS author,
    c.category_name,
    COUNT(l.loan_id) AS times_borrowed,
    b.total_copies,
    b.available_copies,
    ROUND(COUNT(l.loan_id) / b.total_copies, 2) AS borrows_per_copy
FROM Books b
LEFT JOIN Loans l ON b.book_id = l.book_id
LEFT JOIN Authors a ON b.author_id = a.author_id
LEFT JOIN Categories c ON b.category_id = c.category_id
GROUP BY b.book_id, b.title, author, c.category_name, b.total_copies, b.available_copies
ORDER BY times_borrowed DESC;

-- View 5: Financial Summary
-- Purpose: Overview of fines and payments
DROP VIEW IF EXISTS FinancialSummaryView;

CREATE VIEW FinancialSummaryView AS
SELECT 
    DATE_FORMAT(f.fine_date, '%Y-%m') AS month,
    COUNT(f.fine_id) AS total_fines,
    SUM(f.fine_amount) AS total_fine_amount,
    SUM(CASE WHEN f.payment_status = 'Paid' THEN f.fine_amount ELSE 0 END) AS collected,
    SUM(CASE WHEN f.payment_status = 'Unpaid' THEN f.fine_amount ELSE 0 END) AS pending,
    SUM(CASE WHEN f.payment_status = 'Waived' THEN f.fine_amount ELSE 0 END) AS waived,
    ROUND(SUM(CASE WHEN f.payment_status = 'Paid' THEN f.fine_amount ELSE 0 END) * 100.0 / 
          NULLIF(SUM(f.fine_amount), 0), 2) AS collection_rate_percent
FROM Fines f
GROUP BY month
ORDER BY month DESC;

-- View 6: Daily Activity Dashboard
-- Purpose: Today's library activity snapshot
DROP VIEW IF EXISTS DailyActivityView;

CREATE VIEW DailyActivityView AS
SELECT 
    (SELECT COUNT(*) FROM Loans WHERE loan_date = CURDATE()) AS books_issued_today,
    (SELECT COUNT(*) FROM Loans WHERE return_date = CURDATE()) AS books_returned_today,
    (SELECT COUNT(*) FROM Loans WHERE status = 'Active') AS currently_active_loans,
    (SELECT COUNT(*) FROM Loans WHERE status = 'Overdue') AS total_overdue,
    (SELECT COUNT(*) FROM Members WHERE membership_status = 'Active') AS active_members,
    (SELECT SUM(available_copies) FROM Books) AS total_available_books,
    (SELECT COUNT(*) FROM Reservations WHERE status = 'Pending') AS pending_reservations,
    (SELECT COALESCE(SUM(fine_amount), 0) FROM Fines WHERE payment_status = 'Unpaid') AS total_unpaid_fines;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger 1: Auto-Update Overdue Status
-- Purpose: Automatically mark loans as overdue when due date passes
DELIMITER //

DROP TRIGGER IF EXISTS CheckOverdueLoans//

CREATE TRIGGER CheckOverdueLoans
BEFORE UPDATE ON Loans
FOR EACH ROW
BEGIN
    IF NEW.return_date IS NULL AND NEW.due_date < CURDATE() AND NEW.status != 'Overdue' THEN
        SET NEW.status = 'Overdue';
    END IF;
END//

DELIMITER ;

-- Trigger 2: Prevent Deleting Books with Active Loans
-- Purpose: Protect data integrity by preventing deletion of borrowed books
DELIMITER //

DROP TRIGGER IF EXISTS PreventBookDeletion//

CREATE TRIGGER PreventBookDeletion
BEFORE DELETE ON Books
FOR EACH ROW
BEGIN
    DECLARE active_loan_count INT;
    
    SELECT COUNT(*) INTO active_loan_count
    FROM Loans 
    WHERE book_id = OLD.book_id AND status IN ('Active', 'Overdue');
    
    IF active_loan_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot delete book: Active loans exist for this book';
    END IF;
END//

DELIMITER ;

-- Trigger 3: Log Member Status Changes
-- Purpose: Create audit trail for membership status changes
-- First create the audit table
DROP TABLE IF EXISTS MemberStatusAudit;

CREATE TABLE MemberStatusAudit (
    audit_id INT PRIMARY KEY AUTO_INCREMENT,
    member_id INT NOT NULL,
    old_status ENUM('Active', 'Inactive', 'Suspended'),
    new_status ENUM('Active', 'Inactive', 'Suspended'),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_member (member_id),
    INDEX idx_changed_at (changed_at)
);

DELIMITER //

DROP TRIGGER IF EXISTS LogMemberStatusChange//

CREATE TRIGGER LogMemberStatusChange
AFTER UPDATE ON Members
FOR EACH ROW
BEGIN
    IF OLD.membership_status != NEW.membership_status THEN
        INSERT INTO MemberStatusAudit (member_id, old_status, new_status)
        VALUES (NEW.member_id, OLD.membership_status, NEW.membership_status);
    END IF;
END//

DELIMITER ;

-- Trigger 4: Update Book Availability on Loan Return
-- Purpose: Ensure book availability is updated when loan status changes
DELIMITER //

DROP TRIGGER IF EXISTS UpdateBookOnReturn//

CREATE TRIGGER UpdateBookOnReturn
AFTER UPDATE ON Loans
FOR EACH ROW
BEGIN
    IF OLD.status != 'Returned' AND NEW.status = 'Returned' THEN
        UPDATE Books 
        SET available_copies = available_copies + 1
        WHERE book_id = NEW.book_id;
    END IF;
END//

DELIMITER ;

-- Trigger 5: Validate Member Email Format
-- Purpose: Ensure email addresses are properly formatted
DELIMITER //

DROP TRIGGER IF EXISTS ValidateMemberEmail//

CREATE TRIGGER ValidateMemberEmail
BEFORE INSERT ON Members
FOR EACH ROW
BEGIN
    IF NEW.email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid email format';
    END IF;
END//

DELIMITER ;

-- Trigger 6: Auto-Calculate Fine on Overdue
-- Purpose: Automatically create fine record when loan becomes overdue
DELIMITER //

DROP TRIGGER IF EXISTS AutoCreateFine//

CREATE TRIGGER AutoCreateFine
AFTER UPDATE ON Loans
FOR EACH ROW
BEGIN
    DECLARE fine_exists INT;
    DECLARE days_late INT;
    
    IF OLD.status != 'Overdue' AND NEW.status = 'Overdue' THEN
        -- Check if fine already exists for this loan
        SELECT COUNT(*) INTO fine_exists FROM Fines WHERE loan_id = NEW.loan_id;
        
        IF fine_exists = 0 THEN
            SET days_late = DATEDIFF(CURDATE(), NEW.due_date);
            
            INSERT INTO Fines (loan_id, member_id, fine_amount, fine_date, payment_status)
            VALUES (NEW.loan_id, NEW.member_id, days_late * 1.00, CURDATE(), 'Unpaid');
        END IF;
    END IF;
END//

DELIMITER ;

-- Trigger 7: Prevent Negative Available Copies
-- Purpose: Ensure available_copies never goes negative
DELIMITER //

DROP TRIGGER IF EXISTS CheckAvailableCopies//

CREATE TRIGGER CheckAvailableCopies
BEFORE UPDATE ON Books
FOR EACH ROW
BEGIN
    IF NEW.available_copies < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Available copies cannot be negative';
    END IF;
    
    IF NEW.available_copies > NEW.total_copies THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Available copies cannot exceed total copies';
    END IF;
END//

DELIMITER ;

-- ============================================
-- Display summary of views and triggers
-- ============================================
SELECT 'All views and triggers created successfully!' AS Status;

-- List all views
SELECT TABLE_NAME AS view_name
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'LibraryManagementSystem'
ORDER BY TABLE_NAME;

-- List all triggers
SELECT TRIGGER_NAME, EVENT_MANIPULATION, EVENT_OBJECT_TABLE
FROM INFORMATION_SCHEMA.TRIGGERS 
WHERE TRIGGER_SCHEMA = 'LibraryManagementSystem'
ORDER BY TRIGGER_NAME;
