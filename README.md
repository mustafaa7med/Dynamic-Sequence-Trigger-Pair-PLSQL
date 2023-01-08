# Dynamic-Sequence-Trigger-Pair-PLSQL
Dynamically Creating a Sequence/Trigger Pair using Oracle PL/SQL
## Creating a sequence/pair through a click based software has a few complications such as:

- Sequence/Trigger is Table based
- Inconvenient in terms of migrating to another DBMS

# Oracle PLSQL Features Used in the project

- SCALAR VARIABLES
- CURSOR
- FOR LOOP
- IF CONDITION
- DYNAMIC SQL
- SEQUENCE
- TRIGGER
- Data Dictionary

### Note: I've used TOAD throughout this project and i've used the default database that comes with it.

# Step #1

Extracting all table names and their numeric primary key to create a sequence/trigger pair on every table and use their primary key for the sequence, Hence, I extracted these information through Data Dictionary tables available in ORACLE through the following tables

- 'user_constraints' | *To extract table names and specify the PK in the WHERE condition*
- 'user_cons_columns' | *To extract column names associated with table names*
- 'user_tab_columns' | *To specify numeric datatype of the PK column*

### These tables were grouped together through an INNER JOIN statement which will be used later on in the cursor in the DECLARE sections.

```sql
  -- Selecting table names with their PK Column
    SELECT DISTINCT uc.table_name, ucc.column_name, utc.data_type
    FROM user_constraints uc INNER JOIN user_cons_columns ucc
    ON uc.table_name = ucc.table_name and ucc.constraint_name = uc.constraint_name
    INNER JOIN user_tab_columns utc
    ON utc.table_name = ucc.table_name
    WHERE UPPER(UTC.DATA_TYPE) = UPPER('number') AND UPPER(uc.constraint_type) = UPPER('p') 
    -- Added  NOT IN because those 3 columns are not numeric datatype
    -- They are DATE and CHAR datatype and TOAD reads them as NUMBER
    AND ucc.column_name NOT IN ('START_DATE','JOB_ID','COUNTRY_ID');
```

# Step #2

Creating a PLSQL Block and adding the join statement in a CURSOR in the DECLARE section
Creating a FOR LOOP to execute a dynamic SQL create sequence statement
*This is necessary to create a sequence for each table being selected through the cursor*

```sql
  DECLARE

-- Initiating a cursor
CURSOR cons_cursor IS

    -- Selecting table names with their PK Column
    SELECT DISTINCT uc.table_name, ucc.column_name, utc.data_type
    FROM user_constraints uc INNER JOIN user_cons_columns ucc
    ON uc.table_name = ucc.table_name and ucc.constraint_name = uc.constraint_name
    INNER JOIN user_tab_columns utc
    ON utc.table_name = ucc.table_name
    WHERE UPPER(UTC.DATA_TYPE) = UPPER('number') AND UPPER(uc.constraint_type) = UPPER('p') 
    -- Added  NOT IN because those 3 columns are not numeric datatype
    -- They are DATE and CHAR datatype and TOAD reads them as NUMBER
    AND ucc.column_name NOT IN ('START_DATE','JOB_ID','COUNTRY_ID');

cons_max number(8,2);

BEGIN
        
    FOR cons_record IN cons_cursor LOOP
        -- Selecting maximum value and incrementing by 1
        EXECUTE IMMEDIATE 'SELECT (NVL(MAX('||cons_record.column_name||'),0)+1) FROM ' || cons_record.table_name
            INTO cons_max;
```

# Step #3

Handling existing sequences, If we're creating a new sequence that already exists then it will result into an error, Hence,
We will create a counter to check if the sequence exists, If it does then we will DROP it and RECREATE it
*We can check user based sequences through data dictionary table 'USER_SEQUENCES'*

