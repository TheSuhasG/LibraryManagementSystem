DROP DATABASE IF EXISTS library_db;
CREATE DATABASE IF NOT EXISTS library_db;
USE library_db;

-- 1. Authors
CREATE TABLE IF NOT EXISTS Authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    author_name VARCHAR(100) NOT NULL
);

-- 2. Categories
CREATE TABLE IF NOT EXISTS Categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL UNIQUE
);

-- 3. Publishers
CREATE TABLE IF NOT EXISTS Publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    publisher_name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    phone VARCHAR(20)
);

-- 4. Books
CREATE TABLE IF NOT EXISTS Books (
    book_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(150) NOT NULL,
    author_id INT NOT NULL,
    category_id INT NOT NULL,
    publisher_id INT NOT NULL,
    isbn CHAR(13) NOT NULL UNIQUE,
    publish_year SMALLINT,
    total_copies INT NOT NULL DEFAULT 1,
    available_copies INT NOT NULL DEFAULT 1,
    CONSTRAINT fk_book_author FOREIGN KEY (author_id) REFERENCES Authors(author_id),
    CONSTRAINT fk_book_category FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    CONSTRAINT fk_book_publisher FOREIGN KEY (publisher_id) REFERENCES Publishers(publisher_id),
    CONSTRAINT chk_total_copies CHECK (total_copies >= 0),
    CONSTRAINT chk_available CHECK (available_copies >= 0 AND available_copies <= total_copies)
);

-- 5. Members
CREATE TABLE IF NOT EXISTS Members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    member_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    address TEXT,
    membership_type ENUM('Student', 'Faculty', 'Public') NOT NULL DEFAULT 'Student',
    join_date DATE NOT NULL
);

-- 6. Staff
CREATE TABLE IF NOT EXISTS Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    hire_date DATE NOT NULL
);

-- 7. Issue_Records
CREATE TABLE IF NOT EXISTS Issue_Records (
    issue_id INT AUTO_INCREMENT PRIMARY KEY,
    book_id INT NOT NULL,
    member_id INT NOT NULL,
    staff_id INT NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE NULL,
    CONSTRAINT fk_issue_book FOREIGN KEY (book_id) REFERENCES Books(book_id),
    CONSTRAINT fk_issue_member FOREIGN KEY (member_id) REFERENCES Members(member_id),
    CONSTRAINT fk_issue_staff FOREIGN KEY (staff_id) REFERENCES Staff(staff_id),
    CONSTRAINT chk_due_date CHECK (due_date >= issue_date),
    CONSTRAINT chk_return_date CHECK (return_date IS NULL OR return_date >= issue_date)
);

-- 8. Fines
CREATE TABLE IF NOT EXISTS Fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    issue_id INT NOT NULL UNIQUE,
    fine_amount DECIMAL(8,2) NOT NULL,
    fine_date DATE NOT NULL,
    paid TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_fine_issue FOREIGN KEY (issue_id) REFERENCES Issue_Records(issue_id),
    CONSTRAINT chk_fine_amount CHECK (fine_amount >= 0)
);

-- Triggers
DELIMITER $$

DROP TRIGGER IF EXISTS trg_after_issue$$
CREATE TRIGGER trg_after_issue
AFTER INSERT ON Issue_Records
FOR EACH ROW
BEGIN
    UPDATE Books
    SET available_copies = available_copies - 1
    WHERE book_id = NEW.book_id;
END$$

DROP TRIGGER IF EXISTS trg_after_return$$
CREATE TRIGGER trg_after_return
AFTER UPDATE ON Issue_Records
FOR EACH ROW
BEGIN
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        UPDATE Books
        SET available_copies = available_copies + 1
        WHERE book_id = NEW.book_id;

        IF NEW.return_date > NEW.due_date THEN
            INSERT INTO Fines (issue_id, fine_amount, fine_date)
            VALUES (NEW.issue_id, DATEDIFF(NEW.return_date, NEW.due_date) * 5, NEW.return_date);
        END IF;
    END IF;
