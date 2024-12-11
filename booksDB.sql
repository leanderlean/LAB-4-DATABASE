-- ================================PART 2 & 3 ==================================================================================
CREATE TABLE books (
  book_id SERIAL PRIMARY KEY, 
  title VARCHAR(250) NOT NULL,
  author VARCHAR(250) NOT NULL,
  ISBN VARCHAR(13) NOT NULL UNIQUE,  
  genre VARCHAR(250) NOT NULL,
  published_year VARCHAR(250) NOT NULL,
  quantity_available NUMERIC NOT NULL
);

INSERT INTO books (title, author, ISBN, genre, published_year, quantity_available)
VALUES 
    ('Filipino', 'Leander Galido', '1432556712398', 'Language', '2005', 20),
    ('Juan Tamad', 'Juan Gomez', '3126752340985', 'Kids Story', '1987', 40),
    ('NBA book', 'Stephen James', '4537652348093', 'Sport', '2013', 28);

SELECT * FROM books;

CREATE TABLE users (
  user_id SERIAL PRIMARY KEY, 
  full_name VARCHAR(250) NOT NULL,
  email_address VARCHAR(250) NOT NULL,
  membership_date DATE NOT NULL
);

INSERT INTO users (full_name, email_address, membership_date)
VALUES 
    ('Lourdes Win Galido', 'winsgalido@gmail.com', '2017-09-20'),
    ('Lynn Galido', 'lynngalido@gmail.com', '1998-10-05'),
    ('Erwin Galido', 'erwingalido@gmail.com', '1996-02-19');

SELECT * FROM users;

CREATE TABLE book_loans (
  user_id INT NOT NULL,
  ISBN VARCHAR(13) NOT NULL,
  loan_date DATE NOT NULL,
  return_date DATE NOT NULL,
  book_loan_status VARCHAR(20) NOT NULL CHECK (book_loan_status IN ('borrowed', 'returned', 'overdue')),
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (ISBN) REFERENCES books(ISBN)
);

INSERT INTO book_loans (user_id, ISBN, loan_date, return_date, book_loan_status)
VALUES 
    (1, '1432556712398', '2024-12-12', '2024-12-19', 'borrowed'),
    (2, '3126752340985', '2024-11-29', '2024-12-07', 'borrowed'),
    (3, '4537652348093', '2024-10-29', '2024-12-07', 'overdue');

SELECT * FROM book_loans;

-- borrowed books
SELECT b.title, b.author, bl.loan_date, bl.return_date, bl.book_loan_status
FROM book_loans bl
JOIN books b ON bl.ISBN = b.ISBN
WHERE bl.user_id = 1;

-- overdue books
SELECT u.full_name, b.title, bl.loan_date, bl.return_date, bl.book_loan_status
FROM book_loans bl
JOIN books b ON bl.ISBN = b.ISBN
JOIN users u ON bl.user_id = u.user_id
WHERE bl.return_date < CURRENT_DATE AND bl.book_loan_status = 'borrowed';


-- ====================================PART 4 =======================================

-- This function triggers if the book quantity is 0 or not enough quantity
CREATE OR REPLACE FUNCTION check_book_availability() 
RETURNS TRIGGER AS $$
BEGIN
  
  IF (SELECT quantity_available FROM books WHERE ISBN = NEW.ISBN) <= 0 THEN
    RAISE EXCEPTION 'No copies available for this book';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER prevent_borrowing_if_no_copies
  BEFORE INSERT ON book_loans
  FOR EACH ROW
  EXECUTE FUNCTION check_book_availability();

-- 2. Fast retrieval of overdue loans

-- Create indexes on columns to speed up the retrieval of overdue loans
CREATE INDEX idx_return_date ON book_loans(return_date);
CREATE INDEX idx_book_loan_status ON book_loans(book_loan_status);

-- Optimized query for retrieving overdue loans (using indexes)
EXPLAIN ANALYZE
SELECT u.full_name, b.title, bl.loan_date, bl.return_date, bl.book_loan_status
FROM book_loans bl
JOIN books b ON bl.ISBN = b.ISBN
JOIN users u ON bl.user_id = u.user_id
WHERE bl.return_date < CURRENT_DATE
  AND bl.book_loan_status = 'borrowed'
ORDER BY bl.return_date;