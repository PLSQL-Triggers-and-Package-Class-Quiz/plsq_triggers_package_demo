# Class Quiz 02 :PL/SQL Triggers and Package Demonstration
**Group Members**: 
##### - IRADUKUNDA Firmin
##### - MUSHIMIYIMANA Anitha
##### - KAMANZI Milliam
##### - KALAKI Noelyn Vanessa
##### - GANZA Kenny

### Quiz Objective : 
Demonstrate understanding of PL/SQL Triggers and Package by solving a realistic problem, implementing them , and documenting results in a professional GitHub repository.

## Question 1
***Your organization wants to strengthen system security by monitoring suspicious login behavior. A security policy has been introduced stating that: “If any user attempts to log in more than two times with incorrect credentials during the same session or day, the system must immediately record the event and trigger a security alert.” As the database developer, you are required to implement this policy.***

### SOLVING STEPS

1. **Task 1: Create the `login_audit` Table**

*This table will store every login attempt so the system can later analyze failed attempts and trigger alerts.*

2. **Task 2: Create the `security_alerts` Table**

*This table will store records whenever a user exceeds the allowed number of failed login attempts.*

3. **Task 3: Create the Trigger**

*This trigger fires **after each failed login attempt**, checks how many failed attempts the user has made _today_, and inserts an alert if failures exceed 2.*

**Trigger Logic **
 
 - Fires only after **FAILED** attempts  
 - Counts failures for the **same user** on the **same day**  
 - If failures > 2 → insert a record into `security_alerts`

### Results Screenshots

img
img 
img

## Question 2

***Scenario: Hospital Management Package with Bulk Processing*** 

**Background** :  *The hospital management team wants to streamline patient management by storing patient and doctor information in the database. They also want to handle multiple patients at once efficiently and provide functionalities to display information and manage admissions. As a database developer, you are tasked to create a PL/SQL package to support these operations.*

### SOLVING STEPS

 1. **Task 1: Create the `patients and doctors` Tables**
 - Patients table to store patient information (ID, name, age, gender, admitted status)
 - Doctors table to store doctor information (ID, name, specialty).
 
 2. **Task 2: Package Specification**

**Define a collection type to hold multiple patients for bulk processing.**
**Include procedures and functions such as:**
 - `bulk_load_patients` – procedure to insert multiple patient records at once using bulk collection.
 - `show_all_patients` – function to display all patients (returns a cursor).
 - `count_admitted` – function to return the number of patients currently admitted.
 - `admit_patient` – procedure to update a patient’s status as admitted.

 3. **Task 3 : Package Body**

 - Implement the procedures and functions.

 - Use bulk processing techniques (FORALL) for efficient insertion.

 - Use commits appropriately for data consistency.


4. **Task 4 : Testing**

*Create test scripts to:*
 - Load multiple patients using the bulk_load_patients procedure.
 - Display all patients using show_all_patients.
 - Admit one or more patients and verify the change using
   count_admitted.
### Results Screenshots

img
img 
img
