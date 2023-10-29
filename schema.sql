CREATE TABLE "projects" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "name" varchar,
  "start_date" timestamp DEFAULT (current_timestamp),
  "end_date" timestamp
);

CREATE TABLE "project_managers" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "project_id" integer,
  "manager_id" integer,
  "start_date" timestamp DEFAULT (current_timestamp),
  "end_date" timestamp
);

CREATE TABLE "financial_reports" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "project_id" integer,
  "spend_cost" integer,
  "raised_cost" integer,
  "start_date" timestamp DEFAULT (current_timestamp),
  "end_date" timestamp
);

CREATE TABLE "project_enrollments" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "project_id" integer,
  "employee_id" integer,
  "start_date" timestamp DEFAULT (current_timestamp),
  "end_date" timestamp
);

CREATE TABLE "contact_types" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "description" varchar
);

CREATE TABLE "employee_contacts" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "employee_id" integer,
  "contact_type" integer,
  "contact_value" varchar,
  "start_date" timestamp DEFAULT (current_timestamp),
  "end_date" timestamp
);

CREATE TABLE "employee_skills" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "employee_id" integer,
  "skill_type" integer,
  "proficiency_level" integer,
  "start_date" timestamp DEFAULT (current_timestamp),
  "end_date" timestamp
);

CREATE TABLE "project_employees" (
  "project_id" INTEGER GENERATED BY DEFAULT AS IDENTITY,
  "employee_id" INTEGER GENERATED BY DEFAULT AS IDENTITY,
  PRIMARY KEY ("project_id", "employee_id")
);

CREATE TABLE "positions" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "name" varchar
);

CREATE TABLE "employee_positions_updates" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "employee_id" integer,
  "position_id" integer,
  "start_date" timestamp DEFAULT (current_timestamp),
  "end_date" timestamp
);

CREATE TABLE "employee_salaries_updates" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "employee_id" integer,
  "salary_amount" integer,
  "start_date" timestamp DEFAULT (current_timestamp),
  "end_date" timestamp
);

CREATE TABLE "activities" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "description" varchar
);

CREATE TABLE "employee_activities" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "activity_id" integer,
  "employee_id" integer,
  "start_date" timestamp DEFAULT (current_timestamp),
  "end_date" timestamp,
  "total_reward" integer
);

CREATE TABLE "working_hours" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "employee_id" integer,
  "start_date" timestamp DEFAULT (current_timestamp),
  "end_date" timestamp
);

CREATE TABLE "employees" (
  "id" INTEGER GENERATED BY DEFAULT AS IDENTITY UNIQUE PRIMARY KEY,
  "name" varchar,
  "surname" varchar,
  "employment_date" timestamp DEFAULT (current_timestamp),
  "firing_date" timestamp,
  "current_position_id" integer,
  "current_salary" integer
);

ALTER TABLE "project_managers" ADD FOREIGN KEY ("project_id") REFERENCES "projects" ("id");

ALTER TABLE "project_managers" ADD FOREIGN KEY ("manager_id") REFERENCES "employees" ("id");

ALTER TABLE "financial_reports" ADD FOREIGN KEY ("project_id") REFERENCES "projects" ("id");

ALTER TABLE "project_enrollments" ADD FOREIGN KEY ("project_id") REFERENCES "projects" ("id");

ALTER TABLE "project_enrollments" ADD FOREIGN KEY ("employee_id") REFERENCES "employees" ("id");

ALTER TABLE "project_employees" ADD FOREIGN KEY ("project_id") REFERENCES "projects" ("id");

ALTER TABLE "project_employees" ADD FOREIGN KEY ("employee_id") REFERENCES "employees" ("id");

ALTER TABLE "employee_positions_updates" ADD FOREIGN KEY ("employee_id") REFERENCES "employees" ("id");

ALTER TABLE "employee_positions_updates" ADD FOREIGN KEY ("position_id") REFERENCES "positions" ("id");

ALTER TABLE "employee_salaries_updates" ADD FOREIGN KEY ("employee_id") REFERENCES "employees" ("id");

ALTER TABLE "employee_skills" ADD FOREIGN KEY ("employee_id") REFERENCES "employees" ("id");

ALTER TABLE "employee_contacts" ADD FOREIGN KEY ("employee_id") REFERENCES "employees" ("id");

ALTER TABLE "employee_contacts" ADD FOREIGN KEY ("contact_type") REFERENCES "contact_types" ("id");

ALTER TABLE "employee_activities" ADD FOREIGN KEY ("activity_id") REFERENCES "activities" ("id");

ALTER TABLE "employee_activities" ADD FOREIGN KEY ("employee_id") REFERENCES "employees" ("id");

ALTER TABLE "working_hours" ADD FOREIGN KEY ("employee_id") REFERENCES "employees" ("id");


CREATE OR REPLACE FUNCTION validate_project_start_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.start_date > current_timestamp THEN
        RAISE EXCEPTION 'Project start date cannot be in the future';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER project_start_date_validation
