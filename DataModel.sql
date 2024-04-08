------------------------------------------------------------------------------------
-- Data created by : Kidsadakorn Nuallaoong
-- University : Sripatum University
-- Degrees : Bachelors
-- Faculty : Technology
-- Major : Computer Engineer
-- Database : PostgreSQL
-- Use for example data model only
------------------------------------------------------------------------------------

-- Drop triggers
DROP TRIGGER IF EXISTS trg_update_progress ON Task;
DROP FUNCTION IF EXISTS UpdateProgress();
DROP TRIGGER IF EXISTS customer_age_trigger ON Customer;
DROP TRIGGER IF EXISTS employee_age_trigger ON Employee;

-- Drop tables
DROP TABLE IF EXISTS Task;
DROP TABLE IF EXISTS Project;
DROP TABLE IF EXISTS Requirement;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Employee;
DROP TABLE IF EXISTS Department;
DROP TABLE IF EXISTS Company;

-- Create Customer table
CREATE TABLE Customer (
    CustomerID VARCHAR(10) PRIMARY KEY NOT NULL,
    "First name" VARCHAR(50) NOT NULL,
    "Last name" VARCHAR(50) NOT NULL,
    Nationality VARCHAR(50) NOT NULL,
    Gender VARCHAR(50) CHECK (Gender IN ('Male', 'Female', 'Trans')) NOT NULL,
    Birthday DATE CHECK (Birthday >= '0001-01-01') NOT NULL,
    Age INT NOT NULL,
    Job VARCHAR(50) NOT NULL,
    "Phone number" VARCHAR(10) UNIQUE NOT NULL,
    Email VARCHAR(50) UNIQUE NOT NULL
);

-- Create Requirement table
CREATE TABLE Requirement (
    RID VARCHAR(10) PRIMARY KEY NOT NULL,
    Requirement TEXT NOT NULL,
    Fund MONEY NOT NULL,
    CustomerID VARCHAR(10) REFERENCES Customer(CustomerID) NOT NULL
);

-- Create Project table
CREATE TABLE Project (
    PID VARCHAR(10) PRIMARY KEY NOT NULL,
    "P name" VARCHAR(50) NOT NULL,
    Cost MONEY NOT NULL,
    RID VARCHAR(10) NOT NULL,
    "Start date" TIMESTAMP NOT NULL,
    "End date" TIMESTAMP NOT NULL,
    Progress NUMERIC(5,2) DEFAULT 0.00 NOT NULL,
    FOREIGN KEY (RID) REFERENCES Requirement(RID)
);

-- Create Company table
CREATE TABLE Company (
    CID VARCHAR(10) PRIMARY KEY NOT NULL,
    "C name" VARCHAR(50) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    City VARCHAR(50) NOT NULL,
    Address VARCHAR(20) NOT NULL,
    Type VARCHAR(30) NOT NULL
);

-- Create Department table
CREATE TABLE Department (
    DID VARCHAR(10) PRIMARY KEY NOT NULL,
    "D name" VARCHAR(50) NOT NULL,
    CID VARCHAR(10) NOT NULL,
    FOREIGN KEY (CID) REFERENCES Company(CID)
);

-- Create Employee table
CREATE TABLE Employee (
    EID VARCHAR(10) PRIMARY KEY NOT NULL,
    "First name" VARCHAR(50) NOT NULL,
    "Last name" VARCHAR(50) NOT NULL,
    Nationality VARCHAR(50) NOT NULL,
    Gender VARCHAR(50) CHECK (Gender IN ('Male', 'Female', 'Trans')) NOT NULL,
    Birthday DATE CHECK (Birthday >= '0001-01-01') NOT NULL,
    Age INT NOT NULL,
    Job VARCHAR(50) NOT NULL,
    Salary MONEY NOT NULL,
    Manager VARCHAR(10) REFERENCES Employee(EID),
    "Phone number" VARCHAR(10) UNIQUE NOT NULL,
    Email VARCHAR(50) UNIQUE NOT NULL,
    DID VARCHAR(10) NOT NULL,
    FOREIGN KEY (DID) REFERENCES Department(DID)
);

-- Create Task table
CREATE TABLE Task (
    TaskNo VARCHAR(10) PRIMARY KEY NOT NULL,
    "T name" VARCHAR(50) NOT NULL,
    AcceptTime TIMESTAMP NOT NULL,
    FinishTime TIMESTAMP,
    Status VARCHAR(20) NOT NULL,
	PID VARCHAR(10) NOT NULL,
    EID VARCHAR(10) NOT NULL,
    FOREIGN KEY (PID) REFERENCES Project(PID),
    FOREIGN KEY (EID) REFERENCES Employee(EID)
);

-- Create trigger function to calculate age for Customer
CREATE OR REPLACE FUNCTION calculate_age()
RETURNS TRIGGER AS $$
BEGIN
    NEW.age := EXTRACT(YEAR FROM AGE(NEW.Birthday));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for Customer to calculate age on insert or update
