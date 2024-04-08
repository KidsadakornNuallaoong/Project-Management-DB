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