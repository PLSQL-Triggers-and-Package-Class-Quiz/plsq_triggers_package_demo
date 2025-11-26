-- Patients table
CREATE TABLE patients (
    patient_id   NUMBER PRIMARY KEY,
    patient_name VARCHAR2(200) NOT NULL,
    age          NUMBER,
    gender       CHAR(1) CHECK (gender IN ('M','F','O')), -- O = other
    admitted     CHAR(1) DEFAULT 'N' CHECK (admitted IN ('Y','N'))
);

-- Doctors table
CREATE TABLE doctors (
    doctor_id   NUMBER PRIMARY KEY,
    doctor_name VARCHAR2(200) NOT NULL,
    specialty   VARCHAR2(100)
);

CREATE OR REPLACE PACKAGE pkg_patient_mgmt IS

  -- record type that represents a single patient (for bulk collection)
  TYPE t_patient_rec IS RECORD (
    patient_id   NUMBER,
    patient_name VARCHAR2(200),
    age          NUMBER,
    gender       CHAR(1),
    admitted     CHAR(1)
  );

  -- nested table (PL/SQL collection) to hold multiple patient records
  TYPE t_patient_table IS TABLE OF t_patient_rec;

  -- procedure to insert multiple patient records in bulk using FORALL
  PROCEDURE bulk_load_patients(p_patients IN t_patient_table);

  -- function to return a ref cursor of all patients
  FUNCTION show_all_patients RETURN SYS_REFCURSOR;

  -- function to return number of patients currently admitted
  FUNCTION count_admitted RETURN NUMBER;

  -- procedure to mark a patient as admitted
  PROCEDURE admit_patient(p_patient_id IN NUMBER);

END pkg_patient_mgmt;
/


CREATE OR REPLACE PACKAGE BODY pkg_patient_mgmt IS

  ----------------------------------------------------------------------------
  -- bulk_load_patients
  -- Inserts all elements in p_patients into the patients table using FORALL
  ----------------------------------------------------------------------------
  PROCEDURE bulk_load_patients(p_patients IN t_patient_table) IS
  BEGIN
    IF p_patients IS NULL OR p_patients.COUNT = 0 THEN
      RETURN;
    END IF;

    -- Bulk insert
    FORALL i IN 1 .. p_patients.COUNT
      INSERT INTO patients (patient_id, patient_name, age, gender, admitted)
      VALUES (
        p_patients(i).patient_id,
        p_patients(i).patient_name,
        p_patients(i).age,
        p_patients(i).gender,
        NVL(p_patients(i).admitted, 'N')
      );

    -- commit after successful bulk insert
    COMMIT;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      -- handle duplicate primary keys gracefully: rollback and raise for caller to inspect
      ROLLBACK;
      RAISE;
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END bulk_load_patients;

  ----------------------------------------------------------------------------
  -- show_all_patients
  -- Returns a ref cursor selecting all patients (caller is responsible for fetching)
  ----------------------------------------------------------------------------
  FUNCTION show_all_patients RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT patient_id,
             patient_name,
             age,
             gender,
             admitted
      FROM patients
      ORDER BY patient_id;
    RETURN rc;
  END show_all_patients;

  ----------------------------------------------------------------------------
  -- count_admitted
  -- Returns count of patients where admitted = 'Y'
  ----------------------------------------------------------------------------
  FUNCTION count_admitted RETURN NUMBER IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM patients WHERE admitted = 'Y';
    RETURN v_count;
  END count_admitted;

  ----------------------------------------------------------------------------
  -- admit_patient
  -- Marks a given patient as admitted (admitted = 'Y')
  ----------------------------------------------------------------------------
  PROCEDURE admit_patient(p_patient_id IN NUMBER) IS
  BEGIN
    UPDATE patients
       SET admitted = 'Y'
     WHERE patient_id = p_patient_id;

    IF SQL%ROWCOUNT > 0 THEN
      COMMIT;
    ELSE
      -- no rows updated: optionally raise an exception or simply leave it
      -- RAISE_APPLICATION_ERROR(-20001, 'Patient not found: ' || p_patient_id);
      NULL;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE;
  END admit_patient;

END pkg_patient_mgmt;
/

---------------------------------------------------------------------------------------------------------------------------
-- TESTING SCRIPTS

-- anonymous block to call bulk_load_patients
DECLARE
  l_patients pkg_patient_mgmt.t_patient_table := pkg_patient_mgmt.t_patient_table();
BEGIN
  -- populate the PL/SQL nested table
  l_patients.EXTEND;
  l_patients(l_patients.COUNT) := pkg_patient_mgmt.t_patient_rec(1, 'Alice Smith', 30, 'F', 'N');

  l_patients.EXTEND;
  l_patients(l_patients.COUNT) := pkg_patient_mgmt.t_patient_rec(2, 'Bob Johnson', 45, 'M', 'N');

  l_patients.EXTEND;
  l_patients(l_patients.COUNT) := pkg_patient_mgmt.t_patient_rec(3, 'Carol Diaz', 27, 'F', 'N');

  l_patients.EXTEND;
  l_patients(l_patients.COUNT) := pkg_patient_mgmt.t_patient_rec(4, 'David Brown', 60, 'M', 'N');

  -- Bulk insert
  pkg_patient_mgmt.bulk_load_patients(l_patients);

  DBMS_OUTPUT.put_line('Bulk load complete.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line('Error during bulk load: ' || SQLERRM);
    RAISE;
END;
/


-- Call function and fetch cursor rows
SET SERVEROUTPUT ON
DECLARE
  rc SYS_REFCURSOR;
  v_id   patients.patient_id%TYPE;
  v_name patients.patient_name%TYPE;
  v_age  patients.age%TYPE;
  v_gen  patients.gender%TYPE;
  v_adm  patients.admitted%TYPE;
BEGIN
  rc := pkg_patient_mgmt.show_all_patients();

  LOOP
    FETCH rc INTO v_id, v_name, v_age, v_gen, v_adm;
    EXIT WHEN rc%NOTFOUND;
    DBMS_OUTPUT.put_line('ID:' || v_id || ' | ' || v_name || ' | Age:' || v_age || ' | ' || v_gen || ' | Admitted:' || v_adm);
  END LOOP;

  CLOSE rc;
END;
/


-- Admit patient with id = 2
BEGIN
  pkg_patient_mgmt.admit_patient(2);
  DBMS_OUTPUT.put_line('Admitted patient 2.');
END;
/

-- Check admitted count
SET SERVEROUTPUT ON
DECLARE
  v_admitted_count NUMBER;
BEGIN
  v_admitted_count := pkg_patient_mgmt.count_admitted();
  DBMS_OUTPUT.put_line('Admitted count = ' || v_admitted_count);
END;
/


BEGIN
  pkg_patient_mgmt.admit_patient(1);
  pkg_patient_mgmt.admit_patient(3);
END;
/

-- Verify
DECLARE
  v_admitted_count NUMBER;
BEGIN
  v_admitted_count := pkg_patient_mgmt.count_admitted();
  DBMS_OUTPUT.put_line('Admitted count after admitting 1 & 3 = ' || v_admitted_count);
END;
/