```sql
DECLARE

-- Initiating a cursor
CURSOR cons_cursor IS

    -- Selecting table names with their PK Column
    SELECT DISTINCT uc.table_name, ucc.column_name, utc.data_type
    FROM user_constraints uc INNER JOIN user_cons_columns ucc
    ON uc.table_name = ucc.table_name and ucc.constraint_name = uc.constraint_name
    INNER JOIN user_tab_columns utc
    ON utc.table_name = ucc.table_name
    WHERE UPPER(UTC.DATA_TYPE) = UPPER('number') AND UPPER(uc.constraint_type) = UPPER('p') 
    -- Added  NOT IN because those 3 columns are not numeric datatype
    -- They are DATE and CHAR datatype and TOAD reads them as NUMBER
    AND ucc.column_name NOT IN ('START_DATE','JOB_ID','COUNTRY_ID');

cons_max number(8,2);
seq_count number(8,2);

BEGIN
        
    FOR cons_record IN cons_cursor LOOP
        -- Selecting maximum value and incrementing by 1
        EXECUTE IMMEDIATE 'SELECT (NVL(MAX('||cons_record.column_name||'),0)+1) FROM ' || cons_record.table_name
            INTO cons_max;

    -- Selecting all sequences (User based)
    SELECT COUNT(*)
    INTO seq_count
    FROM USER_SEQUENCES
    WHERE SEQUENCE_NAME = cons_record.table_name||'_SEQ';
    
    -- Verifying whether the sequence exists or otherwise.
    IF seq_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE SEQUENCE ' ||cons_record.table_name||'_SEQ START WITH '|| cons_max;
    ELSE 
        EXECUTE IMMEDIATE 'DROP SEQUENCE '||cons_record.table_name||'_SEQ';
        EXECUTE IMMEDIATE 'CREATE SEQUENCE ' ||cons_record.table_name||'_SEQ START WITH '|| cons_max;
    END IF;
```

# Final Step

Creating an associated TRIGGER with the SEQUENCE we just created, That can be done through Dynamic SQL.

*The main objective of the trigger is to initiate .nextval value in the PK column through a special SEQUENCE for the table in question through the loop.*

```sql
DECLARE

-- Initiating a cursor
CURSOR cons_cursor IS

    -- Selecting table names with their PK Column
    SELECT DISTINCT uc.table_name, ucc.column_name, utc.data_type
    FROM user_constraints uc INNER JOIN user_cons_columns ucc
    ON uc.table_name = ucc.table_name and ucc.constraint_name = uc.constraint_name
    INNER JOIN user_tab_columns utc
    ON utc.table_name = ucc.table_name
    WHERE UPPER(UTC.DATA_TYPE) = UPPER('number') AND UPPER(uc.constraint_type) = UPPER('p') 
    -- Added  NOT IN because those 3 columns are not numeric datatype
    -- They are DATE and CHAR datatype and TOAD reads them as NUMBER
    AND ucc.column_name NOT IN ('START_DATE','JOB_ID','COUNTRY_ID');

cons_max number(8,2);
seq_count number(8,2);

BEGIN
        
    FOR cons_record IN cons_cursor LOOP
        -- Selecting maximum value and incrementing by 1
        EXECUTE IMMEDIATE 'SELECT (NVL(MAX('||cons_record.column_name||'),0)+1) FROM ' || cons_record.table_name
            INTO cons_max;

    -- Selecting all sequences (User based)
    SELECT COUNT(*)
    INTO seq_count
    FROM USER_SEQUENCES
    WHERE SEQUENCE_NAME = cons_record.table_name||'_SEQ';
    
    -- Verifying whether the sequence exists or otherwise.
    IF seq_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE SEQUENCE ' ||cons_record.table_name||'_SEQ START WITH '|| cons_max;
    ELSE 
        EXECUTE IMMEDIATE 'DROP SEQUENCE '||cons_record.table_name||'_SEQ';
        EXECUTE IMMEDIATE 'CREATE SEQUENCE ' ||cons_record.table_name||'_SEQ START WITH '|| cons_max;
    END IF;

        -- Creating a dynamic trigger associated to the sequence and PK of the table
        EXECUTE IMMEDIATE 'CREATE OR REPLACE TRIGGER ' || cons_record.table_name||'_TRG' ||
        ' BEFORE INSERT ON ' || cons_record.table_name ||
        ' FOR EACH ROW ' ||
        ' BEGIN ' ||
        ':NEW.'||cons_record.column_name || ' := ' || cons_record.table_name||'_SEQ.nextval;' ||
        'END;';

    END LOOP;
    
END;
```

## 🔗 Get in touch
[![Email](https://img.shields.io/badge/Email_Me-000?style=for-the-badge&logo=ko-fi&logoColor=white)](mustafaa7med@gmail.com)

[![linkedin](https://img.shields.io/badge/linkedin-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/mustafaa7med)