CREATE TRIGGER customer_age_trigger
BEFORE INSERT OR UPDATE OF Birthday ON Customer
FOR EACH ROW
EXECUTE FUNCTION calculate_age();

-- Create trigger for Employee to calculate age on insert or update
CREATE TRIGGER employee_age_trigger
BEFORE INSERT OR UPDATE OF Birthday ON Employee
FOR EACH ROW
EXECUTE FUNCTION calculate_age();

CREATE OR REPLACE FUNCTION UpdateProgress()
RETURNS TRIGGER AS $$
DECLARE
    total_tasks FLOAT;  -- Change data type to FLOAT
    completed_tasks FLOAT;  -- Change data type to FLOAT
BEGIN
    -- Count total tasks for the project
    SELECT COUNT(*)
    INTO total_tasks
    FROM Task
    WHERE Task.PID = NEW.PID;

    -- Count completed tasks for the project
    SELECT COUNT(*)
    INTO completed_tasks
    FROM Task
    WHERE Task.PID = NEW.PID AND Task.Status = 'Complete';

    -- Calculate progress
    UPDATE Project
    SET Progress = (completed_tasks * 100.0) / total_tasks
    WHERE PID = NEW.PID;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER trg_update_progress
AFTER INSERT OR UPDATE OR DELETE ON Task
FOR EACH ROW
EXECUTE FUNCTION UpdateProgress();

DROP FUNCTION IF EXISTS REQID_DETAILS(VARCHAR);
DROP FUNCTION IF EXISTS CUSTOMER_DETAILS(VARCHAR);
DROP FUNCTION IF EXISTS TASK_OVERTIME_TNO(VARCHAR);
DROP FUNCTION IF EXISTS TASK_OVERTIME_ENAME(VARCHAR);
DROP FUNCTION IF EXISTS TASK_OVERTIME_SEL(VARCHAR, VARCHAR);
DROP FUNCTION IF EXISTS TASK_EMP(VARCHAR);
DROP FUNCTION IF EXISTS SEARCH_EMPLOYEE(VARCHAR);
DROP FUNCTION IF EXISTS SEARCH_MANAGER(VARCHAR);
DROP FUNCTION IF EXISTS SEARCH_COMPANY(VARCHAR);
DROP FUNCTION IF EXISTS GET_PROJECTS_IN_COMPANY(VARCHAR);

