CREATE TABLE login_audit (
    audit_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username        VARCHAR2(50) NOT NULL,
    attempt_time    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status          VARCHAR2(10) CHECK (status IN ('SUCCESS', 'FAILED')),
    ip_address      VARCHAR2(45)  -- optional (supports IPv4 & IPv6)
);

CREATE TABLE security_alerts (
    alert_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username        VARCHAR2(50) NOT NULL,
    failed_attempts NUMBER NOT NULL,
    alert_time      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    alert_message   VARCHAR2(200),
    contact_email   VARCHAR2(100)
);


CREATE OR REPLACE TRIGGER trg_failed_login_alert
AFTER INSERT ON login_audit
FOR EACH ROW
WHEN (NEW.status = 'FAILED')
DECLARE
    v_failed_attempts NUMBER;
BEGIN
    -- Count failed attempts for the same user on the same day
    SELECT COUNT(*)
    INTO v_failed_attempts
    FROM login_audit
    WHERE username = :NEW.username
      AND status = 'FAILED'
      AND TRUNC(attempt_time) = TRUNC(SYSDATE);

    -- If failed attempts exceed 2, insert an alert
    IF v_failed_attempts > 2 THEN
        INSERT INTO security_alerts (
            username,
            failed_attempts,
            alert_message,
            contact_email
        ) VALUES (
            :NEW.username,
            v_failed_attempts,
            'More than 2 failed login attempts detected.',
            'securityteam@company.com'
        );
    END IF;
END;
/


ALTER SYSTEM SET SMTP_OUT_SERVER='your.smtp.server.com' SCOPE=BOTH;
GRANT EXECUTE ON UTL_MAIL TO your_user;

CREATE OR REPLACE PROCEDURE send_security_alert_email (
    p_username        IN VARCHAR2,
    p_failed_attempts IN NUMBER,
    p_contact_email   IN VARCHAR2
)
AS
    v_subject VARCHAR2(200);
    v_message VARCHAR2(4000);
BEGIN
    -- Create the email subject and message
    v_subject := 'Security Alert: Multiple Failed Login Attempts';
    v_message := 'User "' || p_username || '" has recorded ' ||
                 p_failed_attempts || ' failed login attempts today.';

    -- Send the email
    UTL_MAIL.send(
        sender     => 'no-reply@company.com',
        recipients => p_contact_email,
        subject    => v_subject,
        message    => v_message
    );
END;
/

CREATE OR REPLACE TRIGGER trg_send_alert_email
AFTER INSERT ON security_alerts
FOR EACH ROW
BEGIN
    send_security_alert_email(
        p_username        => :NEW.username,
        p_failed_attempts => :NEW.failed_attempts,
        p_contact_email   => :NEW.contact_email
    );
END;
/