END$$

DELIMITER ;

-- Views
CREATE VIEW available_books AS
SELECT b.book_id, b.title, a.author_name, c.category_name, b.available_copies
FROM Books b
JOIN Authors a ON b.author_id = a.author_id
JOIN Categories c ON b.category_id = c.category_id
WHERE b.available_copies > 0;

CREATE VIEW overdue_books AS
SELECT i.issue_id, m.member_name, b.title, i.issue_date, i.due_date,
       DATEDIFF(CURDATE(), i.due_date) AS days_overdue,
       DATEDIFF(CURDATE(), i.due_date) * 5 AS fine_so_far
FROM Issue_Records i
JOIN Members m ON i.member_id = m.member_id
JOIN Books b ON i.book_id = b.book_id
WHERE i.return_date IS NULL AND i.due_date < CURDATE();

-- SAMPLE DATA INSERTION
INSERT INTO Authors (author_name) VALUES 
('R. K. Narayan'), ('A. P. J. Abdul Kalam'), ('Yuval Noah Harari'), 
('Carl Sagan'), ('Abraham Silberschatz'), ('James Clear'), 
('Chetan Bhagat'), ('Ruskin Bond'), ('Stephen Hawking'), ('Eric Matthes');

INSERT INTO Categories (category_name) VALUES 
('Fiction'), ('Biography'), ('History'), ('Science'), ('Technology'), ('Self-Help');

INSERT INTO Publishers (publisher_name, city, phone) VALUES 
('Sunrise Publications', 'Bengaluru', '080-12345678'),
('Bluebird Press', 'New Delhi', '011-87654321'),
('Orchid Books', 'Mumbai', '022-33445566'),
('Greenleaf Publishers', 'Chennai', '044-99887766'),
('Meridian House', 'Kolkata', '033-55667788');

INSERT INTO Books (title, author_id, category_id, publisher_id, isbn, publish_year, total_copies, available_copies) VALUES 
('Malgudi Days', 1, 1, 1, '9780000000011', 1943, 4, 4),
('Wings of Fire', 2, 2, 2, '9780000000028', 1999, 5, 5),
('Sapiens', 3, 3, 3, '9780000000035', 2014, 3, 3),
('Cosmos', 4, 4, 4, '9780000000042', 1980, 1, 1),
('Database System Concepts', 5, 5, 5, '9780000000059', 2019, 4, 4),
('Atomic Habits', 6, 6, 1, '9780000000066', 2018, 3, 3),
('Five Point Someone', 7, 1, 2, '9780000000073', 2004, 4, 4),
('The Blue Umbrella', 8, 1, 3, '9780000000080', 1980, 2, 2),
('A Brief History of Time', 9, 4, 4, '9780000000097', 1988, 3, 3),
('Python Crash Course', 10, 5, 5, '9780000000103', 2015, 3, 3);

INSERT INTO Members (member_name, phone, email, membership_type, join_date) VALUES 
('Arun Kumar', '9876500001', 'arun.kumar@example.com', 'Student', '2026-06-15'),
('Priya Sharma', '9876500002', 'priya.sharma@example.com', 'Student', '2026-06-18'),
('Karthik Raja', '9876500003', 'karthik.raja@example.com', 'Faculty', '2026-06-20'),
('Divya Nair', '9876500004', 'divya.nair@example.com', 'Public', '2026-07-02'),
('Mohammed Faizal', '9876500005', 'faizal@example.com', 'Student', '2026-07-10'),
('Sneha Reddy', '9876500006', 'sneha.reddy@example.com', 'Student', '2026-07-15');

INSERT INTO Staff (staff_name, role, phone, email, hire_date) VALUES 
('Anita Joseph', 'Senior Librarian', '9811100001', 'anita@library.org', '2020-01-15'),
('Meena Krishnan', 'Assistant Librarian', '9811100002', 'meena@library.org', '2022-03-10');