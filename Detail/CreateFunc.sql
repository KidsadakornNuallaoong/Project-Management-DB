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
    Progress NUMERIC(10,2)
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
    Progress NUMERIC(10,2)
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