BEFORE INSERT ON projects
FOR EACH ROW
EXECUTE FUNCTION validate_project_start_date();


CREATE OR REPLACE FUNCTION validate_project_enrollment_end_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.end_date IS NOT NULL AND NEW.end_date < NEW.start_date THEN
        RAISE EXCEPTION 'Project enrollment end date cannot be before the start date';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER project_enrollment_end_date_validation
BEFORE INSERT ON project_enrollments
FOR EACH ROW
EXECUTE FUNCTION validate_project_enrollment_end_date();


CREATE OR REPLACE FUNCTION update_employee_salary()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE employees
    SET current_salary = NEW.salary_amount
    WHERE id = NEW.employee_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER employee_salary_update
AFTER INSERT ON employee_salaries_updates
FOR EACH ROW
EXECUTE FUNCTION update_employee_salary();

CREATE OR REPLACE FUNCTION validate_project_manager_assignment_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.start_date < (SELECT start_date FROM projects WHERE id = NEW.project_id) OR
       (NEW.end_date IS NOT NULL AND NEW.end_date > (SELECT end_date FROM projects WHERE id = NEW.project_id)) THEN
        RAISE EXCEPTION 'Project manager assignment date is not within project start and end dates';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER project_manager_assignment_date_validation
BEFORE INSERT ON project_managers
FOR EACH ROW
EXECUTE FUNCTION validate_project_manager_assignment_date();


CREATE OR REPLACE FUNCTION validate_employee_skill_proficiency()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.proficiency_level < 1 OR NEW.proficiency_level > 5 THEN
        RAISE EXCEPTION 'Proficiency level must be between 1 and 5';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER employee_skill_proficiency_validation
BEFORE INSERT ON employee_skills
FOR EACH ROW
EXECUTE FUNCTION validate_employee_skill_proficiency();

CREATE OR REPLACE PROCEDURE update_employee_position(
    emp_id integer,
    new_position_id integer
)
AS $$
DECLARE
    current_position integer;
BEGIN
    SELECT current_position_id INTO current_position
    FROM employees
    WHERE id = emp_id;

    UPDATE employees
    SET current_position_id = new_position_id
    WHERE id = emp_id;

    INSERT INTO employee_positions_updates(employee_id, position_id, start_date, end_date)
    VALUES (emp_id, current_position, current_timestamp, current_timestamp);

    INSERT INTO employee_positions_updates(employee_id, position_id, start_date)
    VALUES (emp_id, new_position_id, current_timestamp);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE update_employee_skills(
    emp_id integer,
    skill_type_id integer,
    new_proficiency_level integer
)
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM employee_skills WHERE employee_id = emp_id AND skill_type = skill_type_id) THEN
        UPDATE employee_skills
        SET proficiency_level = new_proficiency_level
        WHERE employee_id = emp_id AND skill_type = skill_type_id;
    ELSE
        INSERT INTO employee_skills(employee_id, skill_type, proficiency_level)
        VALUES (emp_id, skill_type_id, new_proficiency_level);
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE calculate_total_rewards(
    emp_id integer,
    OUT total_reward_count integer
)
AS $$
BEGIN
    SELECT sum(total_reward) INTO total_reward_count
    FROM employee_activities
    WHERE employee_id = emp_id;
END;
$$ LANGUAGE plpgsql;



INSERT INTO positions (id, name) VALUES
(1, 'Manager'),
(2, 'Developer'),
(3, 'Designer');

INSERT INTO contact_types (id, description) VALUES
(1, 'Email'),
(2, 'Phone'),
(3, 'Address');

INSERT INTO activities (id, description) VALUES
(1, 'Coding'),
(2, 'Designing'),
(3, 'Meeting'),
(4, 'Testing');

INSERT INTO employees (id, name, surname, employment_date, current_position_id, current_salary) VALUES
(1, 'John', 'Doe', '2023-01-01', 1, 60000),
(2, 'Jane', 'Smith', '2022-03-15', 2, 55000),
(3, 'Alice', 'Johnson', '2021-09-10', 2, 58000);

INSERT INTO employee_contacts (id, employee_id, contact_type, contact_value) VALUES
(1, 1, 1, 'john.doe@email.com'),
(2, 1, 2, '123-456-7890'),
(3, 2, 1, 'jane.smith@email.com'),
(4, 3, 1, 'alice.johnson@email.com'),
(5, 3, 2, '987-654-3210');

INSERT INTO employee_skills (id, employee_id, skill_type, proficiency_level) VALUES
(1, 1, 1, 4),
(2, 1, 2, 3),
(3, 2, 2, 4),
(4, 3, 1, 5),
(5, 3, 2, 2);

INSERT INTO employee_activities (id, activity_id, employee_id, start_date, end_date, total_reward) VALUES
(1, 1, 1, '2023-01-02', NULL, 2000),
(2, 1, 2, '2023-01-03', NULL, 1800),
(3, 2, 1, '2023-01-02', NULL, 1500),
(4, 2, 3, '2023-01-03', NULL, 1600);