--- Find Detail of Requirement ---
CREATE OR REPLACE FUNCTION REQID_DETAILS(RequirementID VARCHAR)
RETURNS TABLE (
    CusID VARCHAR,
    CusName VARCHAR,
    Requirement TEXT,
    Fund MONEY,
    ProjectName VARCHAR,
    CostTotal MONEY,
    Progress NUMERIC(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        C.CustomerID AS CusID,
        CONCAT(C."First name", ' ', C."Last name")::VARCHAR AS CusName,
        R.Requirement,
        R.Fund,
        P."P name" AS ProjectName,
        P.Cost AS CostTotal,
        P.Progress
    FROM
        Requirement R
    JOIN Project P ON R.RID = P.RID
    JOIN Customer C ON R.CustomerID = C.CustomerID
    WHERE
        R.RID = RequirementID;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION CUSTOMER_DETAILS(CustomerIdentifier VARCHAR)
RETURNS TABLE (
    CusID VARCHAR,
    CusName VARCHAR,
    Requirement TEXT,
    Fund MONEY,
    ProjectName VARCHAR,
    CostTotal MONEY,
    Progress NUMERIC(5,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        C.CustomerID AS CusID,
        CONCAT(C."First name", ' ', C."Last name")::VARCHAR AS CusName,
        R.Requirement,
        R.Fund,
        P."P name" AS ProjectName,
        P.Cost AS CostTotal,
        P.Progress
    FROM
        Customer C
    JOIN Requirement R ON C.CustomerID = R.CustomerID
    JOIN Project P ON R.RID = P.RID
    WHERE
        C.CustomerID = CustomerIdentifier OR
        CONCAT(C."First name", ' ', C."Last name") ILIKE '%' || CustomerIdentifier || '%';
END;
$$ LANGUAGE plpgsql;

--- Overtime Checking ---
CREATE OR REPLACE FUNCTION TASK_OVERTIME_TNO(TaskNo VARCHAR)
RETURNS TABLE (
    TaskName VARCHAR,
    Status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        Task."T name" AS TaskName,
        CASE
            WHEN Task.FinishTime <= Project."End date" THEN 'In Time'::VARCHAR
            ELSE 'Over Time'::VARCHAR
        END AS Status
    FROM
        Task
    JOIN Project ON Task.PID = Project.PID
    WHERE
        Task.TaskNo = TASK_OVERTIME_TNO.TaskNo;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION TASK_OVERTIME_ENAME(EmpID VARCHAR)
RETURNS TABLE (
    TASKNAME VARCHAR,
    STATUS VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        TASK."T name" AS TASKNAME,
        CASE
            WHEN TASK.FinishTime <= PROJECT."End date" THEN 'In Time'::VARCHAR
            ELSE 'Over Time'::VARCHAR
        END AS STATUS
    FROM
        TASK
    JOIN PROJECT ON TASK.PID = PROJECT.PID
    JOIN EMPLOYEE ON TASK.EID = EMPLOYEE.EID
    WHERE
        EMPLOYEE.EID = TASK_OVERTIME_ENAME.EmpID;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION TASK_OVERTIME_SEL(
    SearchBy VARCHAR,
	EmpIdentifier VARCHAR
)
RETURNS TABLE (
    EmpID VARCHAR,
    EmpName VARCHAR,
    TaskName VARCHAR,
    Status VARCHAR
) AS $$
BEGIN
    IF SearchBy = 'ID' THEN
        RETURN QUERY
        SELECT 
            EMPLOYEE.EID::VARCHAR AS EmpID,
            (EMPLOYEE."First name" || ' ' || EMPLOYEE."Last name")::VARCHAR AS EmpName,
            TASK."T name" AS TaskName,
            CASE
                WHEN TASK.FinishTime <= PROJECT."End date" THEN 'In Time'::VARCHAR
                ELSE 'Over Time'::VARCHAR
            END AS Status
        FROM
            TASK
        JOIN PROJECT ON TASK.PID = PROJECT.PID
        JOIN EMPLOYEE ON TASK.EID = EMPLOYEE.EID
        WHERE
            EMPLOYEE.EID = EmpIdentifier;
    ELSIF SearchBy = 'Name' THEN
        RETURN QUERY
        SELECT 
            EMPLOYEE.EID::VARCHAR AS EmpID,
            (EMPLOYEE."First name" || ' ' || EMPLOYEE."Last name")::VARCHAR AS EmpName,
            TASK."T name" AS TaskName,
            CASE
                WHEN TASK.FinishTime <= PROJECT."End date" THEN 'In Time'::VARCHAR
                ELSE 'Over Time'::VARCHAR
            END AS Status
        FROM
            TASK
        JOIN PROJECT ON TASK.PID = PROJECT.PID
        JOIN EMPLOYEE ON TASK.EID = EMPLOYEE.EID
        WHERE
            EMPLOYEE."First name" || ' ' || EMPLOYEE."Last name" ILIKE '%' || EmpIdentifier || '%';
    ELSE
        RAISE EXCEPTION 'Invalid search option. Use either "ID" or "Name".';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Create the TASK_EMP function
CREATE OR REPLACE FUNCTION TASK_EMP(emp_identifier VARCHAR)
RETURNS TABLE (
    emp_id VARCHAR,
    emp_name VARCHAR,
    job VARCHAR,
    manager_name VARCHAR,
    task_name VARCHAR,
    task_status VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        E.EID::VARCHAR,
        (E."First name" || ' ' || E."Last name")::VARCHAR,
        E.Job::VARCHAR,
        (M."First name" || ' ' || M."Last name")::VARCHAR,
        T."T name"::VARCHAR,
        CASE
            WHEN T.FinishTime <= P."End date" THEN 'In Time'::VARCHAR
            ELSE 'Overtime'::VARCHAR
        END
    FROM 
        Task T
    JOIN Project P ON T.PID = P.PID
    JOIN Employee E ON T.EID = E.EID
    LEFT JOIN Employee M ON E.Manager = M.EID
    WHERE 
        E.EID = emp_identifier OR
        CONCAT(E."First name", ' ', E."Last name") ILIKE '%' || emp_identifier || '%';
END;
$$ LANGUAGE plpgsql;


--- Search Function ---
CREATE OR REPLACE FUNCTION SEARCH_EMPLOYEE(employee_identifier VARCHAR)
RETURNS TABLE (
    employee_id VARCHAR,
    employee_name VARCHAR,
    job VARCHAR,
    manager_name VARCHAR,
    project_name VARCHAR,
    cost MONEY,
    progress NUMERIC(10, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        E.EID::VARCHAR AS employee_id,
        (E."First name" || ' ' || E."Last name")::VARCHAR AS employee_name,
        E.Job::VARCHAR,
        (M."First name" || ' ' || M."Last name")::VARCHAR AS manager_name,
        P."P name" AS project_name,
        P.Cost,
        P.Progress
    FROM 
        Project P
    JOIN Task T ON P.PID = T.PID
    JOIN Employee E ON T.EID = E.EID
    LEFT JOIN Employee M ON E.Manager = M.EID
    WHERE 
        (E.EID = employee_identifier OR
        CONCAT(E."First name", ' ', E."Last name") ILIKE '%' || employee_identifier || '%')
        AND E.EID NOT IN (SELECT Manager FROM Employee WHERE Manager IS NOT NULL);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION SEARCH_MANAGER(manager_identifier VARCHAR)
RETURNS TABLE (
    manager_id VARCHAR,
    manager_name VARCHAR,
    job VARCHAR,
    project_name VARCHAR,
    cost MONEY,
    progress NUMERIC(10, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        M.EID::VARCHAR AS manager_id,
        (M."First name" || ' ' || M."Last name")::VARCHAR AS manager_name,
        M.Job::VARCHAR,
        P."P name" AS project_name,
        P.Cost,
        P.Progress
    FROM 
        Project P
    JOIN Task T ON P.PID = T.PID
    JOIN Employee E ON T.EID = E.EID
    JOIN Employee M ON E.Manager = M.EID
    WHERE 
        M.EID = manager_identifier OR
        CONCAT(M."First name", ' ', M."Last name") ILIKE '%' || manager_identifier || '%';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION SEARCH_COMPANY(company_identifier VARCHAR)
RETURNS TABLE (
    ComID VARCHAR,
    ComName VARCHAR,
    ProjectCounting INT,
    TotalCost MONEY
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        C.CID::VARCHAR,
        C."C name"::VARCHAR,
        COUNT(DISTINCT CASE WHEN PCount > 0 THEN P.PID END)::INT AS ProjectCounting,
        COALESCE(SUM(CAST(P.Cost AS NUMERIC)), 0)::MONEY AS TotalCost
    FROM 
        Company C
    LEFT JOIN Department D ON C.CID = D.CID
    LEFT JOIN Employee E ON D.DID = E.DID
    LEFT JOIN Task T ON E.EID = T.EID
    LEFT JOIN (
        SELECT PID, COUNT(DISTINCT PID) AS PCount
        FROM Task
        GROUP BY PID
    ) TaskCounts ON T.PID = TaskCounts.PID
    LEFT JOIN Project P ON T.PID = P.PID
    WHERE 
        C.CID = company_identifier OR
        C."C name" ILIKE '%' || company_identifier || '%'
    GROUP BY 
        C.CID, C."C name";
END;
$$ LANGUAGE plpgsql;

--- For Recheck Company ---
CREATE OR REPLACE FUNCTION GET_PROJECTS_IN_COMPANY(company_identifier VARCHAR)
RETURNS TABLE (
    ComID VARCHAR,
    ComName VARCHAR,
    ProjectID VARCHAR,
    ProjectName VARCHAR,
    Cost MONEY,
    StartDate TIMESTAMP,
    EndDate TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        C.CID::VARCHAR AS ComID,
        C."C name"::VARCHAR AS ComName,
        P.PID::VARCHAR AS ProjectID,
        P."P name"::VARCHAR AS ProjectName,
        P.Cost::MONEY,
        P."Start date"::TIMESTAMP,
        P."End date"::TIMESTAMP
    FROM 
        Company C
    LEFT JOIN Department D ON C.CID = D.CID
    LEFT JOIN Employee E ON D.DID = E.DID
    LEFT JOIN Task T ON E.EID = T.EID
    LEFT JOIN Project P ON T.PID = P.PID
    WHERE 
        (C.CID = company_identifier OR
        C."C name" ILIKE '%' || company_identifier || '%')
        AND P.PID IS NOT NULL;
END;
$$ LANGUAGE plpgsql;

-- Insert data into Customer table
INSERT INTO Customer (CustomerID, "First name", "Last name", Nationality, Gender, Job, "Phone number", Email, Birthday)
VALUES 
('C1', 'John', 'Doe', 'American', 'Male', 'Engineer', '5551234567', 'john@example.com', '1994-06-15'),
('C2', 'Alice', 'Smith', 'British', 'Female', 'Designer', '5559876543', 'alice@example.com', '1999-03-10'),
('C3', 'Emily', 'Brown', 'Canadian', 'Female', 'Accountant', '5552223333', 'emily@example.com', '1992-09-25'),
('C4', 'Daniel', 'Lee', 'Australian', 'Male', 'Engineer', '5556667777', 'daniel@example.com', '1989-05-20'),
('C5', 'Sophie', 'Miller', 'American', 'Female', 'Architect', '5555551234', 'sophie@example.com', '1991-12-03'),
('C6', 'David', 'Wilson', 'Canadian', 'Male', 'Accountant', '5554445555', 'david@example.com', '1984-08-12'),
('C7', 'Sophia', 'Taylor', 'Australian', 'Female', 'Software Engineer', '5553336666', 'sophia.taylor@example.com', '1990-02-28'),
('C8', 'James', 'Brown', 'American', 'Male', 'Project Manager', '5557778888', 'james.brown@example.com', '1987-11-02'),
('C9', 'Emma', 'Johnson', 'American', 'Female', 'Marketing Specialist', '5559990000', 'emma.johnson@example.com', '1996-07-18'),
('C10', 'Michael', 'Garcia', 'Canadian', 'Male', 'Financial Analyst', '5552221111', 'michael.garcia@example.com', '1988-04-30'),
('C11', 'Oliver', 'Harris', 'American', 'Trans', 'Software Developer', '5558889999', 'oliver.harris@example.com', '1993-10-15'),
('C12', 'Charlotte', 'Davis', 'British', 'Female', 'Marketing Manager', '5557772222', 'charlotte.davis@example.com', '1986-06-20'),
('C13', 'Lucas', 'Brown', 'Canadian', 'Male', 'Financial Analyst', '5556663333', 'lucas.brown@example.com', '1995-01-05'),
('C14', 'Matthew', 'Johnson', 'American', 'Male', 'Software Engineer', '5557779999', 'matthew@example.com', '1991-08-25'),
('C15', 'Emma', 'Clark', 'British', 'Female', 'Graphic Designer', '5551112222', 'emmaclark@example.com', '1989-04-30'),
('C16', 'William', 'Walker', 'Canadian', 'Male', 'Data Analyst', '5553334444', 'william@example.com', '1993-11-15'),
('C17', 'Sophia', 'Lewis', 'Australian', 'Female', 'Project Manager', '5556661111', 'sophia.lewis@example.com', '1988-07-20'),
('C18', 'Alexander', 'Roberts', 'American', 'Male', 'Marketing Specialist', '5558882222', 'alexander@example.com', '1990-02-10'),
('C19', 'Olivia', 'Hall', 'British', 'Female', 'Software Developer', '5559993333', 'olivia.hall@example.com', '1987-09-05'),
('C20', 'James', 'Young', 'Canadian', 'Male', 'Financial Analyst', '5554447777', 'james.young@example.com', '1994-06-18'),
('C21', 'Amelia', 'King', 'Australian', 'Female', 'UX Designer', '5552227777', 'amelia.king@example.com', '1986-12-22'),
('C22', 'Benjamin', 'Evans', 'American', 'Male', 'Database Administrator', '5551117777', 'benjamin.evans@example.com', '1992-03-25'),
('C23', 'Ava', 'Carter', 'British', 'Female', 'Marketing Manager', '5558885555', 'ava.carter@example.com', '1989-01-12'),
('C24', 'Noah', 'Thomas', 'Canadian', 'Male', 'Event Coordinator', '5553338888', 'noah.thomas@example.com', '1995-10-08'),
('C25', 'Charlotte', 'Baker', 'Australian', 'Female', 'Software Engineer', '5556664444', 'charlotte.baker@example.com', '1984-05-28'),
('C26', 'Ethan', 'Green', 'American', 'Male', 'Graphic Designer', '5555559999', 'ethan.green@example.com', '1996-03-17'),
('C27', 'Sophia', 'Hill', 'British', 'Female', 'Data Analyst', '5552224444', 'sophia.hill@example.com', '1988-11-03');

-- Insert data into Requirement table
INSERT INTO Requirement (RID, Requirement, Fund, CustomerID)
VALUES 
('R1', 'Software Development', 50000.00, 'C1'),
('R2', 'Marketing Campaign', 10000.00, 'C2'),
('R3', 'Mobile App Development', 80000.00, 'C3'),
('R4', 'Product Launch Event', 25000.00, 'C4'),
('R5', 'Web Development', 60000.00, 'C5'),
('R6', 'Product Design', 15000.00, 'C6'),
('R7', 'Database Management System', 75000.00, 'C7'),
('R8', 'Market Research', 20000.00, 'C8'),
('R9', 'Social Media Management', 15000.00, 'C14'),
('R10', 'Product Design', 30000.00, 'C15'),
('R11', 'Web Development', 45000.00, 'C16'),
('R12', 'Market Research', 20000.00, 'C17'),
('R13', 'Mobile App Development', 60000.00, 'C18'),
('R14', 'Event Planning', 25000.00, 'C19'),
('R15', 'Database Management', 35000.00, 'C20'),
('R16', 'Software Development', 55000.00, 'C21'),
('R17', 'Content Creation', 18000.00, 'C22'),
('R18', 'UI/UX Design', 32000.00, 'C23'),
('R19', 'Financial Analysis', 40000.00, 'C24'),
('R20', 'Graphic Design', 28000.00, 'C25'),
('R21', 'Database Optimization', 42000.00, 'C26'),
('R22', 'Marketing Campaign', 20000.00, 'C27');

-- Insert data into Company table
INSERT INTO Company (CID, "C name", Country, City, Address, Type)
VALUES 
('CO1', 'ABC Inc.', 'USA', 'New York', '123 Main St', 'Technology'),
('CO2', 'XYZ Ltd.', 'UK', 'London', '456 Park Ave', 'Marketing'),
('CO3', 'Tech Solutions', 'Canada', 'Toronto', '789 Elm St', 'Technology'),
('CO4', 'Event Planners', 'Australia', 'Sydney', '321 Maple Ave', 'Events'),
('CO5', 'Web Solutions', 'USA', 'Chicago', '789 Elm St', 'Technology'),
('CO6', 'Designers Inc.', 'Canada', 'Toronto', '456 Maple Ave', 'Design'),
('CO7', 'Data Solutions Inc.', 'Australia', 'Sydney', '789 High St', 'Technology'),
('CO8', 'Market Insights Ltd.', 'USA', 'Los Angeles', '321 Oak Ave', 'Research'),
('CO9', 'Tech Innovations', 'USA', 'San Francisco', '456 Elm St', 'Technology'),
('CO10', 'Marketing Pro', 'UK', 'Manchester', '789 Oak St', 'Marketing'),
('CO11', 'Digital Solutions', 'Canada', 'Vancouver', '123 Maple Ave', 'Technology'),
('CO12', 'Event Planners Inc.', 'Australia', 'Melbourne', '789 Oak St', 'Events'),
('CO13', 'Web Experts', 'USA', 'Seattle', '456 High St', 'Technology'),
('CO14', 'Design Genius', 'Canada', 'Montreal', '123 Park Ave', 'Design'),
('CO15', 'Data Tech Inc.', 'Australia', 'Brisbane', '789 Elm St', 'Technology'),
('CO16', 'Market Trends', 'USA', 'Boston', '456 Maple Ave', 'Research');

-- Insert data into Department table
INSERT INTO Department (DID, "D name", CID)
VALUES 
('D1', 'Engineering', 'CO1'),
('D2', 'Marketing', 'CO2'),
('D3', 'Finance', 'CO3'),
('D4', 'Events', 'CO4'),
('D5', 'Development', 'CO5'),
('D6', 'Design', 'CO6'),
('D7', 'Database', 'CO7'),
('D8', 'Research', 'CO8'),
('D9', 'Engineering', 'CO9'),
('D10', 'Marketing', 'CO10'),
('D11', 'Finance', 'CO11'),
('D12', 'Events', 'CO12'),
('D13', 'Development', 'CO13'),
('D14', 'Design', 'CO14'),
('D15', 'Database', 'CO15'),
('D16', 'Research', 'CO16');

-- Insert data into Employee table
INSERT INTO Employee (EID, "First name", "Last name", Nationality, Gender, Birthday, Job, Salary, Manager, "Phone number", Email, DID)
VALUES 
('E1', 'Michael', 'Johnson', 'American', 'Male', '1990-05-15', 'Software Developer', 70000.00, 'E9', '5551434567', 'michael@example.com', 'D1'),
('E2', 'Emma', 'Williams', 'British', 'Female', '1995-08-20', 'Marketing Manager', 60000.00, 'E10', '5558876543', 'emma@example.com', 'D2'),
('E3', 'Olivia', 'Martinez', 'Canadian', 'Female', '1993-07-10', 'Financial Analyst', 65000.00, 'E11', '5552123333', 'olivia@example.com', 'D3'),
('E4', 'Sophia', 'Chen', 'Australian', 'Female', '1988-12-05', 'Event Coordinator', 60000.00, 'E12', '5556617777', 'sophia@example.com', 'D4'),
('E5', 'Jacob', 'Brown', 'American', 'Male', '1995-02-20', 'Web Developer', 75000.00, 'E9', '5555551254', 'jacob@example.com', 'D5'),
('E6', 'Chloe', 'Davis', 'Canadian', 'Female', '1987-09-25', 'UX Designer', 70000.00, 'E5', '5554445515', 'chloe@example.com', 'D6'),
('E7', 'Ethan', 'Wilson', 'Australian', 'Male', '1992-04-10', 'Database Administrator', 80000.00, 'E6', '5553316666', 'ethan@example.com', 'D7'),
('E8', 'Isabella', 'Brown', 'American', 'Female', '1985-11-15', 'Research Analyst', 85000.00, 'E7', '5557778288', 'isabella@example.com', 'D8'),
('E9', 'Oliver', 'Harris', 'American', 'Male', '1987-03-20', 'Software Developer', 72000.00, 'E9', '5552321111', 'oliver@example.com', 'D1'),
('E10', 'Charlotte', 'Davis', 'British', 'Female', '1990-12-15', 'Marketing Manager', 65000.00, 'E9', '5550772222', 'charlotte@example.com', 'D2'),
('E11', 'David', 'Garcia', 'Canadian', 'Trans', '1988-09-10', 'Financial Analyst', 68000.00, 'E10', '5558809999', 'david@example.com', 'D3'),
('E12', 'Lucas', 'Smith', 'Australian', 'Male', '1991-06-05', 'Event Coordinator', 62000.00, 'E11', '5558063333', 'lucas@example.com', 'D4'),
('E13', 'Emma', 'Johnson', 'American', 'Female', '1989-05-20', 'Marketing Specialist', 63000.00, 'E10', '5557190000', 'emma.johnson@example.com', 'D2'),
('E14', 'Michael', 'Garcia', 'Canadian', 'Male', '1992-11-10', 'Financial Analyst', 67000.00, 'E11', '5556167877', 'michael.garcia@example.com', 'D3'),
('E15', 'Aiden', 'Martinez', 'American', 'Male', '1989-07-25', 'Software Developer', 72000.00, 'E9', '5551234567', 'aiden@example.com', 'D9'),
('E16', 'Mia', 'Lopez', 'British', 'Female', '1994-04-20', 'Marketing Manager', 65000.00, 'E10', '5559876543', 'mia@example.com', 'D10'),
('E17', 'Elijah', 'Hernandez', 'Canadian', 'Male', '1991-11-15', 'Financial Analyst', 68000.00, 'E11', '5552223333', 'elijah@example.com', 'D11'),
('E18', 'Grace', 'Gonzalez', 'Australian', 'Female', '1986-07-20', 'Event Coordinator', 62000.00, 'E12', '5556667777', 'grace@example.com', 'D12'),
('E19', 'Logan', 'Wilson', 'American', 'Male', '1995-02-20', 'Web Developer', 75000.00, 'E9', '5555551234', 'logan@example.com', 'D13'),
('E20', 'Harper', 'Scott', 'Canadian', 'Female', '1987-09-25', 'UX Designer', 70000.00, 'E5', '5554445555', 'harper@example.com', 'D14'),
('E21', 'Lucas', 'Diaz', 'Australian', 'Male', '1992-04-10', 'Database Administrator', 80000.00, 'E6', '5553336666', 'lucasDiaz@example.com', 'D15'),
('E22', 'Avery', 'Miller', 'American', 'Female', '1985-11-15', 'Research Analyst', 85000.00, 'E7', '5557778888', 'avery@example.com', 'D16'),
('E23', 'Ethan', 'Campbell', 'American', 'Male', '1987-03-20', 'Software Developer', 72000.00, 'E9', '5552221111', 'ethanCamp@example.com', 'D9'),
('E24', 'Scarlett', 'Evans', 'British', 'Female', '1990-12-15', 'Marketing Manager', 65000.00, 'E9', '5557772222', 'scarlett@example.com', 'D10'),
('E25', 'Alexander', 'Murphy', 'Canadian', 'Male', '1988-09-10', 'Financial Analyst', 68000.00, 'E10', '5558889999', 'alexander@example.com', 'D11'),
('E26', 'Madison', 'Cook', 'Australian', 'Female', '1991-06-05', 'Event Coordinator', 62000.00, 'E11', '5556663333', 'madison@example.com', 'D12'),
('E27', 'Jackson', 'Hill', 'American', 'Male', '1992-11-10', 'Software Developer', 72000.00, 'E9', '5556167777', 'jackson@example.com', 'D13'),
('E28', 'Aria', 'Ward', 'British', 'Female', '1989-05-20', 'Marketing Specialist', 63000.00, 'E10', '5555158888', 'aria@example.com', 'D14');

-- Insert data into Project table with TIMESTAMP values
INSERT INTO Project (PID, "P name", Cost, RID, "Start date", "End date")
VALUES 
('P1', 'Website Development', 20000.00, 'R1', '2023-01-01 00:00:00', '2023-06-30 00:00:00'),
('P2', 'Social Media Campaign', 5000.00, 'R2', '2023-03-01 00:00:00', '2023-05-31 00:00:00'),
('P3', 'Mobile App Design', 30000.00, 'R3', '2023-04-01 00:00:00', '2023-06-30 00:00:00'),
('P4', 'Launch Party Planning', 15000.00, 'R4', '2023-07-01 00:00:00', '2023-09-30 00:00:00'),
('P5', 'Web Application Development', 40000.00, 'R5', '2023-02-01 00:00:00', '2023-08-31 00:00:00'),
('P6', 'Product Design Revamp', 20000.00, 'R6', '2023-05-01 00:00:00', '2023-07-31 00:00:00'),
('P7', 'Database Optimization', 25000.00, 'R7', '2023-06-01 00:00:00', '2023-09-30 00:00:00'),
('P8', 'Market Research Survey', 10000.00, 'R8', '2023-04-01 00:00:00', '2023-06-30 00:00:00'),
('P9', 'Website Design', 19000.00, 'R1', '2023-01-01 00:00:00', '2023-06-30 00:00:00'),
('P10', 'Social Media Management', 12000.00, 'R9', '2023-05-01 00:00:00', '2023-08-31 00:00:00'),
('P11', 'Product Design', 25000.00, 'R10', '2023-06-01 00:00:00', '2023-09-30 00:00:00'),
('P12', 'Website Development', 30000.00, 'R11', '2023-07-01 00:00:00', '2023-10-31 00:00:00'),
('P13', 'Market Research', 18000.00, 'R12', '2023-08-01 00:00:00', '2023-11-30 00:00:00'),
('P14', 'Mobile App Development', 50000.00, 'R13', '2023-09-01 00:00:00', '2024-02-29 00:00:00'),
('P15', 'Event Planning', 22000.00, 'R14', '2023-10-01 00:00:00', '2024-03-31 00:00:00'),
('P16', 'Database Management', 38000.00, 'R15', '2023-11-01 00:00:00', '2024-04-30 00:00:00'),
('P17', 'Software Development', 58000.00, 'R16', '2024-01-01 00:00:00', '2024-06-30 00:00:00'),
('P18', 'Content Creation', 15000.00, 'R17', '2024-02-01 00:00:00', '2024-07-31 00:00:00'),
('P19', 'UI/UX Design', 35000.00, 'R18', '2024-03-01 00:00:00', '2024-08-31 00:00:00'),
('P20', 'Financial Analysis', 42000.00, 'R19', '2024-04-01 00:00:00', '2024-09-30 00:00:00'),
('P21', 'Graphic Design', 30000.00, 'R20', '2024-05-01 00:00:00', '2024-10-31 00:00:00'),
('P22', 'Database Optimization', 45000.00, 'R21', '2024-06-01 00:00:00', '2024-11-30 00:00:00'),
('P23', 'Marketing Campaign', 25000.00, 'R22', '2024-07-01 00:00:00', '2024-12-31 00:00:00');

-- Insert data into Task table with TIMESTAMP values and EID
INSERT INTO Task (TaskNo, "T name", PID, AcceptTime, FinishTime, Status, EID)
VALUES 
('T1', 'Design UI', 'P1', '2023-01-01 00:00:00', '2023-01-31 00:00:00', 'Complete', 'E1'),
('T2', 'Develop Backend', 'P1', '2023-02-01 00:00:00', '2023-03-15 00:00:00', 'Pending', 'E5'),
('T3', 'Content Creation', 'P2', '2023-03-01 00:00:00', '2023-03-15 00:00:00', 'Complete', 'E13'),
('T4', 'Wireframing', 'P3', '2023-04-01 00:00:00', '2023-04-15 00:00:00', 'Complete', 'E6'),
('T5', 'Develop App UI', 'P3', '2023-04-16 00:00:00', '2023-05-15 00:00:00', 'In Progress', 'E7'),
('T6', 'Venue Selection', 'P4', '2023-07-01 00:00:00', '2023-07-15 00:00:00', 'Pending', 'E8'),
('T7', 'Frontend Development', 'P5', '2023-02-01 00:00:00', '2023-04-30 00:00:00', 'In Progress', 'E9'),
('T8', 'Backbone Infrastructure Setup', 'P5', '2023-05-01 00:00:00', '2023-06-30 00:00:00', 'Pending', 'E10'),
('T9', 'UI/UX Design Refinement', 'P6', '2023-05-01 00:00:00', '2023-06-30 00:00:00', 'In Progress', 'E11'),
('T10', 'Data Migration', 'P7', '2023-06-01 00:00:00', '2023-07-31 00:00:00', 'Pending', 'E12'),
('T11', 'Survey Questionnaire Design', 'P8', '2023-04-01 00:00:00', '2023-04-15 00:00:00', 'Complete', 'E13'),
('T12', 'Data Collection', 'P8', '2023-04-16 00:00:00', '2023-05-31 00:00:00', 'In Progress', 'E14'),
('T13', 'Database Security', 'P7', '2024-01-01 00:00:00', '2024-01-15 00:00:00', 'Complete', 'E9'),
('T14', 'Database Backup Optimization', 'P7', '2024-01-16 00:00:00', '2024-01-31 00:00:00', 'Pending', 'E10'),
('T15', 'Social Media Strategy', 'P10', '2023-05-01 00:00:00', '2023-05-30 00:00:00', 'Complete', 'E15'),
('T16', 'Design Concept', 'P11', '2023-06-01 00:00:00', '2023-06-30 00:00:00', 'Complete', 'E16'),
('T17', 'Backend Development', 'P12', '2023-07-01 00:00:00', '2023-08-15 00:00:00', 'Pending', 'E17'),
('T18', 'Survey Creation', 'P12', '2023-08-01 00:00:00', '2023-08-30 00:00:00', 'Complete', 'E18'),
('T19', 'App Interface Design', 'P14', '2023-09-01 00:00:00', '2023-10-15 00:00:00', 'In Progress', 'E19'),
('T20', 'Venue Selection', 'P15', '2023-10-01 00:00:00', '2023-10-31 00:00:00', 'Pending', 'E20'),
('T21', 'Database Modeling', 'P16', '2023-11-01 00:00:00', '2023-12-15 00:00:00', 'In Progress', 'E21'),
('T22', 'Software Testing', 'P17', '2024-01-01 00:00:00', '2024-02-28 00:00:00', 'Pending', 'E22'),
('T23', 'Content Writing', 'P18', '2024-02-01 00:00:00', '2024-03-15 00:00:00', 'In Progress', 'E23'),
('T24', 'UI Prototype', 'P19', '2024-03-01 00:00:00', '2024-04-30 00:00:00', 'Pending', 'E24'),
('T25', 'Financial Data Analysis', 'P20', '2024-04-01 00:00:00', '2024-05-31 00:00:00', 'Complete', 'E25'),
('T26', 'Graphic Illustration', 'P21', '2024-05-01 00:00:00', '2024-06-30 00:00:00', 'In Progress', 'E26'),
('T27', 'Database Query Optimization', 'P22', '2024-06-01 00:00:00', '2024-07-31 00:00:00', 'Pending', 'E27'),
('T28', 'Campaign Planning', 'P23', '2024-07-01 00:00:00', '2024-08-31 00:00:00', 'In Progress', 'E28');