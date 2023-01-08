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
SHOW ERRORS